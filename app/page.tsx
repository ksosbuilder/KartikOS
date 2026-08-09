// Root route. Phase 0: redirect to /dashboard. The dashboard handles
// auth — unauthenticated users land on /login.

import { redirect } from "next/navigation";

export default function Home() {
  redirect("/dashboard");
}
