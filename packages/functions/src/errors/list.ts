import { QueryCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";

export async function handler(event: any) {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  const limit = Math.min(
    Math.max(parseInt(event?.queryStringParameters?.limit ?? "50", 10), 1),
    200
  );

  const resp = await ddb.send(
    new QueryCommand({
      TableName: process.env.TABLE_ERRORS!,
      KeyConditionExpression: "pk = :pk AND begins_with(sk, :sk)",
      ExpressionAttributeValues: {
        ":pk": userId,
        ":sk": "ERROR#",
      },
      Limit: limit,
    })
  );

  const items = (resp.Items ?? []) as any[];
  items.sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));

  return json(event, 200, { errors: items.slice(0, limit) });
}
