// Account deletion. The app calls this with the signed-in user's session; the
// function verifies who they are, then deletes THAT auth user with the service
// role. Because public.profiles references auth.users(id) ON DELETE CASCADE,
// the profile and everything hanging off it (bookings, reviews, messages, the
// barber row) goes with it.
//
// Deploy WITH jwt verification (the default — do NOT pass --no-verify-jwt), so
// only an authenticated user can reach it and we can trust the caller's id:
//   supabase functions deploy delete-account
//
// SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY are injected
// into every function automatically.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, apikey, content-type",
    },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return json({}, 204);
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const authHeader = req.headers.get("Authorization") ?? "";

    // Identify the caller from THEIR token — never trust an id in the body.
    const asUser = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: whoErr } = await asUser.auth.getUser();
    if (whoErr || !user) return json({ error: "unauthenticated" }, 401);

    // Delete with the service role. This is the ONLY id we act on.
    const admin = createClient(
      url,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
    if (delErr) {
      console.error("delete-account:", delErr);
      return json({ error: "delete failed" }, 500);
    }
    return json({ ok: true });
  } catch (e) {
    console.error("delete-account:", e);
    return json({ error: String(e) }, 500);
  }
});
