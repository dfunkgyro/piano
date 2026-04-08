import { GetCommand, QueryCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";

export async function handler(event: any) {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });

  const result = await ddb.send(
    new GetCommand({
      TableName: process.env.TABLE_SESSIONS!,
      Key: { pk: userId, sk: "STATS" },
    })
  );
  if (!result.Item) {
    const sessions: any[] = [];
    let lastKey: Record<string, any> | undefined = undefined;

    do {
      const resp = await ddb.send(
        new QueryCommand({
          TableName: process.env.TABLE_SESSIONS!,
          KeyConditionExpression: "pk = :pk AND begins_with(sk, :sk)",
          ExpressionAttributeValues: {
            ":pk": userId,
            ":sk": "SESSION#",
          },
          ScanIndexForward: false,
          ExclusiveStartKey: lastKey,
        })
      );
      sessions.push(...(resp.Items ?? []));
      lastKey = resp.LastEvaluatedKey as Record<string, any> | undefined;
    } while (lastKey);

    let totalMinutes = 0;
    let totalNotes = 0;
    let completedSessions = 0;

    for (const session of sessions) {
      const summary = session.summary ?? null;
      let minutes = 0;
      if (summary && typeof summary.duration_minutes === "number") {
        minutes = Math.max(0, Math.floor(summary.duration_minutes));
      } else {
        const startedAt = session.startedAt;
        const endedAt = session.endedAt;
        if (startedAt && endedAt) {
          const duration =
            new Date(endedAt).getTime() - new Date(startedAt).getTime();
          minutes = Math.max(0, Math.floor(duration / 60000));
        }
      }
      if (session.endedAt) completedSessions += 1;
      totalMinutes += minutes;
      if (summary && typeof summary.total_notes === "number") {
        totalNotes += summary.total_notes;
      } else {
        totalNotes += Number(session.notesPlayed ?? 0);
      }
    }

    await ddb.send(
      new UpdateCommand({
        TableName: process.env.TABLE_SESSIONS!,
        Key: { pk: userId, sk: "STATS" },
        UpdateExpression:
          "SET totalSessions = :ts, totalMinutes = :tm, totalNotes = :tn, completedSessions = :cs, updatedAt = :now",
        ExpressionAttributeValues: {
          ":ts": sessions.length,
          ":tm": totalMinutes,
          ":tn": totalNotes,
          ":cs": completedSessions,
          ":now": new Date().toISOString(),
        },
      })
    );

    return json(event, 200, {
      totalSessions: sessions.length,
      totalMinutes,
      totalNotes,
      averageSessionMinutes:
        completedSessions === 0
          ? 0
          : Math.floor(totalMinutes / completedSessions),
    });
  }

  const stats = result.Item ?? {};
  const totalMinutes = Number(stats.totalMinutes ?? 0);
  const totalNotes = Number(stats.totalNotes ?? 0);
  const totalSessions = Number(stats.totalSessions ?? 0);
  const completedSessions = Number(stats.completedSessions ?? 0);

  return json(event, 200, {
    totalSessions,
    totalMinutes,
    totalNotes,
    averageSessionMinutes:
      completedSessions === 0
        ? 0
        : Math.floor(totalMinutes / completedSessions),
  });
}
