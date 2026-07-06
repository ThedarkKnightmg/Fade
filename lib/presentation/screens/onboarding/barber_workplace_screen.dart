import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/map/fast_tiles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'create_barbershop_screen.dart';

/// Choose the barbershop you'll work at from the map — or create a new one.
/// Picking a shop attaches you to it and flips into barber mode.
class BarberWorkplaceScreen extends StatefulWidget {
  const BarberWorkplaceScreen({super.key});

  @override
  State<BarberWorkplaceScreen> createState() => _BarberWorkplaceScreenState();
}

class _BarberWorkplaceScreenState extends State<BarberWorkplaceScreen> {
  final MapController _map = MapController();
  Barbershop? _selected;

  static const LatLng _center = LatLng(41.3111, 69.2797);

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _pick(Barbershop shop) {
    HapticFeedback.selectionClick();
    setState(() => _selected = shop);
    _map.move(LatLng(shop.lat, shop.lng), 15.5);
  }

  void _workHere() {
    final shop = _selected;
    if (shop == null) return;
    HapticFeedback.mediumImpact();
    AppState.instance
      ..workAtExistingShop(shop.id)
      ..markBarberOnboarded();
    // Role flipped → RootShell swaps to the barber side.
  }

  void _createNew() {
    Navigator.of(context).push(
      FadeThroughPageRoute(
        child: CreateBarbershopScreen(
          initial: _map.camera.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final shops = MockData.barbershops;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
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
                        Text(L.wpTitle, style: AppTypography.h2(context)),
                        Text(L.wpSub,
                            maxLines: 2,
                            style: AppTypography.bodySmall(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Map with a marker per shop ──
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: p.border),
                  ),
                  child: FlutterMap(
                    mapController: _map,
                    options: const MapOptions(
                      initialCenter: _center,
                      initialZoom: 12.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: cartoTileUrl(dark: p.isDark),
                        subdomains: const ['a', 'b', 'c', 'd'],
                        tileProvider: CachedTileProvider(),
                        userAgentPackageName: 'com.barber.app',
                      ),
                      MarkerLayer(
                        markers: [
                          for (final shop in shops)
                            Marker(
                              point: LatLng(shop.lat, shop.lng),
                              width: 44,
                              height: 44,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () => _pick(shop),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  size: _selected?.id == shop.id ? 44 : 34,
                                  color: _selected?.id == shop.id
                                      ? AppColors.accent
                                      : AppColors.accentDeep
                                          .withValues(alpha: 0.75),
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
            // ── Selected shop card → Work here ──
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: _selected == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: clayDecoration(p, radius: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                  Icons.store_mall_directory_rounded,
                                  color: AppColors.accent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selected!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.h4(context)),
                                  Text(_selected!.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTypography.bodySmall(context)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _workHere,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(L.wpWorkHere,
                                    style: GoogleFonts.nunito(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            // ── Create a new shop ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: PrimaryButton(
                label: L.wpCreateNew,
                icon: Icons.add_location_alt_rounded,
                height: 54,
                style: PrimaryButtonStyle.ghost,
                onPressed: _createNew,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
