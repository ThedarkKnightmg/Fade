// Click SHOP API: the two calls Click makes to US when a user pays.
//
//   Prepare  (action=0)  "can this order be paid?" -> we reserve it
//   Complete (action=1)  "the money moved" (or failed) -> we grant or cancel
//
// Every call is signed: sign_string = md5(click_trans_id + service_id +
// SECRET_KEY + merchant_trans_id [+ merchant_prepare_id on Complete] + amount +
// action + sign_time). Unsigned or wrongly signed calls are refused, so nobody
// but Click can mark an order paid.
//
// Pure logic (storage via PaymeStore, shared with the Payme side), testable
// under Node. merchant_trans_id is our payments.id; amounts are in so'm.

import { md5 } from "./md5.ts";
import type { PaymentRow, PaymeStore } from "./payme_core.ts";

export const ClickErr = {
  ok: 0,
  sign: -1,
  amount: -2,
  action: -3,
  alreadyPaid: -4,
  notFound: -5,
  noTxn: -6,
  update: -7,
  request: -8,
  cancelled: -9,
} as const;

export type ClickParams = Record<string, string>;

export function clickSign(p: ClickParams, secret: string, withPrepareId: boolean): string {
  return md5(
    (p.click_trans_id ?? "") +
      (p.service_id ?? "") +
      secret +
      (p.merchant_trans_id ?? "") +
      (withPrepareId ? (p.merchant_prepare_id ?? "") : "") +
      (p.amount ?? "") +
      (p.action ?? "") +
      (p.sign_time ?? ""),
  );
}

function reply(p: ClickParams, error: number, note: string, extra: Record<string, unknown> = {}) {
  return {
    click_trans_id: p.click_trans_id ?? null,
    merchant_trans_id: p.merchant_trans_id ?? null,
    ...extra,
    error,
    error_note: note,
  };
}

const amountMatches = (p: ClickParams, row: PaymentRow) =>
  Math.round(Number(p.amount) * 100) === Number(row.amount_tiyin);

export async function handleClick(
  p: ClickParams,
  store: PaymeStore,
  secret: string,
  serviceId: string,
  now: () => number = Date.now,
): Promise<Record<string, unknown>> {
  const action = p.action;
  if (action !== "0" && action !== "1") return reply(p, ClickErr.action, "Action not found");
  if (!p.click_trans_id || !p.merchant_trans_id || !p.sign_string || !p.sign_time) {
    return reply(p, ClickErr.request, "Error in request from click");
  }
  if (serviceId && p.service_id !== serviceId) {
    return reply(p, ClickErr.request, "Unknown service");
  }
  if (clickSign(p, secret, action === "1") !== p.sign_string.toLowerCase()) {
    return reply(p, ClickErr.sign, "SIGN CHECK FAILED!");
  }

  const row = await store.getPayment(p.merchant_trans_id);
  if (!row) return reply(p, ClickErr.notFound, "Order not found");

  if (action === "0") {
    // ---------------- Prepare ----------------
    if (row.status === "paid") return reply(p, ClickErr.alreadyPaid, "Already paid");
    if (row.status === "cancelled" || row.status === "failed") {
      return reply(p, ClickErr.cancelled, "Transaction cancelled");
    }
    if (!amountMatches(p, row)) return reply(p, ClickErr.amount, "Incorrect parameter amount");
    if (row.provider === "payme" && row.provider_state === 1) {
      // Payme already holds this order.
      return reply(p, ClickErr.cancelled, "Order is being paid another way");
    }
    // Our prepare id must be an integer; the reservation time doubles as one.
    const prepareId = row.provider === "click" && row.provider_txn_id === p.click_trans_id &&
        row.create_time
      ? row.create_time
      : now();
    await store.update(row.id, {
      provider: "click",
      provider_txn_id: p.click_trans_id,
      provider_state: 1,
      provider_time: now(),
      create_time: prepareId,
      status: "pending",
    });
    return reply(p, ClickErr.ok, "Success", { merchant_prepare_id: prepareId });
  }

  // ---------------- Complete ----------------
  if (
    row.provider !== "click" ||
    row.provider_txn_id !== p.click_trans_id ||
    String(row.create_time) !== String(p.merchant_prepare_id)
  ) {
    return reply(p, ClickErr.noTxn, "Transaction does not exist");
  }
  if (row.status === "paid") {
    return reply(p, ClickErr.alreadyPaid, "Already paid", {
      merchant_confirm_id: row.perform_time,
    });
  }
  if (row.status === "cancelled") return reply(p, ClickErr.cancelled, "Transaction cancelled");
  if (!amountMatches(p, row)) return reply(p, ClickErr.amount, "Incorrect parameter amount");

  // Click reports its own failure with a negative `error`: cancel, don't grant.
  if (Number(p.error ?? 0) < 0) {
    await store.update(row.id, {
      provider_state: -1,
      cancel_time: now(),
      status: "cancelled",
    });
    return reply(p, ClickErr.cancelled, "Transaction cancelled");
  }

  const performTime = now();
  await store.update(row.id, { provider_state: 2, perform_time: performTime });
  if (!(await store.apply(row.id))) {
    return reply(p, ClickErr.update, "Failed to update user");
  }
  return reply(p, ClickErr.ok, "Success", { merchant_confirm_id: performTime });
}
