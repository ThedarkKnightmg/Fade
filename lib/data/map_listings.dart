import 'dart:math' as math;

/// A single map "listing" — one price point on the discovery map. Most are
/// procedurally scattered across Tashkent so the map reads dense and alive
/// (Yandex-style); each routes to one of the real barbershops when tapped.
class MapListing {
  const MapListing({
    required this.id,
    required this.lat,
    required this.lng,
    required this.fromUsd,
    required this.hot,
    required this.featured,
    required this.shopIndex,
  });

  final String id;
  final double lat;
  final double lng;

  /// "Haircut from" price (USD) — rendered as a compact so'm tag.
  final double fromUsd;

  /// Trending right now → shows a flame.
  final bool hot;

  /// Sponsored / brand spot → gold scissors-coin.
  final bool featured;

  /// Which real barbershop this point opens (modulo the real shop count).
  final int shopIndex;
}

/// Generates and caches a stable, dense set of Tashkent listings. Computed
/// once (seeded) so markers never jump between rebuilds.
class MapListings {
  MapListings._();

  static List<MapListing>? _cache;
  static List<MapListing> get tashkent => _cache ??= _generate();

  // Real Tashkent districts to crowd points around (lat, lng, weight).
  static const List<List<double>> _hotspots = [
    [41.3110, 69.2790, 5], // Center / Amir Temur
    [41.2856, 69.2034, 4], // Chilonzor
    [41.3640, 69.2870, 4], // Yunusobod
    [41.3290, 69.3340, 3], // Mirzo Ulugbek
    [41.2730, 69.2680, 3], // Yakkasaray / Sergeli road
    [41.3540, 69.2230, 2], // Olmazor
    [41.2520, 69.1880, 2], // Sergeli
    [41.3380, 69.3520, 2], // Qoraqamish
    [41.2980, 69.2480, 3], // Shayxontohur
  ];

  static List<MapListing> _generate() {
    final rng = math.Random(73);
    final out = <MapListing>[];

    // Total weight for weighted hotspot picking.
    final totalW = _hotspots.fold<double>(0, (s, h) => s + h[2]);

    // ~110 clustered points around the districts.
    for (var i = 0; i < 110; i++) {
      // Weighted pick of a hotspot.
      var r = rng.nextDouble() * totalW;
      var spot = _hotspots.first;
      for (final h in _hotspots) {
        if (r < h[2]) {
          spot = h;
          break;
        }
        r -= h[2];
      }
      // Triangular scatter (peaks at the centre) — tighter for big districts.
      final spread = 0.010 + rng.nextDouble() * 0.022;
      final dLat = (rng.nextDouble() - rng.nextDouble()) * spread;
      final dLng = (rng.nextDouble() - rng.nextDouble()) * spread * 1.3;
      out.add(_make(rng, 'c$i', spot[0] + dLat, spot[1] + dLng));
    }

    // ~30 uniform points across the city so outskirts aren't empty.
    for (var i = 0; i < 30; i++) {
      final lat = 41.230 + rng.nextDouble() * 0.150;
      final lng = 69.150 + rng.nextDouble() * 0.220;
      out.add(_make(rng, 'u$i', lat, lng));
    }

    return out;
  }

  static MapListing _make(math.Random rng, String id, double lat, double lng) {
    return MapListing(
      id: id,
      lat: lat,
      lng: lng,
      fromUsd: 16 + rng.nextDouble() * 48, // ≈ 200k–820k so'm
      hot: rng.nextDouble() < 0.17,
      featured: rng.nextDouble() < 0.08,
      shopIndex: rng.nextInt(6),
    );
  }
}
