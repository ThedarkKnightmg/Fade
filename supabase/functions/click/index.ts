// Click SHOP API endpoint: Click's servers call this, not the app.
//
// Setup (once you have a Click merchant):
//   supabase functions deploy click --no-verify-jwt
//   supabase secrets set CLICK_SECRET_KEY=<secret> CLICK_SERVICE_ID=<id>
//   In the Click merchant cabinet, set BOTH the Prepare URL and the Complete
//   URL to: https://<project>.supabase.co/functions/v1/click
//
// Click posts form fields and signs them with our secret key; a call with a
// bad signature is refused before anything is read or written.

import { handleClick } from "../_shared/click_core.ts";
import { paymentsStore } from "../_shared/payments_store.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("POST only", { status: 405 });

  const params: Record<string, string> = {};
  const type = req.headers.get("content-type") ?? "";
  try {
    if (type.includes("application/json")) {
      for (const [k, v] of Object.entries(await req.json())) params[k] = String(v);
    } else {
      const form = await req.formData();
      for (const [k, v] of form.entries()) params[k] = String(v);
    }
  } catch {
    return Response.json({ error: -8, error_note: "Error in request from click" });
  }

  const secret = Deno.env.get("CLICK_SECRET_KEY") ?? "";
  if (!secret) {
    // Not configured: refuse everything rather than accept unsigned calls.
    return Response.json({ error: -8, error_note: "Not configured" });
  }
  try {
    const out = await handleClick(params, paymentsStore, secret, Deno.env.get("CLICK_SERVICE_ID") ?? "");
    return Response.json(out);
  } catch (e) {
    console.error("click", params.action, e);
    return Response.json({ error: -7, error_note: "Failed to update user" });
  }
});
