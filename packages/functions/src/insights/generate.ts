import { GetCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";
import { ddb } from "../util/dynamo";
import { json } from "../util/response";
import { getUserId } from "../util/user";
import { safeJson } from "../util/parse";
import { getBedrockModelId, getBedrockRegion } from "../util/bedrock";

const region = getBedrockRegion();
const modelId = getBedrockModelId();

const client = new BedrockRuntimeClient({ region });

export async function handler(event: any) {
  try {
  const userId = getUserId(event);
  if (!userId) return json(event, 401, { error: "Unauthorized" });
  if (String(userId).startsWith("device:")) {
    return json(event, 200, { ok: true, skipped: true });
  }
    const sessionId = event?.pathParameters?.id;
    if (!sessionId) return json(event, 400, { error: "Missing session id" });

    const body = safeJson(event?.body);
    if (body === null) return json(event, 400, { error: "Invalid JSON body" });
    let summary = body?.summary ?? null;

    if (!summary) {
      const existing = await ddb.send(
        new GetCommand({
          TableName: process.env.TABLE_SESSIONS!,
          Key: { pk: userId, sk: `SESSION#${sessionId}` },
        })
      );
      if (!existing.Item) {
        return json(event, 404, { error: "Session not found" });
      }
      summary = existing.Item?.summary ?? null;
    }

    if (!summary) {
      return json(event, 400, { error: "Missing session summary" });
    }
    if (typeof summary !== "object") {
      return json(event, 400, { error: "Invalid session summary" });
    }
    const summarySize = JSON.stringify(summary).length;
    if (summarySize > 10000) {
      return json(event, 413, { error: "Session summary too large" });
    }

    const system =
      "You are an elite piano coach. Return ONLY valid JSON. No prose.";
    const prompt = {
      session_summary: summary,
      instructions: {
        goals: [
          "diagnose top weaknesses",
          "suggest 2-4 actionable drills",
          "set a concrete tempo target",
          "define next session goal",
        ],
        output_schema: {
          diagnosis: "string",
          top_actions: ["string"],
          drills: [
            {
              name: "string",
              duration_minutes: "number",
              focus: "string",
            },
          ],
          tempo_target_bpm: "number",
          next_session_goal: "string",
          risk_flags: ["string"],
        },
      },
    };

    const payload = {
      anthropic_version: "bedrock-2023-05-31",
      system,
      messages: [
        {
          role: "user",
          content: [{ type: "text", text: JSON.stringify(prompt) }],
        },
      ],
      max_tokens: 700,
      temperature: 0.3,
      top_p: 0.9,
      user: userId,
    };

    const resp = await client.send(
      new InvokeModelCommand({
        modelId,
        contentType: "application/json",
        accept: "application/json",
        body: JSON.stringify(payload),
      })
    );

    const raw = new TextDecoder().decode(resp.body);
    const data = JSON.parse(raw);
    const text = Array.isArray(data.content) ? data.content[0]?.text : "";

    let insights: any = null;
    try {
      insights = JSON.parse(text);
    } catch {
      insights = {
        diagnosis: "Unable to parse model output",
        top_actions: ["Review your session data and retry insights"],
        drills: [],
        tempo_target_bpm: 0,
        next_session_goal: "Collect more data",
        risk_flags: ["invalid_model_output"],
        raw,
      };
    }

    const now = new Date().toISOString();
    await ddb.send(
      new UpdateCommand({
        TableName: process.env.TABLE_SESSIONS!,
        Key: { pk: userId, sk: `SESSION#${sessionId}` },
        UpdateExpression: "SET insights = :insights, insightsAt = :insightsAt, updatedAt = :updatedAt",
        ExpressionAttributeValues: {
          ":insights": insights,
          ":insightsAt": now,
          ":updatedAt": now,
        },
        ConditionExpression: "attribute_exists(pk) AND attribute_exists(sk)",
      })
    );

    return json(event, 200, { insights });
  } catch (e: any) {
    return json(event, 500, { error: "Insights generation failed", detail: String(e) });
  }
}
