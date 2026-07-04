import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/location/geo_position.dart';
import '../../../core/location/location_service.dart';
import '../../../core/map/fast_tiles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// Re-pin the barber's shop on the map. The map pans under a fixed centre pin;
/// "Use this location" saves the centre coordinate (+ a geocoded address).
class ShopLocationPickerScreen extends StatefulWidget {
  const ShopLocationPickerScreen({super.key, required this.initial});
  final LatLng initial;

  @override
  State<ShopLocationPickerScreen> createState() =>
      _ShopLocationPickerScreenState();
}

class _ShopLocationPickerScreenState extends State<ShopLocationPickerScreen> {
  final MapController _map = MapController();
  bool _busy = false;
  bool _locating = false;
  static const double _zoom = 15.5;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    final pos = await createLocator().position();
    if (!mounted) return;
    setState(() => _locating = false);
    // Never fail silently — say why the map didn't move.
    if (pos == null) {
      _snack(L.locationFailed);
      return;
    }
    // Tashkent-only app — a fix outside the city can't be used.
    if (!isInTashkent(pos.lat, pos.lng)) {
      _snack(L.outsideCity);
      return;
    }
    _map.move(LatLng(pos.lat, pos.lng), _zoom);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final c = _map.camera.center;
    final addr = await reverseGeocode(c.latitude, c.longitude);
    if (!mounted) return;
    AppState.instance
        .setShopLocation(lat: c.latitude, lng: c.longitude, address: addr);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(L.locationSaved),
        behavior: SnackBarBehavior.floating,
      ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: widget.initial,
                initialZoom: _zoom,
                minZoom: 5,
                maxZoom: 18,
                backgroundColor: p.bg,
                interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                TileLayer(
                  urlTemplate: cartoTileUrl(dark: p.isDark),
                  subdomains: cartoSubdomains,
                  tileProvider: CachedTileProvider(),
                  userAgentPackageName: 'com.barber.app',
                  maxNativeZoom: 20,
                  keepBuffer: 2,
                  panBuffer: 1,
                ),
              ],
            ),
          ),
          // Fixed centre pin (tip points at the map centre).
          const Center(
            child: IgnorePointer(child: _CentrePin()),
          ),
          // Header.
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border),
                    ),
                    child: Text(L.shopLocationTitle,
                        style: AppTypography.h4(context)),
                  ),
                ],
              ),
            ),
          ),
          // Bottom controls.
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "Use my location" chip.
                    GestureDetector(
                      onTap: _locating ? null : _locateMe,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.border),
                          boxShadow: [
                            BoxShadow(
                                color: p.shadow,
                                blurRadius: 14,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_locating)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.accent),
                              )
                            else
                              const Icon(Icons.my_location_rounded,
                                  size: 18, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text(L.useMyLocation,
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.border),
                        boxShadow: [
                          BoxShadow(
                              color: p.shadow,
                              blurRadius: 18,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 15, color: AppColors.accent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(L.dragToPlaceShop,
                                      style:
                                          AppTypography.bodySmall(context)),
                                ),
                              ],
                            ),
                          ),
                          PrimaryButton(
                            label: _busy ? L.saving : L.useThisLocation,
                            icon: Icons.check_rounded,
                            height: 54,
                            onPressed: _busy ? null : _save,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CentrePin extends StatelessWidget {
  const _CentrePin();

  @override
  Widget build(BuildContext context) {
    // Lift the pin so its tip sits on the exact centre.
    return Transform.translate(
      offset: const Offset(0, -22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded,
              size: 46, color: AppColors.accent),
          // Shadow dot at the tip.
          Container(
            width: 8,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
