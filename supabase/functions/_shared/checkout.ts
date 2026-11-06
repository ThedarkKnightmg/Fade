// Checkout links the app opens, and the server-side rules for what may be
// paid. Pure functions, tested under Node.

/** Wallet top-up amounts the app offers (so'm). Anything else is refused. */
export const TOPUP_OPTIONS_SOM = [50000, 100000, 200000, 500000];

/**
 * Payme checkout: https://checkout.paycom.uz/<base64("m=..;ac.order_id=..;a=..;c=..")>
 * (the sandbox lives at test.paycom.uz). `a` is in tiyin.
 */
export function paymeCheckoutUrl(o: {
  merchantId: string;
  paymentId: string;
  amountTiyin: number;
  returnUrl?: string;
  lang?: string;
  test?: boolean;
}): string {
  const parts = [
    `m=${o.merchantId}`,
    `ac.order_id=${o.paymentId}`,
    `a=${o.amountTiyin}`,
  ];
  if (o.lang) parts.push(`l=${o.lang}`);
  // `;` separates fields, so it can't appear inside the return URL.
  if (o.returnUrl) parts.push(`c=${o.returnUrl.replaceAll(";", "")}`);
  const base = o.test ? "https://test.paycom.uz" : "https://checkout.paycom.uz";
  return `${base}/${btoa(parts.join(";"))}`;
}

/** Click checkout: my.click.uz/services/pay with our payment id as transaction_param. */
export function clickCheckoutUrl(o: {
  serviceId: string;
  merchantId: string;
  paymentId: string;
  amountSom: number;
  returnUrl?: string;
}): string {
  const q = new URLSearchParams({
    service_id: o.serviceId,
    merchant_id: o.merchantId,
    amount: o.amountSom.toFixed(2),
    transaction_param: o.paymentId,
  });
  if (o.returnUrl) q.set("return_url", o.returnUrl);
  return `https://my.click.uz/services/pay?${q.toString()}`;
}

export type BookingForPayment = {
  client_id: string;
  price: number; // so'm
  status: string;
  paid_at: string | null;
};

/**
 * What a payment request is allowed to charge, decided on the SERVER. The app
 * only says what it wants to pay for; the amount comes from here (a fixed
 * top-up option, or the booking's stored price), never from the request.
 */
export function resolveCharge(
  req: { purpose?: unknown; amount_som?: unknown },
  userId: string,
  booking: BookingForPayment | null,
): { amountTiyin: number } | { error: string } {
  if (req.purpose === "wallet_topup") {
    const som = Number(req.amount_som);
    if (!TOPUP_OPTIONS_SOM.includes(som)) return { error: "amount not allowed" };
    return { amountTiyin: som * 100 };
  }
  if (req.purpose === "booking") {
    if (!booking) return { error: "booking not found" };
    if (booking.client_id !== userId) return { error: "not your booking" };
    if (booking.paid_at) return { error: "already paid" };
    if (booking.status !== "requested" && booking.status !== "confirmed") {
      return { error: "booking can't be paid" };
    }
    const som = Math.round(Number(booking.price));
    if (!(som > 0)) return { error: "booking has no price" };
    return { amountTiyin: som * 100 };
  }
  return { error: "unknown purpose" };
}
