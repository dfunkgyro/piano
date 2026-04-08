import { QueryCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";
import { clampNumber } from "../util/parse";

export async function handler(event: any) {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  const rawLimit = Number(event?.queryStringParameters?.limit ?? 10);
  const limit = clampNumber(rawLimit, 1, 100);

  const result = await ddb.send(
    new QueryCommand({
      TableName: process.env.TABLE_SESSIONS!,
      KeyConditionExpression: "pk = :pk AND begins_with(sk, :sk)",
      ExpressionAttributeValues: {
        ":pk": userId,
        ":sk": "SESSION#",
      },
      ScanIndexForward: false,
      Limit: limit,
    })
  );

  return json(event, 200, { sessions: result.Items ?? [] });
}
