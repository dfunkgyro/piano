import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";
import { json } from "../util/response";
import { getUserId } from "../util/user";
import { safeJson } from "../util/parse";
import { getBedrockModelId, getBedrockRegion } from "../util/bedrock";

const region = getBedrockRegion();
const modelId = getBedrockModelId();

const client = new BedrockRuntimeClient({ region });

const baseSystemPrompt = [
  "You are GrandPiano's AI tutor and practice coach.",
  "The app includes: falling-notes lesson game, adjustable tempo, auto-loop, metronome, velocity-aware piano, MIDI input, and progress tracking.",
  "You cannot directly control the app UI. Provide clear, step-by-step guidance and settings to change.",
  "When asked to teach a song, propose a short practice plan and optional note sequences.",
  "If asked for sheet music, provide ABC notation plus a note list with octaves.",
  "If asked for falling-notes data, respond with JSON in a fenced code block using fields: notes[{note,time,duration,hand}], bpm, rangeMin, rangeMax.",
  "Keep responses concise and focused on piano learning outcomes.",
].join(" ");

export async function handler(event: any) {
  try {
    const userId = getUserId(event);
    if (!userId) return json(event, 401, { error: "Unauthorized" });
    const allowGuest = process.env.ALLOW_GUEST_AI !== "false";
    if (String(userId).startsWith("device:") && !allowGuest) {
      return json(event, 200, {
        content:
          "Guest mode is active. Sign in to use the AI tutor and advanced cloud features.",
        guest: true,
      });
    }
    const body = safeJson(event?.body);
    if (body === null) return json(event, 400, { error: "Invalid JSON body" });
    const messages = Array.isArray(body.messages) ? body.messages : [];

    const allowSystem = process.env.ALLOW_SYSTEM_PROMPTS === "true";
    const systemMessages = allowSystem
      ? messages.filter((m: any) => m.role === "system")
      : [];
    const system = [
      baseSystemPrompt,
      ...systemMessages.map((m: any) => m.content),
    ]
      .filter(Boolean)
      .join("\n\n");

    const chatMessages = messages
      .filter((m: any) => m.role === "user" || m.role === "assistant")
      .map((m: any) => ({
        role: m.role,
        content: [{ type: "text", text: String(m.content ?? "") }],
      }));

    if (chatMessages.length === 0) {
      return json(event, 400, { error: "No chat messages provided" });
    }

    if (chatMessages.length > 20) {
      return json(event, 400, { error: "Too many chat messages" });
    }

    const totalChars = chatMessages.reduce((sum: number, m: any) => {
      const text = Array.isArray(m.content) ? m.content[0]?.text ?? "" : "";
      return sum + String(text).length;
    }, 0);

    if (totalChars > 8000) {
      return json(event, 413, { error: "Chat payload too large" });
    }

    const payload = {
      anthropic_version: "bedrock-2023-05-31",
      system,
      messages: chatMessages,
      max_tokens: 800,
      temperature: 0.7,
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
    const content = Array.isArray(data.content) ? data.content[0]?.text : "";

    return json(event, 200, { content });
  } catch (e: any) {
    return json(event, 500, { error: "AI request failed", detail: String(e) });
  }
}
