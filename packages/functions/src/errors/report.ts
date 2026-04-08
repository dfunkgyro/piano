import { PutCommand } from "@aws-sdk/lib-dynamodb";
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";
import { ulid } from "ulid";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";

const sns = new SNSClient({});

export async function handler(event: any) {
  const userId = getUserId(event) ?? "anonymous";
  let body: any = {};
  try {
    body = event?.body ? JSON.parse(event.body) : {};
  } catch {
    body = {};
  }
  const id = ulid();
  const now = new Date().toISOString();

  const item = {
    pk: userId,
    sk: `ERROR#${id}`,
    id,
    createdAt: now,
    message: body.message ?? "unknown",
    stack: body.stack ?? "",
    context: body.context ?? {},
    appVersion: body.appVersion ?? "",
    platform: body.platform ?? "",
  };

  await ddb.send(
    new PutCommand({
      TableName: process.env.TABLE_ERRORS!,
      Item: item,
    })
  );

  const topicArn = process.env.ERROR_TOPIC_ARN;
  if (topicArn) {
    try {
      const subject = `Piano App Crash (${item.platform || "unknown"})`;
      const message = [
        `Time: ${item.createdAt}`,
        `User: ${item.pk}`,
        `App: ${item.appVersion}`,
        `Message: ${item.message}`,
        `Stack: ${String(item.stack).slice(0, 2000)}`,
      ].join("\n");
      await sns.send(
        new PublishCommand({
          TopicArn: topicArn,
          Subject: subject,
          Message: message,
        })
      );
    } catch {
      // Ignore SNS publish errors
    }
  }

  return json(event, 200, { ok: true, id });
}
