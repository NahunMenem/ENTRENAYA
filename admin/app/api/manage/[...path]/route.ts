import { authenticated, sameOrigin } from "@/lib/auth";
export const dynamic = "force-dynamic";
async function proxy(
  request: Request,
  context: { params: Promise<{ path: string[] }> },
) {
  if (!(await authenticated()))
    return Response.json(
      { detail: "Iniciá sesión para continuar." },
      { status: 401 },
    );
  if (request.method !== "GET" && !sameOrigin(request))
    return Response.json({ detail: "Origen no permitido." }, { status: 403 });
  const path = (await context.params).path.join("/");
  if (!/^(exercises|routines)(\/[a-zA-Z0-9-]+)?$/.test(path))
    return Response.json({ detail: "Ruta inválida." }, { status: 404 });
  try {
    const response = await fetch(
      `${process.env.API_BASE_URL || "https://entrenaya-production.up.railway.app"}/api/v1/admin/${path}`,
      {
        method: request.method,
        cache: "no-store",
        signal: AbortSignal.timeout(20000),
        headers: {
          "Content-Type": "application/json",
          "X-Admin-Key": process.env.ADMIN_API_KEY!,
        },
        body: request.method === "GET" ? undefined : await request.text(),
      },
    );
    return new Response(await response.text(), {
      status: response.status,
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "no-store",
      },
    });
  } catch {
    return Response.json(
      { detail: "No pudimos conectar con la API. Reintentá." },
      { status: 502 },
    );
  }
}
export { proxy as GET, proxy as POST, proxy as PUT };
