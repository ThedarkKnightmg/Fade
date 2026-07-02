import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/location/geo_position.dart';
import '../../../core/location/location_service.dart';
import '../../../core/map/fast_tiles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// Pick your location two ways: type an address, or pan a real map of the
/// whole of Uzbekistan and drop the pin on your spot. The spot under the
/// centre pin is reverse-geocoded into a "City, area" label.
class AddressPickerScreen extends StatefulWidget {
  const AddressPickerScreen({super.key});

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  // Open over Tashkent so the picker starts on the city, not the whole country.
  static const LatLng _tashkent = LatLng(41.3175, 69.2800);
  static const double _cityZoom = 12.5;
  static const double _minZoom = 4;
  static const double _maxZoom = 18;

  final MapController _map = MapController();
  late final TextEditingController _field =
      TextEditingController(text: AppState.instance.address ?? '');

  bool _busy = false;
  bool _locating = false;

  @override
  void dispose() {
    _field.dispose();
    _map.dispose();
    super.dispose();
  }

  void _zoom(double delta) {
    final z = (_map.camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    _map.move(_map.camera.center, z);
  }

  /// Apply the address the user typed by hand.
  void _useTyped() {
    final t = _field.text.trim();
    if (t.isEmpty) return;
    FocusScope.of(context).unfocus();
    AppState.instance.setAddress(t);
    Navigator.of(context).pop();
  }

  /// Reverse-geocode the spot under the centre pin and save it.
  Future<void> _useMapCentre() async {
    setState(() => _busy = true);
    final c = _map.camera.center;
    final label = await reverseGeocode(c.latitude, c.longitude) ??
        '${c.latitude.toStringAsFixed(3)}, ${c.longitude.toStringAsFixed(3)}';
    if (!mounted) return;
    AppState.instance.setAddress(label);
    Navigator.of(context).pop();
  }

  /// Jump the map to the device's GPS fix.
  Future<void> _locateMe() async {
    setState(() => _locating = true);
    final pos = await createLocator().position();
    if (!mounted) return;
    setState(() => _locating = false);
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L.locationPinFailed),
        ),
      );
      return;
    }
    // Tashkent-only: a fix outside the city just recentres on Tashkent.
    if (!isInTashkent(pos.lat, pos.lng)) {
      _map.move(_tashkent, _cityZoom);
      return;
    }
    _map.move(LatLng(pos.lat, pos.lng), 14.5);
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      L.setYourLocation,
                      style: AppTypography.h3(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Type it manually ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AddressField(
                controller: _field,
                onSubmit: _useTyped,
              ),
            ),
            const SizedBox(height: 12),
            // ── …or pin it on the map ───────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _flutterMap(p)),
                  // Fixed centre pin — the map slides underneath it.
                  const Center(
                    child: IgnorePointer(child: _CentrePin()),
                  ),
                  // Attribution (required by OSM / CARTO).
                  Positioned(
                    left: 12,
                    top: 10,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.6,
                        child: Text(
                          '© OSM · CARTO',
                          style: GoogleFonts.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Hint chip.
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FadeSlideIn(
                        child: _HintChip(L.dragToPin),
                      ),
                    ),
                  ),
                  // Zoom + locate controls.
                  Positioned(
                    right: 12,
                    top: 52,
                    child: _MapButtons(
                      onZoomIn: () => _zoom(1),
                      onZoomOut: () => _zoom(-1),
                      onLocate: _locateMe,
                      locating: _locating,
                    ),
                  ),
                ],
              ),
            ),
            // ── Confirm bar ─────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: p.card,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: PrimaryButton(
                label: _busy ? L.saving : L.useThisLocation,
                icon: _busy ? null : Icons.place_rounded,
                height: 54,
                onPressed: _busy ? null : _useMapCentre,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flutterMap(PaperPalette p) {
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _tashkent,
        initialZoom: _cityZoom,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/${p.isDark ? 'dark_all' : 'light_all'}/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          tileProvider: CachedTileProvider(),
          userAgentPackageName: 'com.barber.app',
          maxNativeZoom: 20,
          tileDisplay: const TileDisplay.fadeIn(
            duration: Duration(milliseconds: 220),
          ),
        ),
      ],
    );
  }
}

/// The rounded "type your address" search field with an inline Set action.
class _AddressField extends StatelessWidget {
  const _AddressField({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: InputBorder.none,
                hintText: L.typeYourAddress,
                hintStyle: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: p.textSecondary,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                L.setWord,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The fixed pin that marks the chosen point at screen centre.
class _CentrePin extends StatelessWidget {
  const _CentrePin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: const Offset(0, -16),
          child: Icon(
            Icons.location_on,
            size: 46,
            color: AppColors.accent,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        // Ground dot at the exact centre for precision.
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      ],
    );
  }
}

/// Small floating hint pill.
class _HintChip extends StatelessWidget {
  const _HintChip(this.text);
  final String text;

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
          BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: p.text,
        ),
      ),
    );
  }
}

/// Right-side zoom group + locate-me button.
class _MapButtons extends StatelessWidget {
  const _MapButtons({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocate,
    required this.locating,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLocate;
  final bool locating;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    BoxDecoration deco() => BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: deco(),
          child: Column(
            children: [
              _Btn(icon: Icons.add_rounded, onTap: onZoomIn),
              Container(width: 26, height: 1, color: p.border),
              _Btn(icon: Icons.remove_rounded, onTap: onZoomOut),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: deco(),
          child: locating
              ? const SizedBox(
                  width: 42,
                  height: 42,
                  child: Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.accent,
                    ),
                  ),
                )
              : _Btn(
                  icon: Icons.my_location_rounded,
                  color: AppColors.accent,
                  onTap: onLocate,
                ),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap, this.color});
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
