// Run: node --test supabase/tests/play.test.ts
//
// Google Play verification for VIP / Boost: what Google's answers mean, and
// the service-account sign-in (a real RS256 signature, checked with the
// matching public key).

import { test } from "node:test";
import assert from "node:assert/strict";
import { generateKeyPairSync, createVerify } from "node:crypto";

import {
  decideProductGrant,
  decideSubscriptionGrant,
  PLAY_PRODUCTS,
  serviceAccountAssertion,
} from "../functions/_shared/play_core.ts";

test("product ids match the app's packs and VIP", () => {
  // Must equal AppState.boostPacks counts and vipMonthlyBoosts.
  assert.deepEqual(
    Object.fromEntries(Object.entries(PLAY_PRODUCTS).map(([k, v]) => [k, v.kind === "boosts" ? v.count : v.boosts])),
    { fade_boost_starter: 3, fade_boost_growth: 10, fade_boost_pro: 25, fade_vip_monthly: 5 },
  );
});

test("a boost pack grants only when Google says purchased", () => {
  assert.deepEqual(decideProductGrant("fade_boost_growth", { purchaseState: 0, orderId: "GPA.1" }),
    { kind: "boosts", count: 10, orderId: "GPA.1" });
  assert.deepEqual(decideProductGrant("fade_boost_growth", { purchaseState: 2 }), { error: "pending" });
  assert.deepEqual(decideProductGrant("fade_boost_growth", { purchaseState: 1 }), { error: "not purchased" });
  assert.deepEqual(decideProductGrant("fade_vip_monthly", { purchaseState: 0 }), { error: "unknown product" });
  assert.deepEqual(decideProductGrant("free_boosts", { purchaseState: 0 }), { error: "unknown product" });
});

test("VIP grants only an active subscription for this product, until its expiry", () => {
  const now = Date.parse("2026-11-06T12:00:00Z");
  const active = {
    subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
    latestOrderId: "GPA.2",
    lineItems: [{ productId: "fade_vip_monthly", expiryTime: "2026-12-06T12:00:00Z" }],
  };
  assert.deepEqual(decideSubscriptionGrant("fade_vip_monthly", active, now),
    { kind: "vip", until: "2026-12-06T12:00:00.000Z", boosts: 5, orderId: "GPA.2" });
  assert.deepEqual(decideSubscriptionGrant("fade_vip_monthly",
    { ...active, subscriptionState: "SUBSCRIPTION_STATE_EXPIRED" }, now), { error: "not active" });
  assert.deepEqual(decideSubscriptionGrant("fade_vip_monthly",
    { ...active, lineItems: [{ productId: "other", expiryTime: "2026-12-06T12:00:00Z" }] }, now),
    { error: "wrong product" });
  assert.deepEqual(decideSubscriptionGrant("fade_vip_monthly",
    { ...active, lineItems: [{ productId: "fade_vip_monthly", expiryTime: "2026-11-01T00:00:00Z" }] }, now),
    { error: "expired" });
});

test("service-account assertion is a valid RS256 JWT for Google's token endpoint", async () => {
  const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
  const jwt = await serviceAccountAssertion(
    { client_email: "fade@project.iam.gserviceaccount.com", private_key: pem },
    "https://www.googleapis.com/auth/androidpublisher",
    1_800_000_000,
  );
  const [h, c, s] = jwt.split(".");
  const dec = (x: string) => JSON.parse(Buffer.from(x, "base64url").toString());
  assert.deepEqual(dec(h), { alg: "RS256", typ: "JWT" });
  assert.equal(dec(c).iss, "fade@project.iam.gserviceaccount.com");
  assert.equal(dec(c).aud, "https://oauth2.googleapis.com/token");
  assert.equal(dec(c).exp - dec(c).iat, 3600);
  const ok = createVerify("RSA-SHA256").update(`${h}.${c}`).verify(publicKey, Buffer.from(s, "base64url"));
  assert.equal(ok, true);
});
