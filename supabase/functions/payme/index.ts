// Payme Merchant API endpoint: Payme's servers call this, not the app.
//
// Setup (once you have a Payme Business merchant):
//   supabase functions deploy payme --no-verify-jwt
//   supabase secrets set PAYME_KEY=<key from the merchant cabinet>
//   In the Payme cabinet: endpoint URL =
//     https://<project>.supabase.co/functions/v1/payme
//   and the account field name = order_id.
// Use the TEST key first (test.paycom.uz sandbox runs Payme's own checks
// against this endpoint), then swap to the production key.
//
// Payme authenticates with Basic "Paycom:<key>". Anything else gets -32504 and
// touches nothing.

import { handlePayme, paymeAuthorized, PaymeErr } from "../_shared/payme_core.ts";
import { paymentsStore } from "../_shared/payments_store.ts";

const reply = (body: unknown) =>
  new Response(JSON.stringify(body), {
    status: 200, // JSON-RPC: errors travel in the body, always HTTP 200
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("POST only", { status: 405 });

  let rpc: { method?: string; params?: Record<string, unknown>; id?: unknown };
  try {
    rpc = await req.json();
  } catch {
    return reply({
      error: { code: PaymeErr.parse, message: { en: "Parse error", ru: "Ошибка разбора", uz: "Tahlil xatosi" } },
      id: null,
    });
  }

  const key = Deno.env.get("PAYME_KEY") ?? "";
  if (!paymeAuthorized(req.headers.get("Authorization"), key)) {
    return reply({
      error: {
        code: PaymeErr.auth,
        message: { en: "Insufficient privileges", ru: "Недостаточно привилегий", uz: "Huquq yetarli emas" },
      },
      id: rpc.id ?? null,
    });
  }

  try {
    return reply(await handlePayme(rpc, paymentsStore));
  } catch (e) {
    console.error("payme", rpc.method, e);
    return reply({
      error: {
        code: -32400,
        message: { en: "System error", ru: "Системная ошибка", uz: "Tizim xatosi" },
      },
      id: rpc.id ?? null,
    });
  }
});
