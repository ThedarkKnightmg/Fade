// Payme Merchant API (JSON-RPC 2.0), the protocol Payme uses to call US.
//
// Pure logic, no Deno or Supabase imports: storage comes in through the
// PaymeStore interface. That keeps the whole protocol testable under Node
// (supabase/tests/payments.test.ts) and the Edge Function a thin wrapper.
//
// One `payments` row is one order. Payme's account field is `order_id` (set
// the same name in the Payme merchant cabinet). Amounts are in tiyin.
//
// Protocol summary (docs: developer.help.paycom.uz):
//   CheckPerformTransaction  can this order be paid this amount?
//   CreateTransaction        Payme reserves the order (state 1)
//   PerformTransaction       money moved: state 2, grant the effect
//   CancelTransaction        state -1 (before perform) or -2 (after, refund)
//   CheckTransaction         report a transaction's state
//   GetStatement             list transactions in a time window

export interface PaymentRow {
  id: string;
  purpose: string;
  amount_tiyin: number;
  status: string; // created | pending | paid | cancelled | failed
  provider: string | null;
  provider_txn_id: string | null;
  provider_state: number | null;
  provider_time: number | null;
  create_time: number | null;
  perform_time: number | null;
  cancel_time: number | null;
  cancel_reason: number | null;
}

export interface PaymeStore {
  getPayment(id: string): Promise<PaymentRow | null>;
  getByTxn(provider: string, txnId: string): Promise<PaymentRow | null>;
  update(id: string, patch: Partial<PaymentRow>): Promise<void>;
  /** Grant the payment's effect once (payment_apply). */
  apply(id: string): Promise<boolean>;
  /** Undo a granted payment; false when it can't be undone. */
  reverse(id: string): Promise<boolean>;
  listByProviderTime(provider: string, from: number, to: number): Promise<PaymentRow[]>;
}

/** Unpaid Payme transactions expire after 12 hours (their rule). */
export const PAYME_TIMEOUT_MS = 12 * 60 * 60 * 1000;

export const PaymeErr = {
  parse: -32700,
  method: -32601,
  auth: -32504,
  amount: -31001,
  notFound: -31003,
  cantCancel: -31007,
  cantPerform: -31008,
  order: -31050, // -31050..-31099: problems with the account (order)
} as const;

type Rpc = { method?: string; params?: Record<string, unknown>; id?: unknown };

const msg = (en: string, ru: string, uz: string) => ({ en, ru, uz });

function err(id: unknown, code: number, message: ReturnType<typeof msg>, data?: string) {
  return { error: { code, message, ...(data ? { data } : {}) }, id: id ?? null };
}

function ok(id: unknown, result: unknown) {
  return { result, id: id ?? null };
}

/** Constant-time-ish check of Payme's Basic auth header ("Paycom:<key>"). */
export function paymeAuthorized(header: string | null, key: string): boolean {
  if (!header || !key || !header.startsWith("Basic ")) return false;
  let decoded = "";
  try {
    decoded = atob(header.slice(6).trim());
  } catch {
    return false;
  }
  const expected = `Paycom:${key}`;
  if (decoded.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) {
    diff |= decoded.charCodeAt(i) ^ expected.charCodeAt(i);
  }
  return diff === 0;
}

const ORDER_MISSING = msg("Order not found", "Заказ не найден", "Buyurtma topilmadi");
const ORDER_BUSY = msg(
  "Order is already being paid or is not payable",
  "Заказ уже оплачивается или недоступен",
  "Buyurtma allaqachon to'lanmoqda yoki mavjud emas",
);
const BAD_AMOUNT = msg("Incorrect amount", "Неверная сумма", "Noto'g'ri summa");
const NO_TXN = msg("Transaction not found", "Транзакция не найдена", "Tranzaksiya topilmadi");
const CANT_PERFORM = msg(
  "Transaction cannot be performed",
  "Невозможно выполнить операцию",
  "Amalni bajarib bo'lmaydi",
);
const CANT_CANCEL = msg(
  "Transaction cannot be cancelled",
  "Невозможно отменить транзакцию",
  "Tranzaksiyani bekor qilib bo'lmaydi",
);

function orderIdOf(params: Record<string, unknown>): string {
  const account = (params.account ?? {}) as Record<string, unknown>;
  return String(account.order_id ?? "");
}

/** Is this payment row open to a NEW Payme transaction for `amount`? */
async function checkOrder(
  store: PaymeStore,
  rpcId: unknown,
  params: Record<string, unknown>,
): Promise<{ payment: PaymentRow } | { error: unknown }> {
  const orderId = orderIdOf(params);
  const payment = orderId ? await store.getPayment(orderId) : null;
  if (!payment) return { error: err(rpcId, PaymeErr.order, ORDER_MISSING, "order_id") };
  if (Number(params.amount) !== Number(payment.amount_tiyin)) {
    return { error: err(rpcId, PaymeErr.amount, BAD_AMOUNT) };
  }
  if (payment.status !== "created" && payment.status !== "pending") {
    return { error: err(rpcId, PaymeErr.order, ORDER_BUSY, "order_id") };
  }
  return { payment };
}

