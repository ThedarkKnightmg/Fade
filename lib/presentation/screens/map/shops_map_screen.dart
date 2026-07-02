import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/format/thousands_formatter.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/location/geo_position.dart';
import '../../../core/map/fast_tiles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/map_listings.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../barbershop_detail/barbershop_detail_screen.dart';
import '../booking/booking_flow_screen.dart';

/// Map category chips — narrow the pins by type. Price is a separate budget.
enum _MapFilter { all, premium, hot }

/// A real map of Tashkent, Uzbekistan (OpenStreetMap tiles), packed with shop
/// price points. Yandex-style: zoom out and points become grey dots that
/// cluster into counts; zoom in and they bloom into so'm price tags. Hot spots
/// flame; sponsored spots wear a gold scissors-coin.
class ShopsMapScreen extends StatefulWidget {
  const ShopsMapScreen({super.key, this.embedded = false});

  /// When shown as a bottom-nav tab (vs. a pushed route) we drop the back
  /// button and the map fills the whole screen.
  final bool embedded;

  @override
  State<ShopsMapScreen> createState() => _ShopsMapScreenState();
}

class _ShopsMapScreenState extends State<ShopsMapScreen>
    with TickerProviderStateMixin {
  // Tashkent — the city the shops live in.
  static const LatLng _tashkent = LatLng(41.3175, 69.2800);

  /// The user's real position — defaults to the city centre until GPS resolves.
  LatLng _you = const LatLng(41.3155, 69.2790);
  static const double _minZoom = 5; // zoomed out → whole Uzbekistan
  static const double _maxZoom = 18;
  static const double _cityZoom = 12.5;

  /// At/above this zoom, points render as price tags; below, as dots.
  static const double _pillZoom = 13.2;

  final MapController _map = MapController();

  /// Live camera zoom — drives clustering + dot/tag switching.
  double _currentZoom = _cityZoom;

  /// Debounce so we only re-cluster once a gesture settles (keeps the pinch
  /// buttery instead of rebuilding every marker mid-zoom).
  Timer? _reclusterTimer;

  // Smooth, animated camera for the zoom / recenter buttons (flutter_map's
  // own `move` is instant, so we tween it ourselves).
  late final AnimationController _camCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )
    ..addListener(_tickCamera)
    ..addStatusListener((s) {
      // Re-cluster only once the glide finishes. Keeping markers stable during
      // the glide (instead of re-clustering every frame) is what makes zoom
      // feel smooth rather than janky.
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _currentZoom = _map.camera.zoom);
      }
    });
  LatLng _camStartCenter = _tashkent;
  LatLng _camEndCenter = _tashkent;
  double _camStartZoom = _cityZoom;
  double _camEndZoom = _cityZoom;

  /// Real shops (as featured listings) + a dense field of scattered points.
  late final List<MapListing> _listings = _buildListings();

  /// Nothing selected until the user taps a pin — the shop card only appears
  /// on tap (and dismisses when they tap empty map).
  String? _selectedId;

  /// Active category chip (All / Premium / Popular).
  _MapFilter _filter = _MapFilter.all;

  /// Max budget in so'm (null = no price cap). Set via the Price slider.
  int? _maxSom;

  /// Listings passing the category chip (before the price cap).
  List<MapListing> get _categoryListings {
    switch (_filter) {
      case _MapFilter.all:
        return _listings;
      case _MapFilter.premium:
        return _listings.where((l) => l.featured).toList();
      case _MapFilter.hot:
        return _listings.where((l) => l.hot).toList();
    }
  }

  /// Listings shown on the map: category chip ∩ price cap.
  List<MapListing> get _visibleListings {
    final cat = _categoryListings;
    final cap = _maxSom;
    if (cap == null) return cat;
    return cat.where((l) => Money.toSom(l.fromUsd) <= cap).toList();
  }

  /// Cheapest "from" price (so'm) in the current category — powers the
  /// "no shops that cheap, cheapest is X" feedback.
  int? get _cheapestSom {
    final cat = _categoryListings;
    if (cat.isEmpty) return null;
    return cat.map((l) => Money.toSom(l.fromUsd)).reduce(math.min);
  }

  List<MapListing> _buildListings() {
    final shops = MockData.barbershops;
    final real = <MapListing>[
      for (var i = 0; i < shops.length; i++)
        MapListing(
          id: 'real_$i',
          lat: shops[i].lat,
          lng: shops[i].lng,
          fromUsd: _fromUsd(shops[i], i),
          hot: shops[i].isPremium,
          featured: true,
          shopIndex: i,
        ),
    ];
    return [...real, ...MapListings.tashkent];
  }

  MapListing? get _selected {
    if (_selectedId == null) return null;
    for (final l in _listings) {
      if (l.id == _selectedId) return l;
    }
    return null;
  }

  /// Which real barbershop a listing opens.
  Barbershop _shopFor(MapListing l) =>
      MockData.barbershops[l.shopIndex % MockData.barbershops.length];

  /// A representative "haircut from" price (USD) — varied by tier so the
  /// price tags read like a real listings map.
  double _fromUsd(Barbershop shop, int index) {
    const base = {1: 22.0, 2: 30.0, 3: 40.0};
    return (base[shop.priceLevel] ?? 30) + (index % 3) * 4;
  }

  // ── Clustering ──────────────────────────────────────────────────────
  // Bucket points into a lat/lng grid whose cell size shrinks with zoom, so
  // far out they merge into counts and close in they separate into tags.
  double _cellSize(double zoom) => 78 / math.pow(2, zoom);

  List<_Cluster> _clusters(double zoom) {
    final cell = _cellSize(zoom);
    final buckets = <int, _ClusterAcc>{};
    for (final l in _visibleListings) {
      final cx = (l.lng / cell).floor();
      final cy = (l.lat / cell).floor();
      final key = cx * 1000003 + cy;
      (buckets[key] ??= _ClusterAcc()).add(l);
    }
    return [for (final a in buckets.values) a.build()];
  }

  void _open(Barbershop shop) {
    Navigator.of(context).push(
      FadeThroughPageRoute(child: BarbershopDetailScreen(shop: shop)),
    );
  }

  void _book(Barbershop shop) {
    Navigator.of(context).push(
      FadeThroughPageRoute(child: BookingFlowScreen(shop: shop)),
    );
  }

  void _select(String id) => setState(() => _selectedId = id);

  void _setFilter(_MapFilter f) => setState(() {
        _filter = f;
        _selectedId = null; // the previously-selected pin may now be hidden
      });

  void _setMaxSom(int? som) => setState(() {
        _maxSom = som;
        _selectedId = null;
      });

  Future<void> _openPriceSheet() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _PriceSheet(current: _maxSom, cheapestSom: _cheapestSom),
    );
    if (result == null) return; // dismissed without applying
    _setMaxSom(result == 0 ? null : result); // 0 = "any price" (clear)
  }

  /// Tapping a cluster dives the camera in to break it apart.
  void _expand(_Cluster c) {
    final z = (_currentZoom + 2.3).clamp(_minZoom, _maxZoom).toDouble();
    _animateCamera(c.center, z);
  }

  void _tickCamera() {
    final t = Curves.easeInOutCubic.transform(_camCtrl.value);
    final lat = _camStartCenter.latitude +
        (_camEndCenter.latitude - _camStartCenter.latitude) * t;
    final lng = _camStartCenter.longitude +
        (_camEndCenter.longitude - _camStartCenter.longitude) * t;
    final z = _camStartZoom + (_camEndZoom - _camStartZoom) * t;
    _map.move(LatLng(lat, lng), z);
  }

  void _animateCamera(LatLng center, double zoom) {
    _camStartCenter = _map.camera.center;
    _camStartZoom = _map.camera.zoom;
    _camEndCenter = center;
    _camEndZoom = zoom;
    // Scale the glide with how far we zoom — small steps stay snappy, big jumps
    // (recenter / cluster dive) get a longer, calmer glide.
    final dz = (zoom - _camStartZoom).abs();
    final ms = (460 + dz * 130).clamp(440, 880).toInt();
    _camCtrl.duration = Duration(milliseconds: ms);
    _camCtrl.forward(from: 0);
  }

  void _zoomBy(double delta) => _animateCamera(
        _map.camera.center,
        (_map.camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble(),
      );

  void _recenter() => _animateCamera(_you, _cityZoom);

  @override
  void initState() {
    super.initState();
    _locateUser();
  }

  /// Drop the "you are here" pin on the device's real GPS fix (it used to be
  /// stuck on a fixed city point), then recentre the map on it.
  Future<void> _locateUser() async {
    final pos = await createLocator().position();
    if (!mounted || pos == null) return;
    // Tashkent-only app: ignore a fix outside the city (stale/mock location)
    // so the map never drifts off to another region.
    if (!isInTashkent(pos.lat, pos.lng)) return;
    setState(() => _you = LatLng(pos.lat, pos.lng));
    try {
      _animateCamera(_you, _cityZoom);
    } catch (_) {}
  }

  @override
  void dispose() {
    _reclusterTimer?.cancel();
    _camCtrl.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);

    // Embedded (bottom-nav tab) → full-bleed map, chrome floats on top.
    if (widget.embedded) {
      final topPad = MediaQuery.of(context).padding.top + 10;
      return Scaffold(
        backgroundColor: p.bg,
        body: _mapLayers(context, p, topPad: topPad, bottomPad: 96),
      );
    }

    // Pushed (from the menu) → framed card with a header.
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  MiniPill(L.pricesInSom),
                ],
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${L.shopsWord} ',
                        style: AppTypography.h1(context),
                      ),
                      markerBoxSpan(L.onTheMap, AppTypography.h1(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: _mapLayers(context, p, topPad: 12, bottomPad: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapLayers(
    BuildContext context,
    PaperPalette p, {
    required double topPad,
    required double bottomPad,
  }) {
    final selected = _selected;
    return Stack(
      children: [
        Positioned.fill(child: _flutterMap(p, selected)),
        // Floating "N shops" count chip.
        Positioned(
          top: topPad,
          left: 0,
          right: 0,
          child: Center(
            child: FadeSlideIn(child: _CountChip(count: _visibleListings.length)),
          ),
        ),
        // Filter chips — narrow the pins by type. Right margin clears the
        // top-right zoom/locate controls so the last chip never tucks under.
        Positioned(
          top: topPad + 44,
          left: 0,
          right: 62,
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: _FilterBar(
              active: _filter,
              onSelect: _setFilter,
              maxSom: _maxSom,
              onTapPrice: _openPriceSheet,
            ),
          ),
        ),
        // Map attribution (required by OpenStreetMap / CARTO).
        Positioned(
          left: 10,
          top: topPad,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.6,
              child: Text(
                '© CARTO · OSM',
                style: GoogleFonts.nunito(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ),
          ),
        ),
        // Zoom + locate controls.
        Positioned(
          right: 12,
          top: topPad + 8,
          child: _MapControls(
            onZoomIn: () => _zoomBy(1),
            onZoomOut: () => _zoomBy(-1),
            onLocate: _recenter,
          ),
        ),
        // "Your budget is below every shop" banner — tells you the real
        // cheapest instead of just showing an empty map.
        if (_maxSom != null && _visibleListings.isEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPad,
            child: _NoResultsBanner(
              maxSom: _maxSom!,
              cheapestSom: _cheapestSom,
              onShowCheapest:
                  _cheapestSom == null ? null : () => _setMaxSom(_cheapestSom),
            ),
          ),
        // Bottom overlay: the chosen shop.
        Positioned(
          left: 10,
          right: 10,
          bottom: bottomPad,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1).animate(anim),
                child: child,
              ),
            ),
            child: selected == null
                ? const SizedBox.shrink(key: ValueKey('none'))
                : Builder(
                    key: ValueKey(selected.id),
                    builder: (_) {
                      final shop = _shopFor(selected);
                      return _ShopCard(
                        shop: shop,
                        index: MockData.barbershops.indexOf(shop),
                        fromLabel: L.fromPrice(Money.som(selected.fromUsd)),
                        onOpen: () => _open(shop),
                        onBook: () => _book(shop),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _flutterMap(PaperPalette p, MapListing? sel) {
    final pill = _currentZoom >= _pillZoom;
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _tashkent,
        initialZoom: _cityZoom,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        backgroundColor: p.bg,
        // Keep the map's state/tiles alive while it's an off-screen tab so
        // returning to it is instant (no re-init, no tile reload).
        keepAlive: true,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (_, __) => setState(() => _selectedId = null),
        onPositionChanged: (camera, hasGesture) {
          // During our own smooth glide, let markers ride along (we re-cluster
          // when it completes).
          if (_camCtrl.isAnimating) return;
          // Debounce: markers glide with the map during the pinch and only
          // re-cluster ~140ms after the last change — no mid-zoom rebuilds.
          _reclusterTimer?.cancel();
          _reclusterTimer = Timer(const Duration(milliseconds: 140), () {
            if (!mounted) return;
            if ((_map.camera.zoom - _currentZoom).abs() > 0.08) {
              setState(() => _currentZoom = _map.camera.zoom);
            }
          });
        },
      ),
      children: [
        TileLayer(
          // Fast CARTO CDN (EPSG:3857) with on-disk tile caching.
          urlTemplate: cartoTileUrl(dark: p.isDark),
          subdomains: cartoSubdomains,
          tileProvider: CachedTileProvider(),
          userAgentPackageName: 'com.barber.app',
          maxNativeZoom: 20,
          // Smaller buffers → fewer tiles to fetch on first paint.
          keepBuffer: 2,
          panBuffer: 1,
          tileDisplay: const TileDisplay.fadeIn(
            duration: Duration(milliseconds: 120),
          ),
        ),
        // Route from "you" to the chosen point.
        if (sel != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [_you, LatLng(sel.lat, sel.lng)],
                color: AppColors.accent.withValues(alpha: 0.8),
                strokeWidth: 3,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // The "you are here" dot.
            Marker(
              point: _you,
              width: 60,
              height: 60,
              alignment: Alignment.center,
              child: const RepaintBoundary(child: _YouMarker()),
            ),
            // Clustered shop points.
            for (final c in _clusters(_currentZoom)) _markerFor(c, pill),
          ],
        ),
      ],
    );
  }

  Marker _markerFor(_Cluster c, bool pill) {
    final single = c.single;
    final double w, h;
    final Alignment align;
    final Widget inner;
    if (single != null) {
      final color = _listingColor(single.id);
      if (pill) {
        w = 150;
        h = 76;
        align = Alignment.bottomCenter;
        inner = _PricePin(
          label: Money.compact(single.fromUsd),
          color: color,
          hot: single.hot,
          gold: single.featured,
          selected: _selectedId == single.id,
          onTap: () => _select(single.id),
        );
      } else {
        w = 46;
        h = 46;
        align = Alignment.center;
        inner = _Dot(
          color: color,
          hot: single.hot,
          featured: single.featured,
          selected: _selectedId == single.id,
          onTap: () => _select(single.id),
        );
      }
    } else if (pill) {
      // A genuine cluster of 2+ points.
      w = 178;
      h = 76;
      align = Alignment.bottomCenter;
      inner = _ClusterPill(
        count: c.count,
        fromLabel: Money.compact(c.minUsd),
        hot: c.hot,
        onTap: () => _expand(c),
      );
    } else {
      w = 66;
      h = 66;
      align = Alignment.center;
      inner = _ClusterDot(
        count: c.count,
        hot: c.hot,
        featured: c.featured,
        onTap: () => _expand(c),
      );
    }
    // RepaintBoundary lets each marker rasterise once and simply translate as
    // the map pans/zooms, instead of repainting every marker every frame —
    // the single biggest win for buttery-smooth movement with many markers.
    return Marker(
      point: c.center,
      width: w,
      height: h,
      alignment: align,
      child: RepaintBoundary(child: inner),
    );
  }
}

// ── Cluster model ──────────────────────────────────────────────────────
class _ClusterAcc {
  final List<MapListing> _items = [];
  double _sumLat = 0, _sumLng = 0, _minUsd = double.infinity;
  bool _hot = false, _featured = false;

  void add(MapListing l) {
    _items.add(l);
    _sumLat += l.lat;
    _sumLng += l.lng;
    if (l.fromUsd < _minUsd) _minUsd = l.fromUsd;
    _hot = _hot || l.hot;
    _featured = _featured || l.featured;
  }

  _Cluster build() => _Cluster(
        center: LatLng(_sumLat / _items.length, _sumLng / _items.length),
        count: _items.length,
        minUsd: _minUsd,
        hot: _hot,
        featured: _featured,
        single: _items.length == 1 ? _items.first : null,
      );
}

class _Cluster {
  const _Cluster({
    required this.center,
    required this.count,
    required this.minUsd,
    required this.hot,
    required this.featured,
    required this.single,
  });

  final LatLng center;
  final int count;
  final double minUsd;
  final bool hot;
  final bool featured;
  final MapListing? single;
}

const Color _pinNavy = Color(0xFF243049);
const Color _flame = Color(0xFFFF7A33);

/// Rainbow palette for individual price points — red, orange, green, teal,
/// blue, indigo, violet, pink. Each listing gets a stable colour from its id
/// so the map reads bright and varied (clusters stay navy so groups stand out).
const List<Color> _pinPalette = [
  Color(0xFFE5392F), // red
  Color(0xFFF4621F), // orange
  Color(0xFF1FA463), // green
  Color(0xFF0FB5AE), // teal
  Color(0xFF2E8BFF), // blue
  Color(0xFF4759E0), // indigo
  Color(0xFF7A3CF0), // violet
  Color(0xFFE83E8C), // pink
];

Color _listingColor(String id) {
  var h = 0;
  for (var i = 0; i < id.length; i++) {
    h = (h * 31 + id.codeUnitAt(i)) & 0x7fffffff;
  }
  return _pinPalette[h % _pinPalette.length];
}

List<BoxShadow> get _markerShadow => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];

/// A single point at low zoom: grey dot, flame if hot, gold scissors-coin if
/// sponsored. Scales up when selected.
class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.hot,
    required this.featured,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool hot;
  final bool featured;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget core;
    if (featured) {
      core = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.gold,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: _markerShadow,
        ),
        child: const Icon(Icons.content_cut_rounded,
            size: 15, color: _pinNavy),
      );
    } else if (hot) {
      core = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: _pinNavy,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: _markerShadow,
        ),
        child: const Icon(Icons.local_fire_department_rounded,
            size: 15, color: _flame),
      );
    } else {
      core = Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: _markerShadow,
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: selected ? 1.4 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: core,
      ),
    );
  }
}

