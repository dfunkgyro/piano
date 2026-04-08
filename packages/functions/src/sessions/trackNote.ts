import { UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";
import { safeJson } from "../util/parse";

export async function handler(event: any) {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  const sessionId = event?.pathParameters?.id;
  if (!sessionId) return json(event, 400, { error: "Missing session id" });

  const body = safeJson(event?.body);
  if (body === null) return json(event, 400, { error: "Invalid JSON body" });
  const note = Number(body?.note);
  const velocity = Number(body?.velocity);
  const hasVelocity = Number.isFinite(velocity);

  const now = new Date().toISOString();
  try {
    await ddb.send(
      new UpdateCommand({
        TableName: process.env.TABLE_SESSIONS!,
        Key: { pk: userId, sk: `SESSION#${sessionId}` },
        UpdateExpression:
          "ADD notesPlayed :inc" +
          (hasVelocity ? ", velocitySum :vel" : "") +
          " SET lastNoteAt = :lastNoteAt, updatedAt = :updatedAt" +
          (Number.isFinite(note) ? ", lastNote = :note" : "") +
          (hasVelocity ? ", lastVelocity = :vel" : ""),
        ExpressionAttributeValues: {
          ":inc": 1,
          ":lastNoteAt": now,
          ":updatedAt": now,
          ...(Number.isFinite(note) ? { ":note": note } : {}),
          ...(hasVelocity ? { ":vel": velocity } : {}),
        },
        ConditionExpression: "attribute_exists(pk) AND attribute_exists(sk)",
      })
    );
  } catch (e: any) {
    if (e?.name === "ConditionalCheckFailedException") {
      return json(event, 404, { error: "Session not found" });
    }
    return json(event, 500, { error: "Failed to track note", detail: String(e) });
  }

  return json(event, 200, { ok: true });
}
