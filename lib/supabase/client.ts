// Browser-side Supabase client. Uses the @supabase/ssr package which is the
// recommended way to integrate with Next.js 15 App Router cookies.
//
// Use this in client components for any real-time subscriptions or direct
// browser-side queries. For server-side data fetching, prefer lib/supabase/server.ts.

import { createBrowserClient } from "@supabase/ssr";

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
