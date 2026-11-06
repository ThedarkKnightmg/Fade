# Real payments: Payme + Click

Everything is built and tested. It stays switched off until the merchant keys
are set, and until then the app shows "Payments launching soon".

## How it works

```
app ── payments-create ──► payments row (server decides the amount)
 │                          │
 └─► Payme / Click checkout │
            │               │
            └── signed calls ──► payme / click functions ──► payment_apply()
                                                               ├─ wallet credit
app polls its payments row ◄──────────────────────────────────┘└─ booking paid
```

- The app never marks anything paid. Only Payme's or Click's signed callbacks
  can, and each payment is applied once (`payment_apply` is idempotent).
- Amounts come from the server: a fixed top-up option (50k, 100k, 200k, 500k
  so'm) or the booking's stored price. The app only says what to pay for.
- A paid top-up refunded by the provider is reversed, unless it was already
  spent (Payme is then told it can't be cancelled).

## 1. Get merchant accounts (you, once)

Both need a registered business (IP or LLC) and a contract.

- **Payme Business**: business.payme.uz. You receive a merchant ID, a TEST key
  and a production key. In the cabinet set:
  - endpoint: `https://vlpfxcvoqucthtnueaoh.supabase.co/functions/v1/payme`
  - account field: `order_id`
- **Click**: click.uz, merchant section. You receive a service ID, a merchant
  ID and a secret key. Set both the Prepare and Complete URL to:
  `https://vlpfxcvoqucthtnueaoh.supabase.co/functions/v1/click`

## 2. Deploy (once, with the Supabase CLI logged in)

```bash
supabase db push                                   # adds payments, wallets
supabase functions deploy payments-create
supabase functions deploy payme --no-verify-jwt    # Payme calls it, not a user
supabase functions deploy click --no-verify-jwt    # Click calls it, not a user
```

## 3. Set the keys (Supabase dashboard → Edge Functions → Secrets)

Start with Payme's TEST key and the sandbox:

| Secret | Value |
|---|---|
| `PAYME_MERCHANT_ID` | merchant ID |
| `PAYME_KEY` | TEST key first, production key after the sandbox passes |
| `PAYME_TEST` | `1` while testing (checkout opens test.paycom.uz), remove for live |
| `CLICK_SERVICE_ID` | service ID |
| `CLICK_MERCHANT_ID` | merchant ID |
| `CLICK_SECRET_KEY` | secret key |
| `PAYMENT_RETURN_URL` | optional, where checkout sends people back |

The moment `PAYME_MERCHANT_ID` (or both Click IDs) exist, the app switches the
wallet top-up and the "Pay now" card on booking confirmation to real payments.
No new app build is needed.

## 4. Test

- Logic tests (no network): `node --test supabase/tests/payments.test.ts`
- Payme sandbox: test.paycom.uz runs its own checklist against the `payme`
  endpoint with the TEST key. Pass it before switching to the production key.
- Click: make a small real payment, then refund it from the cabinet.

## Not covered here

- VIP and Boost are digital features inside the app, so Google Play requires
  Google Play Billing for them. Payme/Click must not be used for those.
- The 5% booking commission is still deducted on the phone (see
  `wallet.dart`). The server wallet holds top-ups; moving commission
  deduction server-side is the next step before scale.
