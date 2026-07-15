// "Continue with Telegram" backend — one Edge Function, two jobs:
//
//   • POST (Telegram webhook), two steps:
//       1. "/start <code>"  → remember the code for this Telegram user and ask
//          them to SHARE THEIR CONTACT (a request_contact keyboard button).
//       2. contact message  → Telegram hands us the phone number IT verified at
//          signup. That is real proof of ownership (no SMS, no cost). We check
//          contact.user_id === from.id so nobody can forward someone else's
//          card, then mark the code verified with the phone + name.
//     Authenticated via the X-Telegram-Bot-Api-Secret-Token header.
//   • GET ?code=... : the app polls until its code flips to verified, and gets
//     back the verified phone + name.
//
// Setup: see supabase/migrations/*_tg_login_codes.sql for the table, then
//   supabase functions deploy telegram-login --no-verify-jwt
//   supabase secrets set TELEGRAM_BOT_TOKEN=... TG_WEBHOOK_SECRET=...
//   curl "https://api.telegram.org/bot<TOKEN>/setWebhook" \
//     -d url=https://<project>.supabase.co/functions/v1/telegram-login \
//     -d secret_token=<TG_WEBHOOK_SECRET>
//
// The service-role key stays server-side here (never in the app).

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

const tg = (method: string, body: unknown) =>
  fetch(
    `https://api.telegram.org/bot${Deno.env.get("TELEGRAM_BOT_TOKEN")}/${method}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    },
  );

Deno.serve(async (req) => {
  try {
    // ── App polling: GET ?code=... ─────────────────────────────────────
    if (req.method === "GET") {
      const code = new URL(req.url).searchParams.get("code") ?? "";
      if (!code) return json({ error: "code required" }, 400);
      const { data } = await supa
        .from("tg_login_codes")
        .select("status,name,phone")
        .eq("code", code)
        .maybeSingle();
      return json({
        status: data?.status ?? "pending",
        name: data?.name,
        phone: data?.phone,
      });
    }

    // ── Telegram webhook: POST update ──────────────────────────────────
    const secret = req.headers.get("x-telegram-bot-api-secret-token");
    if (secret !== Deno.env.get("TG_WEBHOOK_SECRET")) {
      return json({ error: "bad secret" }, 401);
    }
    const update = await req.json();
    const msg = update?.message;
    if (!msg) return json({ ok: true });

    const fromId = msg.from?.id;
    const chatId = msg.chat?.id;
    const fullName = [msg.from?.first_name, msg.from?.last_name]
      .filter(Boolean)
      .join(" ");

    // Step 1 — /start <code>: park the code, then ask for the contact.
    const start = (msg.text ?? "").match(/^\/start\s+([a-z0-9]{8,64})/);
    if (start) {
      const code = start[1];
      await supa.from("tg_login_codes").upsert({
        code,
        status: "awaiting_contact",
        telegram_id: fromId,
        name: fullName,
      });
      await tg("sendMessage", {
        chat_id: chatId,
        text:
          "✂️ Fade\n\nKirishni yakunlash uchun raqamingizni tasdiqlang — " +
          "quyidagi tugmani bosing. Telegram raqamingizni biz uchun " +
          "tasdiqlaydi (SMS kerak emas).",
        reply_markup: {
          keyboard: [[{
            text: "📱 Raqamni tasdiqlash",
            request_contact: true,
          }]],
          resize_keyboard: true,
          one_time_keyboard: true,
        },
      });
      return json({ ok: true });
    }

    // Step 2 — the contact: Telegram's own verified number.
    const contact = msg.contact;
    if (contact) {
      // Must be THEIR OWN card — a forwarded contact has a different user_id
      // (or none), so this is what makes it proof of ownership.
      if (!contact.user_id || contact.user_id !== fromId) {
        await tg("sendMessage", {
          chat_id: chatId,
          text:
            "❌ Iltimos, faqat O'ZINGIZNING raqamingizni tugma orqali yuboring.",
        });
        return json({ ok: true });
      }
      // Attach it to this user's most recent pending login.
      const { data: row } = await supa
        .from("tg_login_codes")
        .select("code")
        .eq("telegram_id", fromId)
        .eq("status", "awaiting_contact")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (!row) {
        await tg("sendMessage", {
          chat_id: chatId,
          text: "⏳ Avval ilovadan «Telegram orqali kirish» tugmasini bosing.",
        });
        return json({ ok: true });
      }
      const phone = contact.phone_number.startsWith("+")
        ? contact.phone_number
        : `+${contact.phone_number}`;
      await supa
        .from("tg_login_codes")
        .update({ status: "verified", phone, name: fullName })
        .eq("code", row.code);
      await tg("sendMessage", {
        chat_id: chatId,
        text:
          `✅ Raqam tasdiqlandi: ${phone}\nFade ilovasiga qayting — tayyor!`,
        reply_markup: { remove_keyboard: true },
      });
      return json({ ok: true });
    }

    return json({ ok: true });
  } catch (e) {
    console.error("telegram-login:", e);
    return json({ error: String(e) }, 500);
  }
});
