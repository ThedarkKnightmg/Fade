part of '../app_state.dart';

/// Where the live shop catalogue stands right now.
///
/// This exists because "no shops" and "shops not here yet" and "the network
/// failed" are three different things, and the app used to render all three the
/// same way: as the five demo shops. On the live path that is the worst
/// possible answer — a demo shop's ids aren't database UUIDs, so a booking made
/// against one is silently dropped by [BookingRepository] and lives only on the
/// client's phone. They get a confirmation, the booking sits in "My bookings",
/// and no barber ever sees it.
enum CatalogueStatus {
  /// First load in flight; nothing real to show yet.
  loading,

  /// Real shops are loaded and bookable.
  ready,

  /// The server answered, honestly, with no shops.
  empty,

  /// The fetch failed (offline, timeout, server error) and we have nothing
  /// real cached to fall back on.
  failed,
}

/// Owns the live shop catalogue: fetching it, and being honest about what
/// happened when the fetch didn't produce shops.
mixin CatalogueState on ChangeNotifier {
  /// In demo mode the bundled shops *are* the catalogue, so there is nothing to
  /// wait for and the status starts [CatalogueStatus.ready].
  CatalogueStatus _catalogueStatus = SupabaseConfig.useRealCatalogue
      ? CatalogueStatus.loading
      : CatalogueStatus.ready;

  CatalogueStatus get catalogueStatus => _catalogueStatus;

  /// True while the first load is still in flight with nothing to show.
  bool get catalogueLoading => _catalogueStatus == CatalogueStatus.loading;

  /// True when there are real, bookable shops on screen.
  bool get catalogueReady => _catalogueStatus == CatalogueStatus.ready;

  /// The shops a client may browse and book. Empty unless the catalogue is
  /// [CatalogueStatus.ready], so no surface can accidentally render a stale or
  /// demo list while the status says otherwise.
  List<Barbershop> get catalogue =>
      catalogueReady ? List.unmodifiable(MockData.barbershops) : const [];

  /// Pull the live shops from Supabase and swap them in for the visible
  /// catalogue. Every screen reads `MockData.barbershops`, so replacing its
  /// contents flips the whole app to real data in one place.
  ///
  /// A failure never wipes shops we already have — that would turn a flaky
  /// network into an empty app for a user who was mid-browse. It only becomes
  /// [CatalogueStatus.failed] when there was nothing real to lose.
  Future<void> loadCatalogue() async {
    if (!SupabaseConfig.useRealCatalogue) return;
    final hadRealShops = _catalogueStatus == CatalogueStatus.ready;
    if (!hadRealShops && _catalogueStatus != CatalogueStatus.loading) {
      _catalogueStatus = CatalogueStatus.loading;
      notifyListeners();
    }
    try {
      final shops =
          await ShopRepository.fetchShops().timeout(const Duration(seconds: 6));
      MockData.barbershops
        ..clear()
        ..addAll(shops);
      _catalogueStatus =
          shops.isEmpty ? CatalogueStatus.empty : CatalogueStatus.ready;
    } catch (e) {
      debugPrint('loadCatalogue failed: $e');
      if (!hadRealShops) _catalogueStatus = CatalogueStatus.failed;
    }
    notifyListeners();
  }

  /// What the "Try again" button on the browse surfaces calls.
  Future<void> retryCatalogue() {
    _catalogueStatus = CatalogueStatus.loading;
    notifyListeners();
    return loadCatalogue();
  }
}
