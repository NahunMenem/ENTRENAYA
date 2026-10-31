import { redirect } from "next/navigation";
import { demoMode } from "@/lib/auth";
import Login from "@/components/login-form";
export const dynamic = "force-dynamic";
export default function Page() {
  if (demoMode()) redirect("/");
  return <Login />;
}
