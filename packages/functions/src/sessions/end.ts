import { GetCommand, TransactWriteCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";
import { safeJson } from "../util/parse";

function dayKey(iso: string) {
  return iso.slice(0, 10);
}

export async function handler(event: any) {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  const sessionId = event?.pathParameters?.id;
  if (!sessionId) return json(event, 400, { error: "Missing session id" });

  const body = safeJson(event?.body);
  if (body === null) return json(event, 400, { error: "Invalid JSON body" });
  const summary = body?.summary ?? null;

  const now = new Date().toISOString();

  try {
    const existing = await ddb.send(
      new GetCommand({
        TableName: process.env.TABLE_SESSIONS!,
        Key: { pk: userId, sk: `SESSION#${sessionId}` },
      })
    );
    if (!existing.Item) {
      return json(event, 404, { error: "Session not found" });
    }
    if (existing.Item.endedAt) {
      return json(event, 200, { ok: true, alreadyEnded: true });
    }

    const startedAt = existing.Item.startedAt;
    const sessionDay = dayKey(startedAt || now);
    const summaryMinutes =
      summary && typeof summary.duration_minutes === "number"
        ? Math.max(0, Math.floor(summary.duration_minutes))
        : undefined;
    const computedMinutes =
      summaryMinutes ??
      (startedAt
        ? Math.max(
            0,
            Math.floor(
              (new Date(now).getTime() - new Date(startedAt).getTime()) / 60000
            )
          )
        : 0);

    const computedNotes =
      summary && typeof summary.total_notes === "number"
        ? summary.total_notes
        : Number(existing.Item.notesPlayed ?? 0);
    const safeMinutes = Number.isFinite(computedMinutes) ? computedMinutes : 0;
    const safeNotes = Number.isFinite(computedNotes) ? computedNotes : 0;
    const velocitySum = Number(existing.Item.velocitySum ?? 0);
    const avgVelocity = safeNotes > 0 ? velocitySum / safeNotes : 0;

    const updateParts = [
      "SET endedAt = :endedAt",
      "updatedAt = :updatedAt",
      "durationMinutes = :durationMinutes",
      "avgVelocity = :avgVelocity",
    ];
    const values: Record<string, any> = {
      ":endedAt": now,
      ":updatedAt": now,
      ":durationMinutes": safeMinutes,
      ":avgVelocity": avgVelocity,
    };

    if (summary) {
      updateParts.push("summary = :summary");
      values[":summary"] = summary;
    }
    if (Number.isFinite(safeNotes)) {
      updateParts.push("notesPlayed = :notesPlayed");
      values[":notesPlayed"] = safeNotes;
    }

    await ddb.send(
      new TransactWriteCommand({
        TransactItems: [
          {
            Update: {
              TableName: process.env.TABLE_SESSIONS!,
              Key: { pk: userId, sk: `SESSION#${sessionId}` },
              UpdateExpression: updateParts.join(", "),
              ExpressionAttributeValues: values,
              ConditionExpression:
                "attribute_exists(pk) AND attribute_exists(sk) AND attribute_not_exists(endedAt)",
            },
          },
          {
            Update: {
              TableName: process.env.TABLE_SESSIONS!,
              Key: { pk: userId, sk: "STATS" },
              UpdateExpression:
                "ADD totalMinutes :m, totalNotes :n, completedSessions :one SET updatedAt = :now",
              ExpressionAttributeValues: {
                ":m": safeMinutes,
                ":n": safeNotes,
                ":one": 1,
                ":now": now,
              },
            },
          },
          {
            Update: {
              TableName: process.env.TABLE_SESSIONS!,
              Key: { pk: userId, sk: `DAY#${sessionDay}` },
              UpdateExpression:
                "ADD totalMinutes :m, totalNotes :n, completedSessions :one SET day = :day, updatedAt = :now",
              ExpressionAttributeValues: {
                ":m": safeMinutes,
                ":n": safeNotes,
                ":one": 1,
                ":day": sessionDay,
                ":now": now,
              },
            },
          },
        ],
      })
    );
  } catch (e: any) {
    if (e?.name === "ConditionalCheckFailedException") {
      return json(event, 200, { ok: true, alreadyEnded: true });
    }
    return json(event, 500, { error: "Failed to end session", detail: String(e) });
  }

  return json(event, 200, { ok: true });
}
