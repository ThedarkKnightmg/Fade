// Google Play Billing verification for VIP and Boost (digital features, which
// Play requires to be sold through Play Billing, not Payme/Click).
//
// Pure logic, testable under Node: which products exist and what each grants,
// whether Google's answer means "paid", and the service-account sign-in to
// Google's API (RS256 JWT via Web Crypto, available in Deno and Node).

/** Product IDs as created in Play Console, and what each one grants. */
export const PLAY_PRODUCTS: Record<
  string,
  { kind: "boosts"; count: number } | { kind: "vip"; days: number; boosts: number }
> = {
  fade_boost_starter: { kind: "boosts", count: 3 },
  fade_boost_growth: { kind: "boosts", count: 10 },
  fade_boost_pro: { kind: "boosts", count: 25 },
  fade_vip_monthly: { kind: "vip", days: 30, boosts: 5 },
};

export type Grant =
  | { kind: "boosts"; count: number; orderId: string | null }
  | { kind: "vip"; until: string; boosts: number; orderId: string | null };

/**
 * purchases.products.get -> grant. purchaseState: 0 purchased, 1 cancelled,
 * 2 pending. Only a completed purchase grants.
 */
export function decideProductGrant(
  productId: string,
  // deno-lint-ignore no-explicit-any
  resp: any,
): Grant | { error: string } {
  const p = PLAY_PRODUCTS[productId];
  if (!p || p.kind !== "boosts") return { error: "unknown product" };
  if (!resp || typeof resp !== "object") return { error: "no purchase" };
  if (resp.purchaseState === 2) return { error: "pending" };
  if (resp.purchaseState !== 0) return { error: "not purchased" };
  return { kind: "boosts", count: p.count, orderId: resp.orderId ?? null };
}

/**
 * purchases.subscriptionsv2.get -> grant. Active (or in grace period) and
 * covering THIS product; VIP runs to the latest line-item expiry.
 */
export function decideSubscriptionGrant(
  productId: string,
  // deno-lint-ignore no-explicit-any
  resp: any,
  now: number = Date.now(),
): Grant | { error: string } {
  const p = PLAY_PRODUCTS[productId];
  if (!p || p.kind !== "vip") return { error: "unknown product" };
  const state = resp?.subscriptionState;
  if (state !== "SUBSCRIPTION_STATE_ACTIVE" && state !== "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") {
    return { error: "not active" };
  }
  // deno-lint-ignore no-explicit-any
  const items: any[] = Array.isArray(resp.lineItems) ? resp.lineItems : [];
  const mine = items.filter((i) => i?.productId === productId);
  if (mine.length === 0) return { error: "wrong product" };
  const until = Math.max(...mine.map((i) => Date.parse(i.expiryTime ?? "")).filter(Number.isFinite));
  if (!Number.isFinite(until) || until <= now) return { error: "expired" };
  return {
    kind: "vip",
    until: new Date(until).toISOString(),
    boosts: p.boosts,
    orderId: resp.latestOrderId ?? null,
  };
}

// ---------------------------------------------------------------- Google auth

const b64url = (bytes: Uint8Array) =>
  btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const b64urlText = (s: string) => b64url(new TextEncoder().encode(s));

function pemToPkcs8(pem: string): Uint8Array {
  const body = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

/** A signed JWT assertion for Google's OAuth token endpoint (RS256). */
export async function serviceAccountAssertion(
  sa: { client_email: string; private_key: string; token_uri?: string },
  scope: string,
  nowSec: number = Math.floor(Date.now() / 1000),
): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.client_email,
    scope,
    aud: sa.token_uri ?? "https://oauth2.googleapis.com/token",
    iat: nowSec,
    exp: nowSec + 3600,
  };
  const unsigned = `${b64urlText(JSON.stringify(header))}.${b64urlText(JSON.stringify(claims))}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToPkcs8(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)),
  );
  return `${unsigned}.${b64url(sig)}`;
}

export const ANDROID_PUBLISHER_SCOPE = "https://www.googleapis.com/auth/androidpublisher";
