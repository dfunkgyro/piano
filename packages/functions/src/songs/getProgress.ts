import { GetCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";

export async function handler(event: any) {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  const songId = event?.pathParameters?.id;
  if (!songId) return json(event, 400, { error: "Missing song id" });

  const result = await ddb.send(
    new GetCommand({
      TableName: process.env.TABLE_SONG_PROGRESS!,
      Key: { pk: userId, sk: `SONG#${songId}` },
    })
  );

  return json(event, 200, {
    progress: result.Item?.progress ?? 0.0,
  });
}
