export function getUserId(event: any) {
  const claims = event?.requestContext?.authorizer?.jwt?.claims;
  if (claims?.sub) return claims.sub as string;

  const allowDeviceId = process.env.ALLOW_DEVICE_ID === "true";
  const allowGuestApi = process.env.ALLOW_GUEST_API === "true";
  if (!allowDeviceId) return null;
  if (!allowGuestApi) return null;

  const headers = event?.headers ?? {};
  const deviceId =
    headers["x-device-id"] ||
    headers["X-Device-Id"] ||
    headers["x-device-id".toLowerCase()];
  if (deviceId) return `device:${String(deviceId)}`;

  return null;
}
