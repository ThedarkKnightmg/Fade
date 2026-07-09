# Fade — Deficiency Fix Plan

Fixes for the 31 audit findings. **One (#1 "bookings vanish") is a false positive** —
`notifyListeners()` (app_state.dart:1962-1971) already schedules a debounced `_save()`,
and `_save()` persists the user's bookings, so they survive restarts. That leaves
**30 real deficiencies**, grouped into 6 batches by root cause.

Almost everything lives in `lib/data/app_state.dart`. Work top-to-bottom: each batch is
self-contained and independently shippable.

Principle: keep the **flat 5% / 2.5%-VIP** monetization model the owner chose — do not
re-introduce the old "regulars ~0%" tier; just remove its dead code.

---

## Batch A — State-integrity guards (money & terminal states)
**Why first:** smallest, lowest-risk, prevents invalid data (negative wallet, double-charge).
**Findings:** #3, #12, #16, #18, #31, + the dead-tier cleanup, + #17/#29 money-model decision.

1. **Wallet can't go negative (#3).** In `verifyAndComplete()` / `completeBooking()`
   (app_state.dart:843, 1445): before charging, if `_walletSom < commissionSomFor(b)`,
   block completion and return a `needsTopUp` result the UI surfaces ("Top up to complete").
   In `_chargeCommission()` clamp `_walletSom = max(0, _walletSom - fee)` as a floor.
2. **Terminal states are mutually exclusive (#16).** In `completeBooking()` add a guard:
   `if (b.status is completed/noShow/cancelled/declined) return;`. In `verifyAndComplete()`
   widen the guard (line 1449) to also bail on `noShow/cancelled/declined`. Exclude
   non-`upcoming` bookings from `todayScannable` (line 1459) so a no-showed booking can't
   be re-scanned into a completion.
3. **No completing before the appointment (#12, #18).** Gate `verifyAndComplete()` /
   the schedule "Mark done" (barber_schedule_screen.dart:826) to a window
   `now ∈ [b.dateTime − 15m, b.dateTime + duration + 30m]`; reject early scans with a hint.
4. **No-show vs commission (#31).** Decide policy: either `markNoShowWithCharge()` also
   records the platform commission (keeping the client 50% shield separate), or document
   that no-show waives platform commission. Recommend: keep the fee, add a clear code note.
5. **Dead returning-client tier (wallet-medium).** Delete `isReturningClient` and
   `regularFlatFeeSom` (unused) and fix the stale header comments so code == the flat model.
6. **Boost/VIP money model (#17, #29 low).** Pick one: (a) deduct `pack.priceSom` /
   `vipMonthlySom` from `_walletSom` in `buyBoostPack`/`activateVipBoost` with an
   insufficient-funds guard + a ledger row, **or** (b) keep them as external-provider
   purchases and stop showing the wallet balance on the Boost screen as if it funds them.
   Recommend (a) for a coherent in-app economy; write a `WalletTx` debit either way.

**Acceptance:** wallet never renders negative; a booking can be in exactly one terminal
state; "Mark done" is disabled before the slot; buying a pack moves the wallet + logs a row.

---

## Batch B — Booking availability & double-booking
**Findings:** #2 (high), #10 (high), #27, #28, #30.

1. **Block a booking's whole duration, not just its start (#2).** In `blockedSlotsFor()`
   (app_state.dart:1078-1095) and the client `_booked` sets
   (booking_flow_screen.dart:88-109, barbershop_detail_screen.dart:100-120): expand each
   occupying booking to **every 30-min slot in `[start, start + service.durationMinutes)`**
   (mirror the barber schedule's `_end(b)` span at barber_schedule_screen.dart:1379).
2. **Fold breaks into the block set (#28).** Add `barberBreaksOn(day)` windows into
   `blockedSlotsFor()` (expand each break to the 30-min starts it covers). `BarberBreak`
   already exposes `endMinutes`/`appliesOn(day)`.
3. **Enforce off-days client-side (#27).** In the client slot builders, if
   `AppState.instance.offDays.contains(day.weekday)` return no slots (and grey/hide the
   date pill). See per-shop note below.
4. **Guard walk-in logging (#30).** In `addWalkIn()` (app_state.dart:1049) and
   walk_in_sheet.dart:64, refuse/warn if the chosen `dateTime` collides with an existing
   `blockedSlotsFor(...)` entry — the same guard clients already get.
5. **Per-shop hours & off-days (#10, high).** `_workStart/_workEnd/_offDays` are global and
   wrongly bound *every* shop's grid. Move hours + off-days onto the `Barbershop`/`Barber`
   model (or a `Map<shopId, Hours>`), seed each shop with defaults, and drive
   `MockData.timeSlotsFor(...)` from the **shop being booked**, not global `AppState`.
   Only the owner's edits affect their own shop.

**Acceptance:** a 95-min combo blocks 14:00–15:30; lunch (13:00) is un-bookable by clients;
a barber's off-day shows no client slots; a walk-in can't land on a taken slot; browsing
shop B is not bounded by the local barber's hours.

---

## Batch C — Persistence: add the missing fields
**Findings:** #5, #7, #8, #9, #22, #23, #24 (#1 is a false positive).
Mutators already trigger a save via `notifyListeners()`; the gap is that `_save()`/`load()`
simply **omit these fields**. Add them.

Add to `_save()` (2074) and `load()` (1973):
- `walletSom` (int) + `_ledger` (JSON list of `WalletTx`) + a persisted `ledgerSeeded` flag
  so `_ensureLedgerSeed()` doesn't re-inject demo rows over restored data. (#7)
- `vipUntil` (epoch ms, remove key when null) + `vipCommissionSavedSom` (int). (#8)
- `boosts` (int) + `boostActiveUntil` (epoch ms, remove when null). (#9)
- `myBarberShopId` + `myBarberId` (strings, remove when null). (#22)
- `myServices` (JSON: id/name/price/duration/enabled) + `breaks` (JSON: id/start/end/daily). (#23)
  Note: `_myServices` is `late final` — make it a mutable field so restore can repopulate.
- `verifiedScanStreak` (JSON `Map<String,int>`). (#24) For named-client no-show/streak history
  to be meaningful across restarts, either persist those counters independently or persist the
  named-client bookings that carry status changes (currently re-seeded each launch).

**Acceptance:** top up + fees, buy VIP + a pack, set a custom barber/service/break/off-day,
kill & relaunch → everything is exactly as left; the ledger shows real history, not the 3 demo rows.

---

## Batch D — Client identity & QR handshake
**Findings:** #6 (high), #19.
Root cause: the current user's own bookings carry `clientName == null`, but the barber scan
only matches `clientName != null` bookings, and the verified-streak map is keyed by name — so
the handshake and VIP streak never fire for the real user.

1. Give the signed-in user a **stable client identity** (e.g. `clientId`/`clientName` from the
   profile, or a constant `"me"`), and stamp it on user-created bookings in `addBooking` /
   the booking flow.
2. Include the user's own bookings in `todayScannable` / the scan-match set (scan_client_sheet.dart:70).
3. Key `_verifiedScanStreak` on that stable identity so `verifyAndComplete` (line 1452) advances it.
4. Drive the ticket's VIP progress (booking_ticket_screen.dart:31) from the **same** source the
   handshake advances (`verifiedScanStreakFor`), not raw completed-count (fixes #19 and feeds Batch F).

**Acceptance:** a real client booking, once confirmed, can be scanned by the barber → verifies,
locks commission, advances the client's VIP streak; the ticket bar reflects that same streak.

---

## Batch E — Make VIP/Boost real + fix money-facing numbers
**Findings:** #4 (high), #13, #14/#20.

1. **Wire placement (#4).** In the client map (shops_map_screen.dart) and search/sort
   (home_screen.dart `_ShopsSection._list`, explore_screen.dart:46): float the signed-in
   barber's shop to the top and render the **gold pin** when
   `AppState.instance.barberBoosted` (boost active or VIP). This makes the sold perk observable
   in the mock. (Full multi-barber ranking waits for the backend, but the demo must show *an* effect.)
2. **Month-scope the dashboard numbers (#14/#20).** Filter `vipMonthlyFeeSavingEstSom` (1324)
   and `completedBookingsThisMonth` (1336) to the current calendar month
   (`b.dateTime.isAfter(DateTime(now.year, now.month, 1))`), matching the "this month" labels.
3. **One "VIP saved" source of truth (#13).** Use the real accumulator `_vipCommissionSavedSom`
   on both the dashboard and the VIP explainer (or make the estimate also require VIP-at-charge-time),
   so the two screens agree.

**Acceptance:** activating VIP/Boost visibly floats + gold-pins the shop on the client map;
"saved this month" resets on the 1st; the dashboard and explainer show the same saved figure.

---

## Batch F — Loyalty consistency & review integrity
**Findings:** #21, #25, #26, canReviewShop-medium.

1. **Perks earned by visits, not requests (#21).** Move `addPerk(...)` out of
   `BookingConfirmationScreen.initState` and grant it from `verifyAndComplete`/`completeBooking`
   on the user's own booking; dedup by booking id (persisted `awardedPerkBookingIds` set) so a
   re-render can't mint duplicates. (Passes are display-only today, but stop the free farming.)
2. **One loyalty metric everywhere (#25, #26).** Add a single `AppState.loyaltyVisits` +
   `loyaltyProgress` (based on verified visits, no cosmetic `+11`) and have the home bonus sheet
   (home_screen.dart:1279), the ticket (booking_ticket_screen.dart:31), and the confirmation punch
   card (booking_confirmation_screen.dart:372) all read it. Kills the "permanently unlocked" bar.
3. **Review gating (medium).** `canReviewShop(shopId)` (app_state.dart:1474) must require an own
   booking with `status == completed` (and/or `verifiedAt != null`), not merely existence — so a
   review can't be posted from an unconfirmed request or a declined/cancelled booking.

**Acceptance:** passes only appear after a completed visit and never duplicate; all three loyalty
surfaces show the same progress and it advances from 0; "Write review" is locked until a completed visit.

---

## Suggested order, risk, and verification
1. **A** (guards) → 2. **C** (persistence) → 3. **B** (availability) → 4. **D** (identity/QR)
   → 5. **E** (VIP/Boost real) → 6. **F** (loyalty).

- **Lowest risk:** A, C, E-2/E-3, F. **Higher risk (touch shared logic/models):** B-5 (per-shop
  hours), D (identity threads through bookings/streak), E-1 (map/sort).
- After each batch: `flutter analyze lib` must stay clean; then build + install and walk the
  specific acceptance scenario above.
- Recommended: re-run the multi-agent audit workflow after Batches A–F to confirm each finding
  is closed and nothing regressed.

**Effort estimate:** A ≈ half-day, C ≈ half-day, B ≈ 1 day (B-5 is the bulk), D ≈ half-day,
E ≈ half-day, F ≈ half-day. ~3–4 focused days total.
