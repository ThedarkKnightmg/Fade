// Supabase Auth "Send SMS" hook → delivers the OTP through TELEGRAM instead of
// an SMS carrier, using the Telegram Gateway API (gateway.telegram.org).
//
// The user still just types their phone number in Fade; the code arrives as a
// Telegram message from the official "Telegram" service account. Cheaper than
// SMS, instant, and the number stays the account id.
//
// How it fits: the app keeps calling supabase.auth.signInWithOtp() unchanged.
// Supabase generates the code and, with this hook enabled, POSTs
// { user: { phone }, sms: { otp } } here (signed) instead of using Twilio. We
// verify the signature and hand the code to Telegram Gateway. Verification
// itself still happens in Supabase (verifyOtp), so nothing else changes.
//
// Setup (one-time):
//   1. Sign in at https://gateway.telegram.org with your Telegram account,
//      create an app, copy the API token, and top up the balance
//      (per-message pricing is shown on the site).
//   2. supabase functions deploy send-sms-telegram --no-verify-jwt
//   3. supabase secrets set TG_GATEWAY_TOKEN=...
//   4. Dashboard → Authentication → Hooks → "Send SMS" → point at THIS
//      function, then copy the generated hook secret:
//      supabase secrets set SEND_SMS_HOOK_SECRET=v1,whsec_...
//   5. Dashboard → Authentication → Providers → Phone → enable (no Twilio).
//
// Fallback: keep send-sms-eskiz deployed if you want real SMS for users who
// don't have Telegram — only one function can hold the hook at a time, so
// switch the hook target to choose the channel.

import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

const GATEWAY = "https://gatewayapi.telegram.org";

Deno.serve(async (req) => {
  try {
    // Verify the request really comes from Supabase Auth (standard-webhooks
    // signature with the hook secret) — otherwise anyone could spend credit.
    const secret = (Deno.env.get("SEND_SMS_HOOK_SECRET") ?? "").replace(
      "v1,",
      "",
    );
    const payloadText = await req.text();
    const headers = Object.fromEntries(req.headers);
    const wh = new Webhook(secret);
    const { user, sms } = wh.verify(payloadText, headers) as {
      user: { phone: string };
      sms: { otp: string };
    };

    // Telegram Gateway wants E.164 (+998...).
    const phone = user.phone.startsWith("+") ? user.phone : `+${user.phone}`;

    // Optional but recommended: ask first whether this number can receive a
    // Telegram message at all. Costs nothing and tells us to fall back.
    const ableRes = await fetch(`${GATEWAY}/checkSendAbility`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get("TG_GATEWAY_TOKEN")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ phone_number: phone }),
    });
    const able = await ableRes.json();
    if (!able?.ok) {
      // Surface the Gateway's OWN reason. Supabase only forwards our message
      // when we answer 200 with an error body — a non-2xx is reported to the
      // client as a bare "unexpected status code", which hides the cause.
      console.error("checkSendAbility failed:", JSON.stringify(able));
      return new Response(
        JSON.stringify({
          error: { message: `TG Gateway: ${JSON.stringify(able)}` },
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    // Deliver SUPABASE's code (so verifyOtp keeps working unchanged).
    const sendRes = await fetch(`${GATEWAY}/sendVerificationMessage`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get("TG_GATEWAY_TOKEN")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        phone_number: phone,
        request_id: able?.result?.request_id,
        code: sms.otp,
        code_length: sms.otp.length,
        ttl: 300, // 5 minutes, matches Supabase's OTP window
        payload: "fade-login",
      }),
    });
    const sent = await sendRes.json();
    if (!sent?.ok) {
      console.error("sendVerificationMessage failed:", JSON.stringify(sent));
      return new Response(
        JSON.stringify({
          error: { message: `TG Gateway send: ${JSON.stringify(sent)}` },
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("send-sms-telegram:", e);
    return new Response(
      JSON.stringify({ error: { message: String(e) } }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
