import { PutCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";
import { safeJson } from "../util/parse";

export async function handler(event: any) {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  const songId = event?.pathParameters?.id;
  if (!songId) return json(event, 400, { error: "Missing song id" });

  const body = safeJson(event?.body);
  if (body === null) return json(event, 400, { error: "Invalid JSON body" });
  const progress = Number(body.progress ?? 0);
  if (!Number.isFinite(progress) || progress < 0 || progress > 1) {
    return json(event, 400, { error: "Progress must be between 0 and 1" });
  }

  await ddb.send(
    new PutCommand({
      TableName: process.env.TABLE_SONG_PROGRESS!,
      Item: {
        pk: userId,
        sk: `SONG#${songId}`,
        progress,
        updatedAt: new Date().toISOString(),
      },
    })
  );

  return json(event, 200, { ok: true });
}
