import { redirect } from "next/navigation";
import { authenticated, demoMode } from "@/lib/auth";
import Dashboard from "@/components/dashboard";
export const dynamic = "force-dynamic";
export default async function Page() {
  if (!(await authenticated())) redirect("/login");
  return <Dashboard demoMode={demoMode()} />;
}
