import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = {
  title: "EntrenaYa · Monitoreo",
  description: "Gestión de ejercicios y rutinas de EntrenaYa",
};
export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
