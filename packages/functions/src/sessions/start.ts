import { PutCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { ulid } from "ulid";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";

function dayKey(iso: string) {
  return iso.slice(0, 10);
}

export async function handler(event: any) {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  const sessionId = ulid();
  const now = new Date().toISOString();
  const day = dayKey(now);

  await ddb.send(
    new PutCommand({
      TableName: process.env.TABLE_SESSIONS!,
      Item: {
        pk: userId,
        sk: `SESSION#${sessionId}`,
        sessionId,
        startedAt: now,
        notesPlayed: 0,
        velocitySum: 0,
      },
    })
  );

  await ddb.send(
    new UpdateCommand({
      TableName: process.env.TABLE_SESSIONS!,
      Key: { pk: userId, sk: "STATS" },
      UpdateExpression:
        "ADD totalSessions :one SET updatedAt = :now",
      ExpressionAttributeValues: {
        ":one": 1,
        ":now": now,
      },
    })
  );

  await ddb.send(
    new UpdateCommand({
      TableName: process.env.TABLE_SESSIONS!,
      Key: { pk: userId, sk: `DAY#${day}` },
      UpdateExpression:
        "ADD totalSessions :one SET day = :day, updatedAt = :now",
      ExpressionAttributeValues: {
        ":one": 1,
        ":day": day,
        ":now": now,
      },
    })
  );

  return json(event, 200, { sessionId });
}
