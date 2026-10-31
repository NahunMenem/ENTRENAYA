import { NextResponse } from "next/server";
import {
  authenticated,
  configured,
  cookieName,
  newSession,
  sameOrigin,
  sameSecret,
  sessionSeconds,
} from "@/lib/auth";

const attempts = new Map<string, { count: number; until: number }>();
export async function GET() {
  return NextResponse.json({ authenticated: await authenticated() });
}
export async function POST(request: Request) {
  if (!sameOrigin(request))
    return NextResponse.json(
      { detail: "Origen no permitido." },
      { status: 403 },
    );
  if (!configured())
    return NextResponse.json(
      { detail: "Configurá las credenciales del panel en el servidor." },
      { status: 503 },
    );
  const ip = request.headers.get("x-forwarded-for")?.split(",")[0] || "local";
  const now = Date.now();
  for (const [key, value] of attempts)
    if (value.until < now) attempts.delete(key);
  const attempt = attempts.get(ip) ?? { count: 0, until: now + 15 * 60 * 1000 };
  if (attempt.count >= 5)
    return NextResponse.json(
      { detail: "Demasiados intentos. Volvé a intentar en 15 minutos." },
      { status: 429 },
    );
  const body = await request.json().catch(() => null);
  if (
    typeof body?.password !== "string" ||
    !sameSecret(body.password, process.env.ADMIN_PASSWORD!)
  ) {
    attempts.set(ip, { ...attempt, count: attempt.count + 1 });
    return NextResponse.json(
      { detail: "Contraseña incorrecta." },
      { status: 401 },
    );
  }
  attempts.delete(ip);
  const response = NextResponse.json({ ok: true });
  response.cookies.set(cookieName, newSession(), {
    httpOnly: true,
    sameSite: "strict",
    secure:
      process.env.NODE_ENV === "production" &&
      process.env.COOKIE_SECURE !== "false",
    path: "/",
    maxAge: sessionSeconds,
  });
  return response;
}
export async function DELETE(request: Request) {
  if (!sameOrigin(request))
    return NextResponse.json(
      { detail: "Origen no permitido." },
      { status: 403 },
    );
  const response = NextResponse.json({ ok: true });
  response.cookies.set(cookieName, "", {
    httpOnly: true,
    sameSite: "strict",
    path: "/",
    maxAge: 0,
  });
  return response;
}
