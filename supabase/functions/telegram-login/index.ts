// "Continue with Telegram" backend — now issues a REAL Supabase session, and
// binds each login to the device that started it.
//
// Three entry points on one function:
//
//   • POST {action:"mint", code, device_hash, phrase}  (from the app)
//       Register a login attempt BEFORE the bot link opens. The row is bound to
//       the device (device_hash) and carries the check phrase the bot will show.
//       /start then refuses any code that was never minted — an attacker can no
//       longer invent a code and phish it through a t.me link.
//
//   • POST <Telegram update>  (webhook, authed by the secret-token header)
//       1. "/start <code>" → confirm the code was minted, remember the Telegram
//          user, show the CHECK PHRASE + a warning, and ask them to share their
//          contact.
//       2. contact message → Telegram's own verified number. We check
//          contact.user_id === from.id (no forwarded cards), then — with the
//          service-role key — create/fetch the auth user for that phone and mint
//          a one-time magic-link token, storing it on the row.
//
//   • GET ?code=...&device=...  (the app polls)
//       Only the device that minted the code (device secret → sha256 matches
//       device_hash) gets the result. On success it receives token_hash ONCE
//       (the row is consumed), then exchanges it via verifyOtp for a session.
//
// The service-role key stays server-side here — never in the app.
//
// Setup: migrations *_tg_login_codes.sql + *_tg_login_phone.sql +
//   *_tg_real_session.sql, then
//   supabase functions deploy telegram-login --no-verify-jwt
//   supabase secrets set TELEGRAM_BOT_TOKEN=... TG_WEBHOOK_SECRET=...

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const supa = createClient(
  SUPABASE_URL,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// Synthetic email domain — the auth user is keyed on the phone, but generateLink
// needs an email. No mail is ever sent to it; it exists only as the login key.
const EMAIL_DOMAIN = "tg.fade.uz";

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

async function sha256Hex(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

const digits = (phone: string) => phone.replace(/[^0-9]/g, "");
const emailFor = (phone: string) => `p${digits(phone)}@${EMAIL_DOMAIN}`;

Deno.serve(async (req) => {
  try {
    // ── App polling: GET ?code=...&device=... ──────────────────────────
    if (req.method === "GET") {
      const url = new URL(req.url);
      const code = url.searchParams.get("code") ?? "";
      const device = url.searchParams.get("device") ?? "";
      if (!code) return json({ error: "code required" }, 400);

      const { data } = await supa
        .from("tg_login_codes")
        .select("status,name,phone,device_hash,token_hash,expires_at")
        .eq("code", code)
        .maybeSingle();

      if (!data) return json({ status: "pending" });
      if (data.expires_at && new Date(data.expires_at) < new Date()) {
        return json({ status: "expired" });
      }
      // Only the device that minted the code may read the result.
      if (data.device_hash && (await sha256Hex(device)) !== data.device_hash) {
        return json({ status: "pending" }); // don't reveal anything else
      }
      if (data.status !== "verified") {
        return json({ status: data.status ?? "pending", name: data.name });
      }
      // Verified: hand back the one-time token ONCE, then consume the row so a
      // leaked code can never replay.
      await supa.from("tg_login_codes").delete().eq("code", code);
      return json({
        status: "verified",
        name: data.name,
        phone: data.phone,
        token_hash: data.token_hash,
      });
    }

    // ── App minting a login attempt: POST {action:"mint", ...} ─────────
    // Distinguished from the Telegram webhook by the absence of the bot
    // secret-token header and the explicit action field.
    if (req.method === "POST") {
      const secret = req.headers.get("x-telegram-bot-api-secret-token");
      if (secret !== Deno.env.get("TG_WEBHOOK_SECRET")) {
        // Not the webhook — the only other accepted POST is a mint.
        const body = await req.json().catch(() => ({}));
        if (body?.action !== "mint") return json({ error: "unauthorized" }, 401);
        const code = String(body.code ?? "");
        const deviceHash = String(body.device_hash ?? "");
        const phrase = String(body.phrase ?? "");
        if (!/^[a-z0-9]{8,64}$/.test(code) || deviceHash.length !== 64) {
          return json({ error: "bad request" }, 400);
        }
        await supa.from("tg_login_codes").upsert({
          code,
          status: "minted",
          device_hash: deviceHash,
          phrase: phrase.slice(0, 40),
          // 10-minute window (matches the TTL column default; set explicitly so
          // a re-mint of the same code refreshes it).
          expires_at: new Date(Date.now() + 10 * 60_000).toISOString(),
          // wipe any prior verification state for a re-minted code
          telegram_id: null,
          phone: null,
          token_hash: null,
        });
        return json({ ok: true });
      }

      // ── Telegram webhook ─────────────────────────────────────────────
      const update = await req.json();
      const msg = update?.message;
      if (!msg) return json({ ok: true });

      const fromId = msg.from?.id;
      const chatId = msg.chat?.id;
      const fullName = [msg.from?.first_name, msg.from?.last_name]
        .filter(Boolean).join(" ");

      // Step 1 — /start <code>: only a code the app actually MINTED is accepted.
      const start = (msg.text ?? "").match(/^\/start\s+([a-z0-9]{8,64})/);
      if (start) {
        const code = start[1];
        const { data: row } = await supa
          .from("tg_login_codes")
          .select("code,status,phrase,expires_at")
          .eq("code", code)
          .maybeSingle();

        if (
          !row || row.status === "verified" ||
          (row.expires_at && new Date(row.expires_at) < new Date())
        ) {
          await tg("sendMessage", {
            chat_id: chatId,
            text:
              "⏳ Bu kod eskirgan yoki notto'g'ri. Fade ilovasidan «Telegram " +
              "orqali kirish» tugmasini qaytadan bosing.",
          });
          return json({ ok: true });
        }

        await supa.from("tg_login_codes")
          .update({ status: "awaiting_contact", telegram_id: fromId, name: fullName })
          .eq("code", code);

        const phraseLine = row.phrase
          ? `\n\n🔑 Tekshiruv so'zi: *${row.phrase}*\nAgar bu so'zni Fade ` +
            `ilovasida ko'rmagan bo'lsangiz — raqamni ulashMANG.`
          : "";
        await tg("sendMessage", {
          chat_id: chatId,
          parse_mode: "Markdown",
          text:
            "✂️ Fade\n\nKirishni yakunlash uchun raqamingizni tasdiqlang — " +
            "quyidagi tugmani bosing. Telegram raqamingizni biz uchun " +
            "tasdiqlaydi (SMS kerak emas)." + phraseLine,
          reply_markup: {
            keyboard: [[{ text: "📱 Raqamni tasdiqlash", request_contact: true }]],
            resize_keyboard: true,
            one_time_keyboard: true,
          },
        });
        return json({ ok: true });
      }

      // Step 2 — the contact: Telegram's own verified number → real session.
      const contact = msg.contact;
      if (contact) {
        if (!contact.user_id || contact.user_id !== fromId) {
          await tg("sendMessage", {
            chat_id: chatId,
            text: "❌ Iltimos, faqat O'ZINGIZNING raqamingizni tugma orqali yuboring.",
          });
          return json({ ok: true });
        }
        const { data: row } = await supa
          .from("tg_login_codes")
          .select("code,expires_at")
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
          ? contact.phone_number : `+${contact.phone_number}`;
        const email = emailFor(phone);

        // Create the auth user (idempotent — ignore "already registered"), then
        // mint a one-time magic-link token for it. This is what turns a verified
        // phone into a genuine, server-issued session.
        await supa.auth.admin.createUser({
          email,
          email_confirm: true,
          phone,
          phone_confirm: true,
          user_metadata: { full_name: fullName, telegram_id: fromId },
        }).catch(() => {/* already exists — fine */});

        const { data: link, error: linkErr } = await supa.auth.admin
          .generateLink({ type: "magiclink", email });
        if (linkErr || !link?.properties?.hashed_token) {
          console.error("generateLink failed:", linkErr);
          await tg("sendMessage", {
            chat_id: chatId,
            text: "⚠️ Server xatosi. Birozdan so'ng qayta urinib ko'ring.",
          });
          return json({ ok: true });
        }

        await supa.from("tg_login_codes")
          .update({
            status: "verified",
            phone,
            name: fullName,
            token_hash: link.properties.hashed_token,
          })
          .eq("code", row.code);

        await tg("sendMessage", {
          chat_id: chatId,
          text: `✅ Raqam tasdiqlandi: ${phone}\nFade ilovasiga qayting — tayyor!`,
          reply_markup: { remove_keyboard: true },
        });
        return json({ ok: true });
      }

      return json({ ok: true });
    }

    return json({ error: "method not allowed" }, 405);
  } catch (e) {
    console.error("telegram-login:", e);
    return json({ error: String(e) }, 500);
  }
});
