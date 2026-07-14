// Supabase Auth "Send SMS" hook → delivers the OTP via Eskiz.uz (~95 UZS/SMS
// inside Uzbekistan instead of Twilio's international rates).
//
// How it fits: the app keeps calling supabase.auth.signInWithOtp() unchanged.
// Supabase generates the code and, with this hook enabled, POSTs
// { user: { phone }, sms: { otp } } here (signed) instead of using Twilio.
// We verify the signature and hand the code to Eskiz.
//
// Setup (one-time):
//   1. Register a business account at https://eskiz.uz and get a sender name
//      approved (or use the shared default sender "4546").
//   2. supabase functions deploy send-sms-eskiz --no-verify-jwt
//   3. supabase secrets set ESKIZ_EMAIL=... ESKIZ_PASSWORD=... ESKIZ_FROM=4546
//   4. Dashboard → Authentication → Hooks → "Send SMS" → this function.
//      Copy the generated hook secret:
//      supabase secrets set SEND_SMS_HOOK_SECRET=v1,whsec_...
//   5. Dashboard → Authentication → Providers → Phone → enable (no Twilio).
//
// Once live, the in-app demo-code fallback stops firing on its own (it only
// activates when the provider is unconfigured).

import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

const ESKIZ_BASE = "https://notify.eskiz.uz/api";

async function eskizToken(): Promise<string> {
  const res = await fetch(`${ESKIZ_BASE}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email: Deno.env.get("ESKIZ_EMAIL"),
      password: Deno.env.get("ESKIZ_PASSWORD"),
    }),
  });
  if (!res.ok) throw new Error(`eskiz auth failed: ${res.status}`);
  const json = await res.json();
  const token = json?.data?.token;
  if (!token) throw new Error("eskiz auth: no token in response");
  return token;
}

Deno.serve(async (req) => {
  try {
    // Verify the request really comes from Supabase Auth (standard-webhooks
    // signature with the hook secret) — otherwise anyone could spend our SMS.
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

    // Eskiz wants digits only (998XXXXXXXXX).
    const phone = user.phone.replace(/\D/g, "");
    const message =
      `Fade: kirish kodingiz ${sms.otp}. Uni hech kimga bermang.`;

    const token = await eskizToken();
    const send = await fetch(`${ESKIZ_BASE}/message/sms/send`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        mobile_phone: phone,
        message,
        from: Deno.env.get("ESKIZ_FROM") ?? "4546",
      }),
    });
    if (!send.ok) {
      const body = await send.text();
      throw new Error(`eskiz send failed: ${send.status} ${body}`);
    }

    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("send-sms-eskiz:", e);
    return new Response(
      JSON.stringify({ error: { message: String(e) } }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
