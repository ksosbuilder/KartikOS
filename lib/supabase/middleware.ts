// Supabase middleware helper. Refreshes the user's session on every request
// so that:
//   1. Server Components see a fresh session (no stale auth state)
//   2. The cookie carrying the JWT is rotated before it expires
//   3. RLS policies have up-to-date auth.uid()
//
// Wired up in /middleware.ts at the project root.

import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // IMPORTANT: This triggers the actual session refresh. Do not remove.
  // The `getUser()` call below would not refresh the token without it.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Route protection: send unauthenticated users to /login.
  // Phase 0: keep the public root accessible. Phase 1+: tighten this as
  // the data model exposes routes that require auth.
  if (!user && request.nextUrl.pathname.startsWith("/dashboard")) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  return response;
}
