import { GetCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";

export async function handler(event: any) {
  try {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  if (String(userId).startsWith("device:")) {
    return json(event, 200, { insights: [], generated: false });
  }
    const sessionId = event?.pathParameters?.id;
    if (!sessionId) return json(event, 400, { error: "Missing session id" });

    const existing = await ddb.send(
      new GetCommand({
        TableName: process.env.TABLE_SESSIONS!,
        Key: { pk: userId, sk: `SESSION#${sessionId}` },
      })
    );

    if (!existing.Item) {
      return json(event, 404, { error: "Session not found" });
    }

    const insights = existing.Item?.insights ?? null;
    if (!insights) {
      return json(event, 404, { error: "Insights not available" });
    }

    return json(event, 200, { insights });
  } catch (e: any) {
    return json(event, 500, { error: "Failed to load insights", detail: String(e) });
  }
}
