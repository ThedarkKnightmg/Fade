part of '../app_state.dart';

/// The shared surface every domain mixin is allowed to reach for.
///
/// Domain mixins declare `on ChangeNotifier, AppStatePlumbing` rather than
/// `on AppState`, which would be circular (AppState is the class that mixes
/// them in). A mixin can only call members declared on its `on` types, so
/// anything genuinely shared between domains has to be named here.
///
/// That constraint is the point. AppState's domains really are coupled —
/// completing a booking charges commission and earns loyalty points — and
/// listing the couplings in one place makes them visible and reviewable
/// instead of leaving them implicit in a 3,600-line file. Everything below is
/// implemented once by [AppState]; because this is all one library, the
/// members can stay private.
mixin AppStatePlumbing on ChangeNotifier {
  /// Write the whole state blob to shared_preferences. Domains call this after
  /// a mutation they want to survive a relaunch.
  Future<void> _save();

  /// Look up a booking by id. Shared because bookings, wallet, QR check-in and
  /// the persistence layer all need it.
  Booking? _bookingById(String id);

  /// True while the signed-in barber holds VIP. Wallet reads it to halve the
  /// commission rate.
  bool get barberVip;

  /// Lifetime earnings from completed cuts, and the current week's figure in
  /// so'm. The wallet displays both.
  double get barberTotalEarned;
  int get barberEarnedThisWeekSom;

  /// Credit a VIP barber with commission the discount saved them. A method
  /// rather than a settable field so the running total stays owned by the VIP
  /// domain.
  void _recordVipSaving(int som);
}
