import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/barbershop_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/paper_kit.dart';
import '../barbershop_detail/barbershop_detail_screen.dart';
import '../map/shops_map_screen.dart';

enum _ExploreFilter { all, featured, nearby, topRated, saved }

/// Explore — every shop in town as a clean list, searchable and filterable.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  _ExploreFilter _filter = _ExploreFilter.all;

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
              s.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final shops = _shops;
        final favs = AppState.instance.favouriteShopIds;
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
                      Text('Every shop in town',
                          style: AppTypography.h2(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Search pill with the map shortcut riding as its trailing chip.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 50),
                  child: _SearchField(
                    controller: _search,
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
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
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
                            onTap: () => setState(() => _filter = f),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (shops.isEmpty)
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

/// The Yandex-style search pill — search glyph, live text field, and a tinted
/// map chip on the right (same silhouette as the home search bar).
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onMapTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22, color: p.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
              cursorColor: p.text,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: L.searchShopsHint,
                hintStyle: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: p.textTertiary,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close_rounded,
                    size: 18, color: p.textTertiary),
              ),
            ),
          const SizedBox(width: 4),
          Material(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onMapTap,
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
