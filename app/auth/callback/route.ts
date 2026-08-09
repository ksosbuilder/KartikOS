// Magic link / OAuth callback. Supabase redirects here after the user
// clicks the email link. We exchange the auth code for a session cookie
// and send them to the dashboard.

import { createClient } from "@/lib/supabase/server";
import { NextResponse, type NextRequest } from "next/server";

export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/dashboard";

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);

    if (!error) {
      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  // If something went wrong, send them back to login with an error.
  return NextResponse.redirect(`${origin}/login?error=auth_callback_failed`);
}
