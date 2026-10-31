import { createHash, createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";

export const cookieName = "entrenaya_admin";
export const sessionSeconds = 8 * 60 * 60;
export function demoMode() {
  return process.env.ADMIN_DEMO_MODE === "true";
}
export function configured() {
  return (
    (process.env.ADMIN_PASSWORD?.length ?? 0) >= 12 &&
    (process.env.ADMIN_SESSION_SECRET?.length ?? 0) >= 32 &&
    (process.env.ADMIN_API_KEY?.length ?? 0) >= 32
  );
}
export function sameSecret(a: string, b: string) {
  return timingSafeEqual(
    createHash("sha256").update(a).digest(),
    createHash("sha256").update(b).digest(),
  );
}
function signature(payload: string) {
  return createHmac("sha256", process.env.ADMIN_SESSION_SECRET!)
    .update(payload)
    .digest("base64url");
}
export function newSession() {
  const payload = Buffer.from(
    JSON.stringify({ role: "admin", exp: Date.now() + sessionSeconds * 1000 }),
  ).toString("base64url");
  return `${payload}.${signature(payload)}`;
}
export async function authenticated() {
  if (demoMode()) return (process.env.ADMIN_API_KEY?.length ?? 0) >= 32;
  if (!configured()) return false;
  const token = (await cookies()).get(cookieName)?.value;
  if (!token) return false;
  try {
    const [payload, sig, extra] = token.split(".");
    if (extra || !payload || !sig || !sameSecret(sig, signature(payload)))
      return false;
    const data = JSON.parse(Buffer.from(payload, "base64url").toString("utf8"));
    return (
      data.role === "admin" &&
      typeof data.exp === "number" &&
      data.exp > Date.now()
    );
  } catch {
    return false;
  }
}
export function sameOrigin(request: Request) {
  try {
    const origin = new URL(request.headers.get("origin") || "");
    const host =
      request.headers.get("x-forwarded-host") ||
      request.headers.get("host") ||
      new URL(request.url).host;
    return origin.host === host;
  } catch {
    return false;
  }
}
