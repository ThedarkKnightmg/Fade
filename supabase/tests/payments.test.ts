// Run: node --test supabase/tests/payments.test.ts
//
// Exercises the Payme and Click merchant protocols end to end against an
// in-memory store, plus the checkout links and the server-side charge rules.
// No network and no Supabase: the protocol logic is pure on purpose.

import { test } from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";

import { md5 } from "../functions/_shared/md5.ts";
import {
  handlePayme,
  PAYME_TIMEOUT_MS,
  paymeAuthorized,
  PaymeErr,
  type PaymentRow,
  type PaymeStore,
} from "../functions/_shared/payme_core.ts";
import { clickSign, ClickErr, handleClick } from "../functions/_shared/click_core.ts";
import {
  clickCheckoutUrl,
  paymeCheckoutUrl,
  resolveCharge,
} from "../functions/_shared/checkout.ts";

// ---------------------------------------------------------------- store

function memStore(rows: PaymentRow[], opts: { canReverse?: boolean } = {}) {
  const byId = new Map(rows.map((r) => [r.id, { ...r }]));
  const applied: string[] = [];
  const store: PaymeStore = {
    async getPayment(id) {
      return byId.get(id) ?? null;
    },
    async getByTxn(provider, txn) {
      for (const r of byId.values()) {
        if (r.provider === provider && r.provider_txn_id === txn) return r;
      }
      return null;
    },
    async update(id, patch) {
      Object.assign(byId.get(id)!, patch);
    },
    async apply(id) {
      const r = byId.get(id)!;
      if (r.status === "paid") return true;
      r.status = "paid";
      applied.push(id);
      return true;
    },
    async reverse(id) {
      if (opts.canReverse === false) return false;
      byId.get(id)!.status = "cancelled";
      return true;
    },
    async listByProviderTime(provider, from, to) {
      return [...byId.values()].filter((r) =>
        r.provider === provider && (r.provider_time ?? -1) >= from && (r.provider_time ?? -1) <= to
      );
    },
  };
  return { store, byId, applied };
}

const order = (id: string, amountTiyin = 5_000_000): PaymentRow => ({
  id,
  purpose: "wallet_topup",
  amount_tiyin: amountTiyin,
  status: "created",
  provider: null,
  provider_txn_id: null,
  provider_state: null,
  provider_time: null,
  create_time: null,
  perform_time: null,
  cancel_time: null,
  cancel_reason: null,
});

// deno-lint-ignore no-explicit-any
const call = (method: string, params: Record<string, unknown>, store: PaymeStore, now?: () => number): Promise<any> =>
  handlePayme({ method, params, id: 1 }, store, now);

// ---------------------------------------------------------------- md5

test("md5 matches node:crypto, including block boundaries and unicode", () => {
  const inputs = ["", "a", "abc", "message digest", "x".repeat(55), "x".repeat(56),
    "x".repeat(64), "x".repeat(119), "Сардор ✂️ o'g'li", "1234567" + "secret" + "abc"];
  for (const s of inputs) {
    assert.equal(md5(s), createHash("md5").update(s, "utf8").digest("hex"), JSON.stringify(s));
  }
});

// ---------------------------------------------------------------- Payme

test("payme auth: only the exact Paycom:<key> passes", () => {
  const h = (s: string) => "Basic " + btoa(s);
  assert.equal(paymeAuthorized(h("Paycom:k3y"), "k3y"), true);
  assert.equal(paymeAuthorized(h("Paycom:k3"), "k3y"), false);
  assert.equal(paymeAuthorized(h("Paycom:k3y"), ""), false);
  assert.equal(paymeAuthorized(null, "k3y"), false);
  assert.equal(paymeAuthorized("Bearer x", "k3y"), false);
});

test("payme happy path: check, create, perform grants exactly once", async () => {
  const { store, byId, applied } = memStore([order("o1")]);
  const acc = { order_id: "o1" };
  assert.deepEqual((await call("CheckPerformTransaction", { amount: 5_000_000, account: acc }, store)).result, { allow: true });

  const c = await call("CreateTransaction", { id: "pm1", time: 1000, amount: 5_000_000, account: acc }, store, () => 2000);
  assert.equal(c.result.state, 1);
  assert.equal(c.result.transaction, "o1");
  // Payme retries Create with the same id: same answer, no new transaction.
  const c2 = await call("CreateTransaction", { id: "pm1", time: 1000, amount: 5_000_000, account: acc }, store, () => 2500);
  assert.equal(c2.result.create_time, 2000);

  const p = await call("PerformTransaction", { id: "pm1" }, store, () => 3000);
  assert.equal(p.result.state, 2);
  const p2 = await call("PerformTransaction", { id: "pm1" }, store, () => 4000);
  assert.equal(p2.result.perform_time, 3000);
  assert.deepEqual(applied, ["o1"]); // granted once
  assert.equal(byId.get("o1")!.status, "paid");

  const ct = await call("CheckTransaction", { id: "pm1" }, store);
  assert.equal(ct.result.state, 2);
  const st = await call("GetStatement", { from: 0, to: 5000 }, store);
  assert.equal(st.result.transactions.length, 1);
  assert.equal(st.result.transactions[0].account.order_id, "o1");
});

