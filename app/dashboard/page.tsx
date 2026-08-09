// Dashboard placeholder. Phase 4 will turn this into the real homepage.
// For now it only proves the auth wiring works end-to-end.

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { SignOutButton } from "@/components/sign-out-button";

export default async function DashboardPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-6 py-12">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold tracking-tight text-zinc-900 dark:text-zinc-50">
          Kartik OS
        </h1>
        <SignOutButton />
      </div>
      <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
        <p className="text-sm text-zinc-600 dark:text-zinc-400">
          Signed in as <span className="font-medium">{user.email}</span>
        </p>
        <p className="mt-3 text-sm text-zinc-600 dark:text-zinc-400">
          Phase 0 complete — foundation is in place. Phase 1 (Core Data
          Layer) is next.
        </p>
      </div>
    </main>
  );
}
