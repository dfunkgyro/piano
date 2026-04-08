import { GetCommand, PutCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";

export async function handler(event: any) {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  if (String(userId).startsWith("device:")) {
    return json(event, 200, {
      display_name: "Guest",
      email: "",
      skill_level: "beginner",
      total_practice_hours: 0,
      guest: true,
    });
  }

  const existing = await ddb.send(
    new GetCommand({
      TableName: process.env.TABLE_PROFILES!,
      Key: { pk: userId, sk: "PROFILE" },
    })
  );

  if (existing.Item) {
    return json(event, 200, existing.Item);
  }

  const profile = {
    pk: userId,
    sk: "PROFILE",
    display_name: "Piano Student",
    email: "",
    skill_level: "beginner",
    total_practice_hours: 0,
  };

  await ddb.send(
    new PutCommand({
      TableName: process.env.TABLE_PROFILES!,
      Item: profile,
    })
  );

  return json(event, 200, profile);
}
