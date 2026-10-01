# Fade — a two-sided barbershop marketplace

A production-minded Flutter app for the Uzbek market where **clients book
haircuts and barbers run their chair**, both in one app with a role switch.
Built around a real backend, three languages, and a design system with a single
blue accent.

> 56k lines of Dart across 164 files · 9 test suites · Supabase backend with
> row-level security · EN / RU / UZ throughout

**[⬇ Download the Android app (APK)](https://github.com/ThedarkKnightmg/Fade/releases/latest)** · Android 7+ · sign in with Telegram, Google or Apple

---

## What's in it

**Booking, end to end**
Discover shops on a real map of Tashkent, pick a service → barber → date →
time, and get a confirmation screen with a ticket, a QR code and a calendar
hand-off. Bookings carry real status (requested, upcoming, completed,
cancelled, no-show), and the home screen changes its call to action to match.

**Two sides, one app**
A role switch turns the client app into the barber's: a roster, incoming
booking requests to confirm, walk-ins, history, a wallet, and anti
double-booking checks.

**Phone sign-in via a Telegram bot**
SMS costs money per login and Telegram is what everyone here already uses. A
Supabase Edge Function mints a one-time code bound to the device, the bot
verifies the number Telegram itself confirmed, and the function issues a real
Supabase session — not a local "logged in" flag. Google and Apple sign-in sit
alongside it.

**AI hair try-on, on device**
Face analysis runs locally; a hair mask is painted over the selfie, with an
optional Cloudflare Worker for full inpainting renders. No API key is required
for the free path.

**Built to convert**
Scarcity cues, social proof, a goal-gradient loyalty card (Fade Points), and a
variable surprise reward at the moment satisfaction peaks — the booking
confirmation. Two waiting-chair mini-games fill the dead time before your turn
and pay into the same points balance.

**Trust and safety**
Legal consent is recorded with a timestamp and document version, reviews are
dual-key, there's a no-show shield, account deletion is a server function, and
the database is locked down with row-level security policies.

---

## Architecture

```
lib/
├── core/           theme · i18n (EN/RU/UZ) · animations · map · AI · Supabase
├── data/           models · AppState (split into parts) · repositories
└── presentation/   21 feature areas, screens + widgets
supabase/
├── migrations/     schema + RLS policies
└── functions/      telegram-login · delete-account · SMS · feedback · seed
```

**State** — a single `AppState` `ChangeNotifier`, split into focused part files
(loyalty, wallet, mini-game, catalogue, legal consent) with debounced
persistence, rather than one unreadable file.

**Localisation** — every string goes through `L._t(en, ru, uz)`, with a root
rebuild on language change. No string is hardcoded in a screen.

**Design system** — one blue accent (`#2E8BFF`) on paper-like surfaces, Nunito
throughout, light and dark. Motion is purposeful: shared-axis routes, staggered
entrances, and a liquid tab indicator.

**Maps** — `flutter_map` with CARTO basemaps and disk-cached tiles.

---

## Tests

```bash
flutter test
```

Covers money maths, loyalty points, catalogue states, the mini-game, security
rules, and a guard for an Android resource clash that only breaks release
builds.

---

## Run it

```bash
flutter pub get
flutter run
```

The app runs on mock data out of the box. To point it at a live backend, fill in
`lib/core/supabase/supabase_config.dart` and apply `supabase/migrations/`.

**Build a release bundle**

```bash
flutter build appbundle --release
```

Release signing reads `android/key.properties`, which is intentionally not in
this repository.

---

## Status

Shipping toward a Play Store release: `uz.fade.app`, signed release bundle
building, backend deployed. The barber side and payments are on mock data while
the marketplace rules are finished server-side.
