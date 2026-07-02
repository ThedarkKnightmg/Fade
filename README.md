# Barber — Modern Barbershop Booking App

A polished Flutter mobile app for discovering barbershops and booking appointments. Built with a coherent design system, fluid animations, and a complete booking flow from discovery to confirmation.

## Features

- Animated splash and onboarding flow
- Auth screens (sign-in / sign-up) with form validation
- Home with featured barbershops, categories, search, and filters
- Hero-animated barbershop detail page with services, barbers, gallery, reviews
- Multi-step booking flow: service → barber → date → time → confirm
- Animated booking confirmation
- My Bookings with status filters (Upcoming / Completed / Cancelled)
- Profile with settings, theme, language

## Design System

- **Palette:** charcoal-on-cream with a warm gold accent (`#C9A86A`)
- **Type:** Poppins display + Inter body (Google Fonts)
- **Spacing:** 4 / 8 / 12 / 16 / 24 / 32 / 48 grid
- **Radii:** 8 / 16 / 24 / 32 with consistent elevation
- **Motion:** spring curves, staggered lists, hero transitions, shared-axis page routes

## Run

```bash
flutter pub get
flutter run
```

## Project Layout

```
lib/
├── main.dart
├── core/                # theme, constants, animation utils
├── data/                # models + mock repository
└── presentation/        # screens, widgets, navigation
```
