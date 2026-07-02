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

/// Explore — every shop as a full note card, searchable.
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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 150),
            children: [
              FadeSlideIn(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Every ',
                        style: AppTypography.h1(context),
                      ),
                      markerBoxSpan('shop', AppTypography.h1(context)),
                      TextSpan(
                        text: ' in town',
                        style: AppTypography.h1(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeSlideIn(
                delay: const Duration(milliseconds: 50),
                child: Text(
                  'find the one that gets your hair',
                  style: AppTypography.scribble(context, size: 21)
                      .copyWith(color: p.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              // Search pill + map shortcut.
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                        ),
                        cursorColor: p.text,
                        decoration: InputDecoration(
                          hintText: L.searchShopsHint,
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 20, color: p.textTertiary),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      size: 18, color: p.textTertiary),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleBtn(
                      icon: Icons.map_rounded,
                      size: 54,
                      onTap: () => Navigator.of(context).push(
                        FadeThroughPageRoute(
                            child: const ShopsMapScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
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
                    child: ScribbleNote(L.nothingMatches),
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
