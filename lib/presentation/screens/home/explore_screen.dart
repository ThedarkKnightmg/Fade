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
                // Header = back button INLINE with the search bar. The old
                // two-line "Shahardagi barcha barbershoplar" title row is gone —
                // the search hint + the Shops/Barbers toggle already say what
                // this screen is, so the title was just another stacked bar.
                FadeSlideIn(
                  child: Row(
                    children: [
                      CircleBtn(
                        icon: Icons.arrow_back_rounded,
                        size: 44,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
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
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                              for (final (f, label, _) in [
                                (_BarberFilter.all, L.filterAll, null),
                                (_BarberFilter.boosted, L.boostedPill,
                                    Icons.bolt_rounded),
                                (_BarberFilter.vip, 'VIP',
                                    Icons.workspace_premium_rounded),
                                (_BarberFilter.topRated, L.filterTopRated,
                                    Icons.star_rounded),
                              ]) ...[
                                FilterTab(
                                  label: label,
                                  selected: _bFilter == f,
                                  onTap: () =>
                                      setState(() => _bFilter = f),
                                ),
                                const SizedBox(width: 22),
                              ],
                            ],
                          )
                        : Row(
                            children: [
                              for (final (f, label, _) in [
                                (_ExploreFilter.all, L.filterAll, null),
                                (_ExploreFilter.featured, L.filterFeatured,
                                    Icons.star_rounded),
                                (_ExploreFilter.nearby, L.filterNearby,
                                    Icons.near_me_rounded),
                                (_ExploreFilter.topRated, L.filterTopRated,
                                    Icons.trending_up_rounded),
                                (_ExploreFilter.saved, L.filterSaved,
                                    Icons.favorite_rounded),
                              ]) ...[
                                FilterTab(
                                  label: label,
                                  selected: _filter == f,
                                  onTap: () =>
                                      setState(() => _filter = f),
                                ),
                                const SizedBox(width: 22),
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
      height: 56,
      padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
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
          // Plain leading glyph — brightens to accent on focus. No heavy tile,
          // so the pill reads as one field instead of a boxed-in segment.
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(
              Icons.search_rounded,
              size: 21,
              color: focused ? AppColors.accent : p.textTertiary,
            ),
          ),
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
                // The app-wide InputDecorationTheme fills its fields, and
                // `border: none` only drops the OUTLINE — the fill stayed and
                // painted a second rounded box inside this one. Kill it here so
                // the bar reads as a single field.
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hint,
                hintMaxLines: 1,
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
          // Map shortcut as a quiet accent action. The divider that used to sit
          // in front of it is gone — it chopped the bar into segments and ate
          // width the hint needed (it was rendering as "Search sh…").
          GestureDetector(
            onTap: widget.onMapTap,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 38,
              height: 40,
              child: Icon(Icons.map_rounded, size: 20, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