/// A merged group at low zoom: a dark bubble sized by count, flame badge if
/// any member is hot.
class _ClusterDot extends StatelessWidget {
  const _ClusterDot({
    required this.count,
    required this.hot,
    required this.featured,
    required this.onTap,
  });

  final int count;
  final bool hot;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = (30 + math.min(count, 30) * 0.8).clamp(30.0, 56.0);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: featured ? AppColors.gold : _pinNavy,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: _markerShadow,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: GoogleFonts.nunito(
                    fontSize: size > 44 ? 16 : 13.5,
                    fontWeight: FontWeight.w900,
                    color: featured ? _pinNavy : Colors.white,
                  ),
                ),
              ),
              if (hot)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: _flame,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department_rounded,
                        size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A merged group at high zoom: "N · from <price>" tag with a leading count
/// chip and a downward tail.
class _ClusterPill extends StatelessWidget {
  const _ClusterPill({
    required this.count,
    required this.fromLabel,
    required this.hot,
    required this.onTap,
  });

  final int count;
  final String fromLabel;
  final bool hot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            decoration: BoxDecoration(
              color: _pinNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: _markerShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: _pinNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                if (hot) ...[
                  const Icon(Icons.local_fire_department_rounded,
                      size: 14, color: _flame),
                  const SizedBox(width: 3),
                ],
                Text(
                  'from $fromLabel',
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(size: const Size(13, 7), painter: _TailPainter(_pinNavy)),
        ],
      ),
    );
  }
}

