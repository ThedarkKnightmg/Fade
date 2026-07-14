import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/barber.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/barber_feed_kit.dart';
import '../../widgets/barbershop_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/paper_kit.dart';
import '../barbershop_detail/barbershop_detail_screen.dart';
import '../map/shops_map_screen.dart';

enum _ExploreFilter { all, featured, nearby, topRated, saved }

enum _BarberFilter { all, boosted, vip, topRated }

/// Explore — every shop AND every stylist in town: searchable, filterable,
/// and switchable between the two views (same Shops | Barbers switch as Home).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  _ExploreFilter _filter = _ExploreFilter.all;
  _BarberFilter _bFilter = _BarberFilter.all;
  bool _barbersMode = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Barbershop> get _shops {
    final favs = AppState.instance.favouriteShopIds;
    var list = switch (_filter) {
      _ExploreFilter.all => [...MockData.barbershops],
      _ExploreFilter.featured =>
        MockData.barbershops.where((s) => s.isFeatured).toList(),
      _ExploreFilter.nearby =>
        MockData.barbershops.where((s) => s.distanceKm <= 2).toList(),
      _ExploreFilter.topRated =>
        ([...MockData.barbershops]..sort((a, b) => b.rating.compareTo(a.rating)))
            .take(3)
            .toList(),
      _ExploreFilter.saved =>
        MockData.barbershops.where((s) => favs.contains(s.id)).toList(),
    };
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.tagline.toLowerCase().contains(q) ||
              L.tr(s.tagline).toLowerCase().contains(q) ||
              s.tags.any((t) =>
                  t.toLowerCase().contains(q) ||
                  L.tr(t).toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }

  /// Every stylist in town, filtered (spotlight status / top-rated) and
  /// searchable by name, specialty or shop. Ranking stays per-barber:
  /// boosted → VIP → standard, rating breaking ties.
  List<(Barbershop, Barber)> get _barbers {
    final st = AppState.instance;
    var pairs = <(Barbershop, Barber)>[
      for (final s in MockData.barbershops)
        for (final b in s.barbers) (s, b),
    ];
    pairs = switch (_bFilter) {
      _BarberFilter.all || _BarberFilter.topRated => pairs,
      _BarberFilter.boosted =>
        pairs.where((e) => st.barberIsBoosted(e.$2.id)).toList(),
      _BarberFilter.vip =>
        pairs.where((e) => st.barberIsVip(e.$2.id)).toList(),
    };
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      pairs = pairs
          .where((e) =>
              e.$2.name.toLowerCase().contains(q) ||
              e.$2.specialty.toLowerCase().contains(q) ||
              L.tr(e.$2.specialty).toLowerCase().contains(q) ||
              e.$1.name.toLowerCase().contains(q))
          .toList();
    }
    if (_bFilter == _BarberFilter.topRated) {
      pairs.sort((a, b) =>
          st.barberTalentRating(b.$2).compareTo(st.barberTalentRating(a.$2)));
    } else {
      pairs.sort((a, b) {
        final t = st
            .barberSpotlightTier(a.$2.id)
            .compareTo(st.barberSpotlightTier(b.$2.id));
        if (t != 0) return t;
        return b.$2.rating.compareTo(a.$2.rating);
      });
    }
    return pairs;
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final shops = _shops;
        final barbers = _barbers;
        final favs = AppState.instance.favouriteShopIds;
        final empty = _barbersMode ? barbers.isEmpty : shops.isEmpty;
        return Scaffold(
          backgroundColor: p.bg,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
              children: [
                // Standard header — back circle + screen title.
                FadeSlideIn(
                  child: Row(
                    children: [
                      CircleBtn(
                        icon: Icons.arrow_back_rounded,
                        size: 42,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Text(L.pfEveryShop,
                          style: AppTypography.h2(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Search pill — focus-aware, with the map shortcut riding
                // as its trailing chip.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 50),
                  child: _SearchField(
                    controller: _search,
                    hint: _barbersMode
                        ? L.searchBarbersHint
                        : L.searchShopsHint,
                    onChanged: (_) => setState(() {}),
                    onClear: () {
                      _search.clear();
                      setState(() {});
                    },
                    onMapTap: () => Navigator.of(context).push(
                      FadeThroughPageRoute(child: const ShopsMapScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Shops ⇄ Barbers — same switch as Home, so stylists are
                // findable everywhere.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: FeedModeSwitch(
                    barbersMode: _barbersMode,
                    onChanged: (v) => setState(() => _barbersMode = v),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 110),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: _barbersMode
                        ? Row(
                            children: [
                              for (final (f, label) in [
                                (_BarberFilter.all, L.filterAll),
                                (_BarberFilter.boosted,
                                    '⚡ ${L.boostedPill}'),
                                (_BarberFilter.vip, 'VIP'),
                                (_BarberFilter.topRated, L.filterTopRated),
                              ]) ...[
                                CountChip(
                                  label: label,
                                  selected: _bFilter == f,
                                  onTap: () =>
                                      setState(() => _bFilter = f),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          )
                        : Row(
                            children: [
                              for (final (f, label) in [
                                (_ExploreFilter.all, L.filterAll),
                                (_ExploreFilter.featured, L.filterFeatured),
                                (_ExploreFilter.nearby, L.filterNearby),
                                (_ExploreFilter.topRated, L.filterTopRated),
                                (_ExploreFilter.saved, L.filterSaved),
                              ]) ...[
                                CountChip(
                                  label: label,
                                  selected: _filter == f,
                                  onTap: () =>
                                      setState(() => _filter = f),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (empty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.search_off_rounded,
                                size: 22, color: AppColors.accent),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            L.nothingMatches,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(context)
                                .copyWith(color: p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_barbersMode)
                  for (var i = 0; i < barbers.length; i++) ...[
                    FadeSlideIn(
                      delay: Duration(milliseconds: 180 + i * 45),
                      child: SpotlightBarberCard(
                        shop: barbers[i].$1,
                        barber: barbers[i].$2,
                        index: i,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ]
                else
                  for (var i = 0; i < shops.length; i++) ...[
                    FadeSlideIn(
                      delay: Duration(milliseconds: 180 + i * 60),
                      child: BarbershopCard(
                        shop: shops[i],
                        index: MockData.barbershops.indexOf(shops[i]),
                        isFavourite: favs.contains(shops[i].id),
                        onTap: () => Navigator.of(context).push(
                          FadeThroughPageRoute(
                            child: BarbershopDetailScreen(shop: shops[i]),
                          ),
                        ),
                        onFavourite: () =>
                            AppState.instance.toggleFavourite(shops[i].id),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The search pill, redesigned: the glyph sits in a tinted accent tile, the
/// whole pill lights up with an accent border + glow while focused, the clear
/// button pops in only when there's text, and the map shortcut rides on the
/// right — one clean control instead of a flat grey box.
class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    required this.onMapTap,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onMapTap;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final focused = _focus.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 58,
      padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: focused ? AppColors.accent : p.border,
          width: focused ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: focused
                ? AppColors.accent.withValues(alpha: 0.18)
                : p.shadow,
            blurRadius: focused ? 20 : 16,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  AppColors.accent.withValues(alpha: focused ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search_rounded,
                size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: p.textTertiary,
                ),
              ),
            ),
          ),
          // Clear pops in only when there's something to clear.
          AnimatedScale(
            scale: hasText ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: GestureDetector(
              onTap: widget.onClear,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: p.textTertiary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded,
                    size: 15, color: p.textSecondary),
              ),
            ),
          ),
          Material(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.onMapTap,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.map_rounded,
                    size: 19, color: AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