test("payme refuses a wrong amount and an unknown order", async () => {
  const { store } = memStore([order("o1")]);
  const bad = await call("CheckPerformTransaction", { amount: 100, account: { order_id: "o1" } }, store);
  assert.equal(bad.error.code, PaymeErr.amount);
  const none = await call("CheckPerformTransaction", { amount: 5_000_000, account: { order_id: "nope" } }, store);
  assert.equal(none.error.code, PaymeErr.order);
});

test("payme: an order held by one transaction can't be taken by another", async () => {
  const { store } = memStore([order("o1")]);
  const acc = { order_id: "o1" };
  await call("CreateTransaction", { id: "pmA", time: 1, amount: 5_000_000, account: acc }, store, () => 10);
  const other = await call("CreateTransaction", { id: "pmB", time: 2, amount: 5_000_000, account: acc }, store, () => 20);
  assert.equal(other.error.code, PaymeErr.order);
});

test("payme: a transaction older than 12h is cancelled, not performed", async () => {
  const { store, byId, applied } = memStore([order("o1")]);
  await call("CreateTransaction", { id: "pm1", time: 1, amount: 5_000_000, account: { order_id: "o1" } }, store, () => 0);
  const late = await call("PerformTransaction", { id: "pm1" }, store, () => PAYME_TIMEOUT_MS + 1);
  assert.equal(late.error.code, PaymeErr.cantPerform);
  assert.equal(byId.get("o1")!.provider_state, -1);
  assert.equal(byId.get("o1")!.cancel_reason, 4);
  assert.deepEqual(applied, []);
});

test("payme cancel: before perform -> -1; after perform -> -2, or refused if spent", async () => {
  {
    const { store } = memStore([order("o1")]);
    await call("CreateTransaction", { id: "pm1", time: 1, amount: 5_000_000, account: { order_id: "o1" } }, store, () => 5);
    const r = await call("CancelTransaction", { id: "pm1", reason: 3 }, store, () => 6);
    assert.equal(r.result.state, -1);
  }
  {
    const { store } = memStore([order("o1")]);
    await call("CreateTransaction", { id: "pm1", time: 1, amount: 5_000_000, account: { order_id: "o1" } }, store, () => 5);
    await call("PerformTransaction", { id: "pm1" }, store, () => 6);
    const r = await call("CancelTransaction", { id: "pm1", reason: 5 }, store, () => 7);
    assert.equal(r.result.state, -2);
    // Retried cancel reports the same outcome.
    const again = await call("CancelTransaction", { id: "pm1", reason: 5 }, store, () => 8);
    assert.equal(again.result.state, -2);
  }
  {
    const { store } = memStore([order("o1")], { canReverse: false });
    await call("CreateTransaction", { id: "pm1", time: 1, amount: 5_000_000, account: { order_id: "o1" } }, store, () => 5);
    await call("PerformTransaction", { id: "pm1" }, store, () => 6);
    const r = await call("CancelTransaction", { id: "pm1", reason: 5 }, store, () => 7);
    assert.equal(r.error.code, PaymeErr.cantCancel);
  }
});

test("payme: unknown transaction and method", async () => {
  const { store } = memStore([]);
  assert.equal((await call("PerformTransaction", { id: "x" }, store)).error.code, PaymeErr.notFound);
  assert.equal((await call("Nope", {}, store)).error.code, PaymeErr.method);
});

// ---------------------------------------------------------------- Click

const SECRET = "clk-secret";
function clickReq(over: Record<string, string>) {
  const p: Record<string, string> = {
    click_trans_id: "777",
    service_id: "42",
    click_paydoc_id: "1",
    merchant_trans_id: "o1",
    amount: "50000.00",
    action: "0",
    error: "0",
    error_note: "Success",
    sign_time: "2026-11-06 12:00:00",
    ...over,
  };
  p.sign_string = clickSign(p, SECRET, p.action === "1");
  return p;
}

