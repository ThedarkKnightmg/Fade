import '../../../core/map/map_attribution.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/map/fast_tiles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// What the search screen returns: either an existing shop the barber picked,
/// or a request to create a brand-new one (the Leader Loop) — carrying the text
/// they typed so it can pre-fill the new shop's name.
class ShopAttachResult {
  const ShopAttachResult.existing(this.shop) : createName = null;
  const ShopAttachResult.createNew(this.createName) : shop = null;

  final Barbershop? shop;
  final String? createName;

  bool get isCreateNew => shop == null;
}

/// "Where do you cut hair?" — the barber searches for their workplace. If it's
/// already on the map they attach to it; if not, the "Add it in 60 seconds"
/// card kicks off the Leader Loop. Returns a [ShopAttachResult].
class BarberShopAttachScreen extends StatefulWidget {
  const BarberShopAttachScreen({super.key, this.selectedId});
  final String? selectedId;

  @override
  State<BarberShopAttachScreen> createState() => _BarberShopAttachScreenState();
}

class _BarberShopAttachScreenState extends State<BarberShopAttachScreen> {
  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();
  late final List<Barbershop> _all = MockData.barbershops;
  String _query = '';
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _search.addListener(() {
      if (_search.text != _query) setState(() => _query = _search.text);
    });
  }

  @override
  void dispose() {
    _map.dispose();
    _search.dispose();
    super.dispose();
  }

  List<Barbershop> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.address.toLowerCase().contains(q) ||
            s.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  Barbershop? get _selected {
    if (_selectedId == null) return null;
    for (final s in _all) {
      if (s.id == _selectedId) return s;
    }
    return null;
  }

  void _select(Barbershop shop) {
    HapticFeedback.selectionClick();
    setState(() => _selectedId = shop.id);
    try {
      _map.move(LatLng(shop.lat, shop.lng), 14.5);
    } catch (_) {}
  }

  void _createNew() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(ShopAttachResult.createNew(_search.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final list = _filtered;
    final noMatches = list.isEmpty;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 20, 0),
              child: Row(
                children: [
                  CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(L.whereDoYouCut, style: AppTypography.h2(context)),
                        Text(L.pickShopOnMap,
                            style: AppTypography.bodySmall(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Search field — the "search trigger".
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _search,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: p.text),
                cursorColor: AppColors.accent,
                decoration: InputDecoration(
                  hintText: L.searchYourShopHint,
                  hintStyle: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600, color: p.textTertiary),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: p.textTertiary),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: p.textTertiary),
                          onPressed: () => _search.clear(),
                        ),
                  filled: true,
                  fillColor: p.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: p.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: p.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!noMatches) ...[
              // Map of the matching shops.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 170,
                    child: FlutterMap(
                      mapController: _map,
                      options: const MapOptions(
                        initialCenter: LatLng(41.3175, 69.2800),
                        initialZoom: 11.5,
                        interactionOptions: InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: cartoTileUrl(dark: p.isDark),
                          subdomains: cartoSubdomains,
                          tileProvider: CachedTileProvider(),
                          userAgentPackageName: 'com.barber.app',
                          keepBuffer: 2,
                          panBuffer: 1,
                        ),
                        const MapAttribution(),
                        MarkerLayer(
                          markers: [
                            for (final s in list)
                              Marker(
                                point: LatLng(s.lat, s.lng),
                                width: 44,
                                height: 44,
                                alignment: Alignment.topCenter,
                                child: GestureDetector(
                                  onTap: () => _select(s),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: _selectedId == s.id ? 42 : 32,
                                    color: _selectedId == s.id
                                        ? AppColors.accent
                                        : AppColors.accentDeep
                                            .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // The list, or the "add your shop" empty-state.
            Expanded(
              child: noMatches
                  ? _AddYourShopEmpty(query: _query.trim(), onTap: _createNew)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      itemCount: list.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == list.length) {
                          return _CantFindFooter(onTap: _createNew);
                        }
                        final s = list[i];
                        final sel = _selectedId == s.id;
                        return _ShopRow(
                            shop: s, selected: sel, onTap: () => _select(s));
                      },
                    ),
            ),
            // Confirm (attach to the selected existing shop).
            if (!noMatches)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 4, 20, 12 + MediaQuery.of(context).padding.bottom),
                child: PrimaryButton(
                  label: _selected == null
                      ? L.selectShopTitle
                      : '${L.iWorkHere} · ${_selected!.name}',
                  icon: Icons.check_rounded,
                  height: 56,
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.of(context)
                          .pop(ShopAttachResult.existing(_selected)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A selectable shop row on the attach list.
class _ShopRow extends StatelessWidget {
  const _ShopRow(
      {required this.shop, required this.selected, required this.onTap});
  final Barbershop shop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.10) : p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.accent : p.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h4(context)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.place_rounded, size: 12, color: p.textTertiary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(shop.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

/// Footer under the shop list: a quiet "Can't find your shop?" → Leader Loop.
class _CantFindFooter extends StatelessWidget {
  const _CantFindFooter({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_location_alt_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.notListedShop,
                      style: GoogleFonts.nunito(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accentDeep)),
                  Text(L.addShopIn60, style: AppTypography.caption(context)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

/// The search-miss empty-state — a big, inviting "Add your shop in 60 seconds"
/// hero. This is the reward-framed doorway into the Leader Loop.
class _AddYourShopEmpty extends StatelessWidget {
  const _AddYourShopEmpty({required this.query, required this.onTap});
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.add_business_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              query.isEmpty ? L.notListedShop : '"$query"',
              textAlign: TextAlign.center,
              style: AppTypography.h2(context),
            ),
            const SizedBox(height: 6),
            Text(L.beFirstHere,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(context)),
            const SizedBox(height: 20),
            PrimaryButton(
              label: L.addShopIn60,
              icon: Icons.bolt_rounded,
              style: PrimaryButtonStyle.lime,
              onPressed: onTap,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: p.textTertiary),
                const SizedBox(width: 4),
                Text(L.sixtySeconds, style: AppTypography.caption(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
