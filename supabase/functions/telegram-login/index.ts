// "Continue with Telegram" backend — one Edge Function, two jobs:
//
//   • POST (Telegram webhook): the bot receives "/start <code>" when the user
//     taps START; we mark the code verified with their telegram id + name and
//     reply in-chat. Authenticated via the X-Telegram-Bot-Api-Secret-Token
//     header (set when registering the webhook).
//   • GET ?code=...: the app polls until its code flips to verified.
//
// Setup (one-time):
//   1. @BotFather → /newbot → grab the bot token + username. Put the username
//      into SupabaseConfig.telegramBot in the app.
//   2. Create the table (SQL editor):
//        create table if not exists tg_login_codes (
//          code text primary key,
//          status text not null default 'pending',
//          telegram_id bigint,
//          name text,
//          created_at timestamptz not null default now()
//        );
//        alter table tg_login_codes enable row level security;
//        -- no policies: only the service role (this function) touches it.
//   3. supabase functions deploy telegram-login --no-verify-jwt
//   4. supabase secrets set TELEGRAM_BOT_TOKEN=... TG_WEBHOOK_SECRET=<random>
//   5. Register the webhook:
//        curl "https://api.telegram.org/bot<TOKEN>/setWebhook" \
//          -d url=https://<project>.supabase.co/functions/v1/telegram-login \
//          -d secret_token=<TG_WEBHOOK_SECRET>
//
// The service-role key stays server-side here (never in the app), matching
// the project's security posture.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supa = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  try {
    // ── App polling: GET ?code=... ─────────────────────────────────────
    if (req.method === "GET") {
      const code = new URL(req.url).searchParams.get("code") ?? "";
      if (!code) return json({ error: "code required" }, 400);
      const { data } = await supa
        .from("tg_login_codes")
        .select("status,name")
        .eq("code", code)
        .maybeSingle();
      return json({ status: data?.status ?? "pending", name: data?.name });
    }

    // ── Telegram webhook: POST update ──────────────────────────────────
    const secret = req.headers.get("x-telegram-bot-api-secret-token");
    if (secret !== Deno.env.get("TG_WEBHOOK_SECRET")) {
      return json({ error: "bad secret" }, 401);
    }
    const update = await req.json();
    const msg = update?.message;
    const text: string = msg?.text ?? "";
    const match = text.match(/^\/start\s+([a-z0-9]{8,64})/);
    if (msg && match) {
      const code = match[1];
      const name = [msg.from?.first_name, msg.from?.last_name]
        .filter(Boolean)
        .join(" ");
      await supa.from("tg_login_codes").upsert({
        code,
        status: "verified",
        telegram_id: msg.from?.id,
        name,
      });
      // Friendly confirmation in the chat, uz-first like the app.
      await fetch(
        `https://api.telegram.org/bot${
          Deno.env.get("TELEGRAM_BOT_TOKEN")
        }/sendMessage`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            chat_id: msg.chat.id,
            text: "✅ Fade: kirish tasdiqlandi — ilovaga qayting!",
          }),
        },
      );
    }
    return json({ ok: true });
  } catch (e) {
    console.error("telegram-login:", e);
    return json({ error: String(e) }, 500);
  }
});