test("click happy path: prepare then complete grants exactly once", async () => {
  const { store, applied, byId } = memStore([order("o1")]);
  const prep = await handleClick(clickReq({}), store, SECRET, "42", () => 111);
  assert.equal(prep.error, ClickErr.ok);
  assert.equal(prep.merchant_prepare_id, 111);

  const done = await handleClick(clickReq({ action: "1", merchant_prepare_id: "111" }), store, SECRET, "42", () => 222);
  assert.equal(done.error, ClickErr.ok);
  assert.equal(done.merchant_confirm_id, 222);
  assert.equal(byId.get("o1")!.status, "paid");

  // Click retries Complete: "already paid", still one grant.
  const again = await handleClick(clickReq({ action: "1", merchant_prepare_id: "111" }), store, SECRET, "42", () => 333);
  assert.equal(again.error, ClickErr.alreadyPaid);
  assert.deepEqual(applied, ["o1"]);
});

test("click refuses a forged signature, a wrong amount and a wrong prepare id", async () => {
  const { store, applied } = memStore([order("o1")]);
  const forged = { ...clickReq({}), sign_string: "0".repeat(32) };
  assert.equal((await handleClick(forged, store, SECRET, "42")).error, ClickErr.sign);
  // Signed with someone else's secret.
  const other = clickReq({});
  other.sign_string = clickSign(other, "not-our-secret", false);
  assert.equal((await handleClick(other, store, SECRET, "42")).error, ClickErr.sign);

  assert.equal((await handleClick(clickReq({ amount: "1.00" }), store, SECRET, "42")).error, ClickErr.amount);

  await handleClick(clickReq({}), store, SECRET, "42", () => 111);
  const wrongPrep = await handleClick(clickReq({ action: "1", merchant_prepare_id: "999" }), store, SECRET, "42");
  assert.equal(wrongPrep.error, ClickErr.noTxn);
  assert.deepEqual(applied, []);
});

test("click: a failed payment (error < 0 on complete) cancels, never grants", async () => {
  const { store, applied, byId } = memStore([order("o1")]);
  await handleClick(clickReq({}), store, SECRET, "42", () => 111);
  const failed = await handleClick(
    clickReq({ action: "1", merchant_prepare_id: "111", error: "-5017", error_note: "insufficient funds" }),
    store, SECRET, "42",
  );
  assert.equal(failed.error, ClickErr.cancelled);
  assert.equal(byId.get("o1")!.status, "cancelled");
  assert.deepEqual(applied, []);
});

test("click and payme can't both hold one order", async () => {
  const { store } = memStore([order("o1")]);
  await call("CreateTransaction", { id: "pm1", time: 1, amount: 5_000_000, account: { order_id: "o1" } }, store, () => 5);
  const r = await handleClick(clickReq({}), store, SECRET, "42");
  assert.equal(r.error, ClickErr.cancelled);
});

// ---------------------------------------------------------------- checkout + rules

test("checkout links carry the order and amount", () => {
  const pm = paymeCheckoutUrl({ merchantId: "m1", paymentId: "o1", amountTiyin: 5_000_000, returnUrl: "fade://paid;x", test: true });
  assert.ok(pm.startsWith("https://test.paycom.uz/"));
  assert.equal(atob(pm.split("/").pop()!), "m=m1;ac.order_id=o1;a=5000000;c=fade://paidx");
  const ck = new URL(clickCheckoutUrl({ serviceId: "42", merchantId: "9", paymentId: "o1", amountSom: 50000 }));
  assert.equal(ck.searchParams.get("transaction_param"), "o1");
  assert.equal(ck.searchParams.get("amount"), "50000.00");
});

test("the server decides the amount, never the app", () => {
  assert.deepEqual(resolveCharge({ purpose: "wallet_topup", amount_som: 100000 }, "u", null), { amountTiyin: 10_000_000 });
  assert.ok("error" in resolveCharge({ purpose: "wallet_topup", amount_som: 1 }, "u", null));
  const b = { client_id: "u", price: 358400, status: "confirmed", paid_at: null };
  assert.deepEqual(resolveCharge({ purpose: "booking", amount_som: 1 }, "u", b), { amountTiyin: 35_840_000 });
  assert.ok("error" in resolveCharge({ purpose: "booking" }, "someone-else", b));
  assert.ok("error" in resolveCharge({ purpose: "booking" }, "u", { ...b, paid_at: "2026-01-01" }));
  assert.ok("error" in resolveCharge({ purpose: "booking" }, "u", { ...b, status: "cancelled" }));
  assert.ok("error" in resolveCharge({ purpose: "free_money" }, "u", null));
});