/// A Yandex-style price tag: a rounded pill with a downward tail. Selected
/// pills fill electric blue; sponsored shops get a gold edge; hot spots flame.
class _PricePin extends StatelessWidget {
  const _PricePin({
    required this.label,
    required this.color,
    required this.hot,
    required this.gold,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool hot;
  final bool gold;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = color;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: selected ? 1.0 : 0.96,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.6)
                      : (gold
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.08)),
                  width: (selected || gold) ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (selected ? color : Colors.black)
                        .withValues(alpha: selected ? 0.55 : 0.35),
                    blurRadius: selected ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hot) ...[
                    Icon(Icons.local_fire_department_rounded,
                        size: 13, color: selected ? Colors.white : _flame),
                    const SizedBox(width: 3),
                  ] else if (gold) ...[
                    const Icon(Icons.content_cut_rounded,
                        size: 12, color: AppColors.gold),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CustomPaint(size: const Size(13, 7), painter: _TailPainter(bg)),
        ],
      ),
    );
  }
}

/// Downward triangle tail for the price tag.
class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

/// Floating "N shops nearby" chip over the map.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: p.isDark
            ? const Color(0xFF111B2C).withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded,
              size: 15, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            L.shopsNearby(count),
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: p.text,
            ),
          ),
        ],
      ),
    );
  }
}

