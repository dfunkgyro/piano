const DEFAULT_MODEL_ID = "anthropic.claude-3-5-sonnet-20240620-v1:0";

export function getBedrockRegion() {
  return process.env.BEDROCK_REGION || process.env.AWS_REGION || "us-east-1";
}

export function getBedrockModelId() {
  return process.env.BEDROCK_MODEL_ID || DEFAULT_MODEL_ID;
}
