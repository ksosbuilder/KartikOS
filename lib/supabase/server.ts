// Server-side Supabase client. Wraps the SSR client with Next.js cookies()
// so the server can read the user's session and enforce RLS.
//
// Use this in:
//   - Server Components
//   - Route Handlers (app/api/*/route.ts)
//   - Server Actions ("use server" functions)
//
// NEVER use this in a client component — it will leak the anon key context
// and won't have access to the user's cookies.

import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // setAll is called from Server Components where cookies() is
            // read-only. Middleware refreshes the session, so this is safe
            // to ignore — see https://supabase.com/docs/guides/auth/server-side
          }
        },
      },
    },
  );
}