String _filterLabel(_MapFilter f) => switch (f) {
      _MapFilter.all => L.mapFilterAll,
      _MapFilter.premium => L.mapFilterPremium,
      _MapFilter.hot => L.mapFilterHot,
    };

/// Horizontal filter chips floating over the map: category chips + a live
/// price-budget chip that shows the current cap.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.active,
    required this.onSelect,
    required this.maxSom,
    required this.onTapPrice,
  });

  final _MapFilter active;
  final ValueChanged<_MapFilter> onSelect;
  final int? maxSom;
  final VoidCallback onTapPrice;

  @override
  Widget build(BuildContext context) {
    const items = <(_MapFilter, IconData)>[
      (_MapFilter.all, Icons.grid_view_rounded),
      (_MapFilter.premium, Icons.workspace_premium_rounded),
      (_MapFilter.hot, Icons.local_fire_department_rounded),
    ];
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (f, icon) in items) ...[
              _FilterChip(
                label: _filterLabel(f),
                icon: icon,
                selected: f == active,
                onTap: () => onSelect(f),
              ),
              const SizedBox(width: 8),
            ],
            _FilterChip(
              label: maxSom != null
                  ? "≤ ${Money.group(maxSom!)} so'm"
                  : L.mapFilterPrice,
              icon: Icons.savings_rounded,
              selected: maxSom != null,
              onTap: onTapPrice,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to type a max budget in so'm. Shows the current cheapest as a
/// hint, so a too-low budget is obvious.
class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.current, required this.cheapestSom});

  final int? current;
  final int? cheapestSom;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  late final TextEditingController _c = TextEditingController(
    text: widget.current != null ? Money.group(widget.current!) : '',
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  int? _parse() {
    final digits = _c.text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(L.setBudgetTitle, style: AppTypography.h2(context)),
            const SizedBox(height: 4),
            if (widget.cheapestSom != null)
              Text(
                L.cheapestRightNow(Money.group(widget.cheapestSom!)),
                style: AppTypography.bodySmall(context),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _c,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              style: GoogleFonts.nunito(
                  fontSize: 22, fontWeight: FontWeight.w900, color: p.text),
              decoration: InputDecoration(
                hintText: '120 000',
                suffixText: "so'm",
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: L.anyPrice,
                    height: 52,
                    style: PrimaryButtonStyle.ghost,
                    onPressed: () => Navigator.pop(context, 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: L.applyWord,
                    height: 52,
                    onPressed: () => Navigator.pop(context, _parse() ?? 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the budget is below every shop — names the real cheapest and
/// offers to snap the budget to it.
class _NoResultsBanner extends StatelessWidget {
  const _NoResultsBanner({
    required this.maxSom,
    required this.cheapestSom,
    required this.onShowCheapest,
  });

  final int maxSom;
  final int? cheapestSom;
  final VoidCallback? onShowCheapest;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  L.mapNoShopsUnder(Money.group(maxSom)),
                  style: AppTypography.h4(context),
                ),
              ),
            ],
          ),
          if (cheapestSom != null) ...[
            const SizedBox(height: 4),
            Text(
              L.mapCheapestIs(Money.group(cheapestSom!)),
              style: AppTypography.bodySmall(context),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: L.showCheapest,
              height: 46,
              onPressed: onShowCheapest,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final idle = p.isDark
        ? const Color(0xFF111B2C).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : idle,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.accent : p.border),
          boxShadow: [
            BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : p.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : p.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Right-side map controls: zoom in / out (grouped) + recenter.
class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocate,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    BoxDecoration deco() => BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: deco(),
          child: Column(
            children: [
              _CtrlBtn(icon: Icons.add_rounded, onTap: onZoomIn),
              Container(width: 26, height: 1, color: p.border),
              _CtrlBtn(icon: Icons.remove_rounded, onTap: onZoomOut),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: deco(),
          child: _CtrlBtn(
            icon: Icons.my_location_rounded,
            color: AppColors.accent,
            onTap: onLocate,
          ),
        ),
      ],
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: color ?? p.text),
        ),
      ),
    );
  }
}

