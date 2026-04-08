import { QueryCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";
import { clampNumber } from "../util/parse";

export async function handler(event: any) {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  const rawDays = Number(event?.queryStringParameters?.days ?? 30);
  const days = clampNumber(rawDays, 1, 365);
  const cutoff = Date.now() - days * 24 * 60 * 60 * 1000;

  const dayItems: any[] = [];
  let lastKey: Record<string, any> | undefined = undefined;

  do {
    const result = await ddb.send(
      new QueryCommand({
        TableName: process.env.TABLE_SESSIONS!,
        KeyConditionExpression: "pk = :pk AND begins_with(sk, :sk)",
        ExpressionAttributeValues: {
          ":pk": userId,
          ":sk": "DAY#",
        },
        ScanIndexForward: false,
        ExclusiveStartKey: lastKey,
      })
    );
    dayItems.push(...(result.Items ?? []));
    lastKey = result.LastEvaluatedKey as Record<string, any> | undefined;
  } while (lastKey);

  if (dayItems.length === 0) {
    const sessions: any[] = [];
    let lastSessionKey: Record<string, any> | undefined = undefined;

    do {
      const result = await ddb.send(
        new QueryCommand({
          TableName: process.env.TABLE_SESSIONS!,
          KeyConditionExpression: "pk = :pk AND begins_with(sk, :sk)",
          ExpressionAttributeValues: {
            ":pk": userId,
            ":sk": "SESSION#",
          },
          ScanIndexForward: false,
          ExclusiveStartKey: lastSessionKey,
        })
      );
      sessions.push(...(result.Items ?? []));
      lastSessionKey = result.LastEvaluatedKey as
        | Record<string, any>
        | undefined;
    } while (lastSessionKey);

    const recentSessions = sessions.filter((s) => {
      const startedAt = s.startedAt ? new Date(s.startedAt).getTime() : 0;
      return startedAt >= cutoff;
    });

    let totalMinutes = 0;
    let totalNotes = 0;

    for (const session of recentSessions) {
      const summary = session.summary ?? null;
      if (summary && typeof summary.duration_minutes === "number") {
        totalMinutes += Math.max(0, Math.floor(summary.duration_minutes));
      } else {
        const startedAt = session.startedAt;
        const endedAt = session.endedAt;
        if (startedAt && endedAt) {
          const duration =
            new Date(endedAt).getTime() - new Date(startedAt).getTime();
          totalMinutes += Math.max(0, Math.floor(duration / 60000));
        }
      }
      if (summary && typeof summary.total_notes === "number") {
        totalNotes += summary.total_notes;
      } else {
        totalNotes += Number(session.notesPlayed ?? 0);
      }
    }

    // Best-effort backfill: aggregate by day for future queries.
    const byDay: Record<string, { minutes: number; notes: number; sessions: number }> = {};
    for (const session of recentSessions) {
      if (!session.startedAt) continue;
      const day = String(session.startedAt).slice(0, 10);
      if (!byDay[day]) {
        byDay[day] = { minutes: 0, notes: 0, sessions: 0 };
      }
      byDay[day].sessions += 1;
      const summary = session.summary ?? null;
      if (summary && typeof summary.duration_minutes === "number") {
        byDay[day].minutes += Math.max(0, Math.floor(summary.duration_minutes));
      } else if (session.startedAt && session.endedAt) {
        const duration =
          new Date(session.endedAt).getTime() -
          new Date(session.startedAt).getTime();
        byDay[day].minutes += Math.max(0, Math.floor(duration / 60000));
      }
      if (summary && typeof summary.total_notes === "number") {
        byDay[day].notes += summary.total_notes;
      } else {
        byDay[day].notes += Number(session.notesPlayed ?? 0);
      }
    }

    await Promise.all(
      Object.entries(byDay).map(([day, agg]) =>
        ddb.send(
          new UpdateCommand({
            TableName: process.env.TABLE_SESSIONS!,
            Key: { pk: userId, sk: `DAY#${day}` },
            UpdateExpression:
              "ADD totalMinutes :m, totalNotes :n, completedSessions :s SET day = :day, updatedAt = :now",
            ExpressionAttributeValues: {
              ":m": agg.minutes,
              ":n": agg.notes,
              ":s": agg.sessions,
              ":day": day,
              ":now": new Date().toISOString(),
            },
          })
        )
      )
    );

    return json(event, 200, {
      total_sessions: recentSessions.length,
      total_minutes: totalMinutes,
      total_notes: totalNotes,
      average_accuracy: 0.0,
    });
  }

  const recentDays = dayItems.filter((d) => {
    const day = d.day ? new Date(d.day).getTime() : 0;
    return day >= cutoff;
  });

  let totalMinutes = 0;
  let totalNotes = 0;
  let totalSessions = 0;

  for (const day of recentDays) {
    totalMinutes += Number(day.totalMinutes ?? 0);
    totalNotes += Number(day.totalNotes ?? 0);
    totalSessions += Number(day.completedSessions ?? day.totalSessions ?? 0);
  }

  return json(event, 200, {
    total_sessions: totalSessions,
    total_minutes: totalMinutes,
    total_notes: totalNotes,
    average_accuracy: 0.0,
  });
}