function txnView(p: PaymentRow) {
  return {
    create_time: p.create_time ?? 0,
    perform_time: p.perform_time ?? 0,
    cancel_time: p.cancel_time ?? 0,
    transaction: p.id,
    state: p.provider_state ?? 0,
    reason: p.cancel_reason ?? null,
  };
}

/** Handle one Payme JSON-RPC call. `now` is injectable for tests. */
export async function handlePayme(
  rpc: Rpc,
  store: PaymeStore,
  now: () => number = Date.now,
): Promise<unknown> {
  const id = rpc.id;
  const params = (rpc.params ?? {}) as Record<string, unknown>;

  switch (rpc.method) {
    case "CheckPerformTransaction": {
      const r = await checkOrder(store, id, params);
      if ("error" in r) return r.error;
      if (r.payment.provider_state === 1) {
        // Another live Payme transaction already holds this order.
        return err(id, PaymeErr.order, ORDER_BUSY, "order_id");
      }
      return ok(id, { allow: true });
    }

    case "CreateTransaction": {
      const txnId = String(params.id ?? "");
      const existing = txnId ? await store.getByTxn("payme", txnId) : null;
      if (existing) {
        if (existing.provider_state !== 1) {
          return err(id, PaymeErr.cantPerform, CANT_PERFORM);
        }
        if (now() - (existing.create_time ?? 0) > PAYME_TIMEOUT_MS) {
          await store.update(existing.id, {
            provider_state: -1,
            cancel_time: now(),
            cancel_reason: 4,
            status: "cancelled",
          });
          return err(id, PaymeErr.cantPerform, CANT_PERFORM);
        }
        return ok(id, {
          create_time: existing.create_time,
          transaction: existing.id,
          state: existing.provider_state,
        });
      }
      const r = await checkOrder(store, id, params);
      if ("error" in r) return r.error;
      const p = r.payment;
      if (p.provider_txn_id && p.provider_state === 1) {
        // The order is held by a different, still-open transaction.
        return err(id, PaymeErr.order, ORDER_BUSY, "order_id");
      }
      const createTime = now();
      await store.update(p.id, {
        provider: "payme",
        provider_txn_id: txnId,
        provider_state: 1,
        provider_time: Number(params.time ?? createTime),
        create_time: createTime,
        status: "pending",
      });
      return ok(id, { create_time: createTime, transaction: p.id, state: 1 });
    }

    case "PerformTransaction": {
      const p = await store.getByTxn("payme", String(params.id ?? ""));
      if (!p) return err(id, PaymeErr.notFound, NO_TXN);
      if (p.provider_state === 2) {
        return ok(id, { transaction: p.id, perform_time: p.perform_time, state: 2 });
      }
      if (p.provider_state !== 1) return err(id, PaymeErr.cantPerform, CANT_PERFORM);
      if (now() - (p.create_time ?? 0) > PAYME_TIMEOUT_MS) {
        await store.update(p.id, {
          provider_state: -1,
          cancel_time: now(),
          cancel_reason: 4,
          status: "cancelled",
        });
        return err(id, PaymeErr.cantPerform, CANT_PERFORM);
      }
      const performTime = now();
      await store.update(p.id, { provider_state: 2, perform_time: performTime });
      await store.apply(p.id); // the ONLY place money turns into a grant
      return ok(id, { transaction: p.id, perform_time: performTime, state: 2 });
    }

    case "CancelTransaction": {
      const p = await store.getByTxn("payme", String(params.id ?? ""));
      if (!p) return err(id, PaymeErr.notFound, NO_TXN);
      const reason = Number(params.reason ?? 0) || null;
      if (p.provider_state === 1) {
        const t = now();
        await store.update(p.id, {
          provider_state: -1,
          cancel_time: t,
          cancel_reason: reason,
          status: "cancelled",
        });
        return ok(id, { transaction: p.id, cancel_time: t, state: -1 });
      }
      if (p.provider_state === 2) {
        if (!(await store.reverse(p.id))) return err(id, PaymeErr.cantCancel, CANT_CANCEL);
        const t = now();
        await store.update(p.id, {
          provider_state: -2,
          cancel_time: t,
          cancel_reason: reason,
          status: "cancelled",
        });
        return ok(id, { transaction: p.id, cancel_time: t, state: -2 });
      }
      // Already cancelled: report it again (Payme retries are normal).
      return ok(id, { transaction: p.id, cancel_time: p.cancel_time, state: p.provider_state });
    }

    case "CheckTransaction": {
      const p = await store.getByTxn("payme", String(params.id ?? ""));
      if (!p) return err(id, PaymeErr.notFound, NO_TXN);
      return ok(id, txnView(p));
    }

    case "GetStatement": {
      const rows = await store.listByProviderTime(
        "payme",
        Number(params.from ?? 0),
        Number(params.to ?? 0),
      );
      return ok(id, {
        transactions: rows.map((p) => ({
          id: p.provider_txn_id,
          time: p.provider_time,
          amount: p.amount_tiyin,
          account: { order_id: p.id },
          ...txnView(p),
        })),
      });
    }

    default:
      return err(id, PaymeErr.method, msg("Method not found", "Метод не найден", "Metod topilmadi"));
  }
}
