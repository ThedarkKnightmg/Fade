// The app's ONE payment entry point: "I want to pay for X".
//
// Requires the user's JWT (deploy WITH jwt verification). The request names
// what to pay for; the AMOUNT is decided here (resolveCharge): a fixed top-up
// option, or the booking's stored price. A `payments` row is created and the
// app gets checkout links for each provider that is configured.
//
// Setup:
//   supabase functions deploy payments-create
//   Payme:  supabase secrets set PAYME_MERCHANT_ID=<id> [PAYME_TEST=1]
//   Click:  supabase secrets set CLICK_SERVICE_ID=<id> CLICK_MERCHANT_ID=<id>
//   Optional: PAYMENT_RETURN_URL (where checkout sends the user back).
// With neither provider configured it answers 503 {configured:false} and the
// app keeps showing "payments launching soon".

import { admin } from "../_shared/payments_store.ts";
import { clickCheckoutUrl, paymeCheckoutUrl, resolveCharge } from "../_shared/checkout.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...cors },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  const paymeMerchant = Deno.env.get("PAYME_MERCHANT_ID") ?? "";
  const clickService = Deno.env.get("CLICK_SERVICE_ID") ?? "";
  const clickMerchant = Deno.env.get("CLICK_MERCHANT_ID") ?? "";
  const hasPayme = paymeMerchant !== "";
  const hasClick = clickService !== "" && clickMerchant !== "";
  if (!hasPayme && !hasClick) return json({ configured: false }, 503);

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data: auth } = await admin.auth.getUser(token);
  const user = auth?.user;
  if (!user) return json({ error: "sign in first" }, 401);

  const body = await req.json().catch(() => ({}));

  let booking = null;
  if (body.purpose === "booking") {
    const { data } = await admin
      .from("bookings")
      .select("client_id, price, status, paid_at")
      .eq("id", String(body.booking_id ?? ""))
      .maybeSingle();
    booking = data;
  }

  const charge = resolveCharge(body, user.id, booking);
  if ("error" in charge) return json({ error: charge.error }, 400);

  const { data: row, error } = await admin
    .from("payments")
    .insert({
      user_id: user.id,
      purpose: body.purpose,
      booking_id: body.purpose === "booking" ? body.booking_id : null,
      amount_tiyin: charge.amountTiyin,
    })
    .select("id")
    .single();
  if (error || !row) {
    console.error("payments-create insert", error);
    return json({ error: "could not start payment" }, 500);
  }

  const returnUrl = Deno.env.get("PAYMENT_RETURN_URL") ?? undefined;
  const lang = ["uz", "ru", "en"].includes(body.lang) ? body.lang : undefined;
  return json({
    configured: true,
    payment_id: row.id,
    amount_som: charge.amountTiyin / 100,
    payme_url: hasPayme
      ? paymeCheckoutUrl({
        merchantId: paymeMerchant,
        paymentId: row.id,
        amountTiyin: charge.amountTiyin,
        returnUrl,
        lang,
        test: Deno.env.get("PAYME_TEST") === "1",
      })
      : null,
    click_url: hasClick
      ? clickCheckoutUrl({
        serviceId: clickService,
        merchantId: clickMerchant,
        paymentId: row.id,
        amountSom: charge.amountTiyin / 100,
        returnUrl,
      })
      : null,
  });
});