/// Pulsing "you are here" dot.
class _YouMarker extends StatefulWidget {
  const _YouMarker();

  @override
  State<_YouMarker> createState() => _YouMarkerState();
}

class _YouMarkerState extends State<_YouMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // Isolated so the perpetual pulse doesn't repaint the whole marker layer.
    return RepaintBoundary(
      child: AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final t = _pulse.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 18 + 34 * t,
              height: 18 + 34 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent
                      .withValues(alpha: (1 - t).clamp(0.0, 1.0)),
                  width: 3,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: p.bg, width: 3),
              ),
            ),
          ],
        );
      },
      ),
    );
  }
}

/// The chooser card that slides up over the map.
class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.index,
    required this.fromLabel,
    required this.onOpen,
    required this.onBook,
  });

  final Barbershop shop;
  final int index;
  final String fromLabel;
  final VoidCallback onOpen;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return PaperCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              InitialAvatar(
                name: shop.name,
                size: 46,
                index: index,
                square: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.name, style: AppTypography.h4(context)),
                    const SizedBox(height: 2),
                    Text(
                      '${shop.address} · ${shop.distanceLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MiniPill('★ ${shop.rating.toStringAsFixed(1)}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.payments_rounded, size: 16, color: AppColors.green),
              const SizedBox(width: 6),
              Text(
                fromLabel,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: L.openShop,
                  height: 46,
                  style: PrimaryButtonStyle.ghost,
                  onPressed: onOpen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: L.bookHere,
                  height: 46,
                  onPressed: onBook,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
