// In-app feedback sink. The app POSTs {category, message, contact, role,
// platform}; this function (service role) stores it in the `feedback` table AND
// — if OWNER_TG_CHAT_ID is set — pings the owner on Telegram via the bot, so a
// bug report or idea actually reaches a human instead of dying in local storage.
//
// Setup:
//   supabase functions deploy feedback --no-verify-jwt
//   (optional, for the Telegram ping) get your numeric id from @userinfobot,
//   then: supabase secrets set OWNER_TG_CHAT_ID=<your id>
//   (TELEGRAM_BOT_TOKEN is already set for the login function.)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supa = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, apikey, content-type",
    },
  });

const clamp = (v: unknown, n: number) => String(v ?? "").slice(0, n);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return json({}, 204);
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  try {
    const body = await req.json().catch(() => ({}));
    const message = clamp(body.message, 2000).trim();
    if (!message) return json({ error: "message required" }, 400);

    const category = clamp(body.category || "other", 20);
    const contact = body.contact ? clamp(body.contact, 120) : null;
    const role = body.role ? clamp(body.role, 20) : null;
    const platform = body.platform ? clamp(body.platform, 40) : null;

    const { error } = await supa.from("feedback").insert({
      category,
      message,
      contact,
      role,
      platform,
    });
    if (error) {
      console.error("feedback insert:", error);
      return json({ error: "store failed" }, 500);
    }

    // Instant ping to the owner (best-effort — never fails the request).
    const chatId = Deno.env.get("OWNER_TG_CHAT_ID");
    const token = Deno.env.get("TELEGRAM_BOT_TOKEN");
    if (chatId && token) {
      const emoji = category === "bug" ? "🐞" : category === "idea" ? "💡" : "💬";
      const lines = [
        `${emoji} Fade — ${category}`,
        "",
        message,
        "",
        contact ? `📞 ${contact}` : "",
        role ? `role: ${role}` : "",
      ].filter(Boolean).join("\n");
      try {
        await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ chat_id: chatId, text: lines }),
        });
      } catch (e) {
        console.error("feedback telegram ping:", e);
      }
    }

    return json({ ok: true });
  } catch (e) {
    console.error("feedback:", e);
    return json({ error: String(e) }, 500);
  }
});
