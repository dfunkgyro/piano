function getAllowedOrigins() {
  return (process.env.ALLOWED_ORIGINS ?? "")
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean);
}

export function json(event: any, statusCode: number, body: unknown) {
  const origins = getAllowedOrigins();
  const origin = event?.headers?.origin || event?.headers?.Origin;
  const allowOrigin = origin && origins.includes(origin) ? origin : null;

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Headers": "content-type,authorization,x-device-id",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
    Vary: "Origin",
  };

  if (allowOrigin) {
    headers["Access-Control-Allow-Origin"] = allowOrigin;
  }

  return {
    statusCode,
    headers,
    body: JSON.stringify(body ?? {}),
  };
}
