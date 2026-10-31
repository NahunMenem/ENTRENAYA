"use client";
import { useState } from "react";
import { Dumbbell, ArrowRight, ShieldCheck } from "lucide-react";
export default function Login() {
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  return (
    <main className="login">
      <div className="login-card">
        <div className="brand">
          <i>
            <Dumbbell />
          </i>
          Entrena<span>Ya</span>
        </div>
        <span className="eyebrow">PANEL DE MONITOREO</span>
        <h1>
          Tu contenido.
          <br />
          Su próximo progreso.
        </h1>
        <p>
          Administrá los ejercicios y las rutinas que acompañan a tu comunidad.
        </p>
        <form
          onSubmit={async (e) => {
            e.preventDefault();
            setBusy(true);
            setError("");
            const password = String(
              new FormData(e.currentTarget).get("password"),
            );
            try {
              const response = await fetch("/api/session", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ password }),
              });
              const data = await response.json();
              if (!response.ok) throw new Error(data.detail);
              window.location.href = "/";
            } catch (e) {
              setError(e instanceof Error ? e.message : "No pudimos ingresar.");
            } finally {
              setBusy(false);
            }
          }}
        >
          <label>
            Contraseña de administración
            <input
              name="password"
              type="password"
              autoComplete="current-password"
              required
            />
          </label>
          {error && (
            <div className="error" role="alert">
              {error}
            </div>
          )}
          <button disabled={busy}>
            {busy ? "Ingresando…" : "Entrar al panel"}
            <ArrowRight size={18} />
          </button>
        </form>
        <small>
          <ShieldCheck size={15} /> Acceso exclusivo para administradores
        </small>
      </div>
    </main>
  );
}
