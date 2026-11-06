// The real PaymeStore: the `payments` table, written with the service role.
// Shared by the payme and click Edge Functions (Deno only).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { PaymentRow, PaymeStore } from "./payme_core.ts";

export const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const paymentsStore: PaymeStore = {
  async getPayment(id) {
    if (!UUID.test(id)) return null; // a junk order id is simply "not found"
    const { data } = await admin.from("payments").select("*").eq("id", id).maybeSingle();
    return (data as PaymentRow) ?? null;
  },
  async getByTxn(provider, txnId) {
    if (!txnId) return null;
    const { data } = await admin
      .from("payments")
      .select("*")
      .eq("provider", provider)
      .eq("provider_txn_id", txnId)
      .maybeSingle();
    return (data as PaymentRow) ?? null;
  },
  async update(id, patch) {
    const { error } = await admin.from("payments").update(patch).eq("id", id);
    if (error) throw error;
  },
  async apply(id) {
    const { data, error } = await admin.rpc("payment_apply", { p_payment: id });
    if (error) throw error;
    return data === true;
  },
  async reverse(id) {
    const { data, error } = await admin.rpc("payment_reverse", { p_payment: id });
    if (error) throw error;
    return data === true;
  },
  async listByProviderTime(provider, from, to) {
    const { data } = await admin
      .from("payments")
      .select("*")
      .eq("provider", provider)
      .gte("provider_time", from)
      .lte("provider_time", to)
      .order("provider_time");
    return (data as PaymentRow[]) ?? [];
  },
};
