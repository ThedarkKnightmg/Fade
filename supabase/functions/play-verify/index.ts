// Verify a Google Play purchase (VIP / Boost) and grant it, once.
//
// Setup:
//   supabase functions deploy play-verify
//   Play Console: create the products (ids in _shared/play_core.ts), then
//   Setup -> API access: link a Google Cloud service account and give it
//   "View financial data" + "Manage orders and subscriptions".
//   supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON='<the key JSON>'
//   (optional) PLAY_PACKAGE_NAME, defaults to uz.fade.app
//
// The app sends {product_id, purchase_token}. Nothing is granted on the app's
// word: Google is asked, and the token is recorded so it grants exactly once.

import { admin } from "../_shared/payments_store.ts";
import {
  ANDROID_PUBLISHER_SCOPE,
  decideProductGrant,
  decideSubscriptionGrant,
  PLAY_PRODUCTS,
  serviceAccountAssertion,
} from "../_shared/play_core.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...cors },
  });

let cachedToken: { value: string; exp: number } | null = null;

async function googleToken(): Promise<string> {
  if (cachedToken && cachedToken.exp > Date.now() + 60_000) return cachedToken.value;
  const sa = JSON.parse(Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON") ?? "{}");
  const assertion = await serviceAccountAssertion(sa, ANDROID_PUBLISHER_SCOPE);
  const res = await fetch(sa.token_uri ?? "https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const body = await res.json();
  if (!res.ok || !body.access_token) throw new Error(`google token: ${res.status}`);
  cachedToken = { value: body.access_token, exp: Date.now() + (body.expires_in ?? 3600) * 1000 };
  return cachedToken.value;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);
  if (!Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON")) return json({ configured: false }, 503);

  const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data: auth } = await admin.auth.getUser(jwt);
  const user = auth?.user;
  if (!user) return json({ error: "sign in first" }, 401);

  const body = await req.json().catch(() => ({}));
  const productId = String(body.product_id ?? "");
  const token = String(body.purchase_token ?? "");
  const product = PLAY_PRODUCTS[productId];
  if (!product || !token) return json({ error: "unknown product" }, 400);

  const pkg = Deno.env.get("PLAY_PACKAGE_NAME") ?? "uz.fade.app";
  const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${pkg}/purchases`;
  const url = product.kind === "vip"
    ? `${base}/subscriptionsv2/tokens/${encodeURIComponent(token)}`
    : `${base}/products/${productId}/tokens/${encodeURIComponent(token)}`;

  let google;
  try {
    const res = await fetch(url, { headers: { Authorization: `Bearer ${await googleToken()}` } });
    if (res.status === 404 || res.status === 400) return json({ error: "not a real purchase" }, 400);
    if (!res.ok) throw new Error(`google ${res.status}`);
    google = await res.json();
  } catch (e) {
    console.error("play-verify google", e);
    return json({ error: "could not reach Google, try again" }, 502);
  }

  const grant = product.kind === "vip"
    ? decideSubscriptionGrant(productId, google)
    : decideProductGrant(productId, google);
  if ("error" in grant) return json({ error: grant.error }, 400);

  const { data: outcome, error } = await admin.rpc("play_grant", {
    p_user: user.id,
    p_token: token,
    p_product: productId,
    p_order: grant.orderId,
    p_boosts: grant.kind === "boosts" ? grant.count : grant.boosts,
    p_vip_until: grant.kind === "vip" ? grant.until : null,
  });
  if (error) {
    console.error("play-verify grant", error);
    return json({ error: "could not grant" }, 500);
  }
  if (outcome === "foreign") return json({ error: "purchase belongs to another account" }, 409);

  return json({
    ok: true,
    already: outcome === "already",
    product_id: productId,
    kind: grant.kind,
    boosts: grant.kind === "boosts" ? grant.count : grant.boosts,
    vip_until: grant.kind === "vip" ? grant.until : null,
  });
});
