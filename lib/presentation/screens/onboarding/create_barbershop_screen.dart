import '../../../core/map/map_attribution.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/location/location_service.dart';
import '../../../core/map/fast_tiles.dart';
import '../../../core/photo/photo_source.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../root_shell.dart';

/// Create a brand-new barbershop when yours isn't on the map: pin the location,
/// name it, add photos + info, set working hours + days off — then it's live on
/// the map and you're working as its founder.
class CreateBarbershopScreen extends StatefulWidget {
  const CreateBarbershopScreen({super.key, required this.initial});
  final LatLng initial;

  @override
  State<CreateBarbershopScreen> createState() =>
      _CreateBarbershopScreenState();
}

class _CreateBarbershopScreenState extends State<CreateBarbershopScreen> {
  final MapController _map = MapController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _info = TextEditingController();
  final List<Uint8List> _photos = [];
  int _from = 9;
  int _till = 21;
  final Set<int> _off = {};
  bool _busy = false;

  @override
  void dispose() {
    _map.dispose();
    _name.dispose();
    _info.dispose();
    super.dispose();
  }

  String _hh(int h) => '${h.toString().padLeft(2, '0')}:00';

  Future<void> _addPhoto() async {
    final b = await capturePhoto();
    if (b != null) setState(() => _photos.add(b));
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      _toast(L.csNeedName);
      return;
    }
    // A brand-new shop has no rating, no reviews and no history — its photos
    // are the only reason anyone would tap it on the map. Shipping one with an
    // empty gallery puts a dead pin on the map and blames the barber for it.
    if (_photos.isEmpty) {
      _toast(L.csNeedPhotos);
      return;
    }
    setState(() => _busy = true);
    final c = _map.camera.center;
    final addr = await reverseGeocode(c.latitude, c.longitude) ?? 'Tashkent';
    if (!mounted) return;
    final s = AppState.instance;
    final user = s.user;
    final parts = user.fullName.trim().split(' ');
    // Creating flips the account into barber mode as the shop's founder.
    s.createShopAsLeader(
      firstName: parts.isNotEmpty ? parts.first : 'Barber',
      surname: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      age: 25,
      phone: user.phone,
      shopName: _name.text.trim(),
      address: addr,
      lat: c.latitude,
      lng: c.longitude,
      claimLeader: true,
      leaderPhoto: s.userPhoto,
    );
    // Apply the details to the barber's shop context.
    s.setShopDescription(_info.text.trim());
    for (final p in _photos) {
      s.addShopPhoto(p);
    }
    s.setWorkingHours(_from, _till);
    for (final d in _off) {
      s.toggleOffDay(d);
    }
    s.setWeeklyGoal(s.weeklyGoalSom);
    s.markBarberOnboarded();
    HapticFeedback.mediumImpact();
    // Role has flipped → RootShell now shows the barber side.
    if (!mounted) {
      _busy = false;
      return;
    }
    // Never leave the button dead: clear busy before we (re)build or navigate.
    setState(() => _busy = false);
    Navigator.of(context).pushAndRemoveUntil(
      FadeThroughPageRoute(child: const RootShell()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
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
                    child: Text(L.csTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h1(context)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // ── Location: pannable map with a fixed centre pin ──
                  _Label(L.csLocation),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          FlutterMap(
                            mapController: _map,
                            options: MapOptions(
                              initialCenter: widget.initial,
                              initialZoom: 15.5,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: cartoTileUrl(dark: p.isDark),
                                subdomains: const ['a', 'b', 'c', 'd'],
                                tileProvider: CachedTileProvider(),
                                userAgentPackageName: 'com.barber.app',
                              ),
                              const MapAttribution(),
                            ],
                          ),
                          // Fixed centre pin — the map pans under it.
                          Transform.translate(
                            offset: const Offset(0, -16),
                            child: const Icon(Icons.location_on_rounded,
                                size: 44, color: AppColors.accent),
                          ),
                          Positioned(
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: p.card,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                      color: p.shadow,
                                      blurRadius: 10,
                                      offset: const Offset(0, 3)),
                                ],
                              ),
                              child: Text(L.csSetOnMap,
                                  style: GoogleFonts.nunito(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: p.text)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _Label(L.csName),
                  const SizedBox(height: 8),
                  _Field(controller: _name, hint: L.csName),
                  const SizedBox(height: 22),
                  _Label(L.csInfo),
                  const SizedBox(height: 8),
                  _Field(controller: _info, hint: L.csInfoHint, lines: 3),
                  const SizedBox(height: 22),
                  _Label(L.csPhotos),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 88,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var i = 0; i < _photos.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(_photos[i],
                                  width: 88, height: 88, fit: BoxFit.cover),
                            ),
                          ),
                        GestureDetector(
                          onTap: _addPhoto,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.add_a_photo_rounded,
                                size: 24, color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _Label(L.csHours),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _HourStepper(
                          label: L.csFrom,
                          value: _hh(_from),
                          onMinus: _from > 5
                              ? () => setState(() => _from--)
                              : null,
                          onPlus: _from < _till - 1
                              ? () => setState(() => _from++)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HourStepper(
                          label: L.csTill,
                          value: _hh(_till),
                          onMinus: _till > _from + 1
                              ? () => setState(() => _till--)
                              : null,
                          onPlus:
                              _till < 24 ? () => setState(() => _till++) : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _Label(L.csOffDays),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        _DayChip(
                          label: L.weekdayShort(d),
                          off: _off.contains(d),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (_off.contains(d)) {
                                _off.remove(d);
                              } else {
                                _off.add(d);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryButton(
                label: L.csCreate,
                icon: Icons.check_rounded,
                height: 56,
                onPressed: _busy ? null : _create,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.h4(context));
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint, this.lines = 1});
  final TextEditingController controller;
  final String hint;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      maxLines: lines,
      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: p.text),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: p.card,
        hintStyle: GoogleFonts.nunito(color: p.textTertiary),
        border: b(p.border),
        enabledBorder: b(p.border),
        focusedBorder: b(AppColors.accent, 1.5),
      ),
    );
  }
}

class _HourStepper extends StatelessWidget {
  const _HourStepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });
  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    Widget btn(IconData i, VoidCallback? on) => GestureDetector(
          onTap: on == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  on();
                },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: on == null
                  ? p.cardAlt
                  : AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(i,
                size: 18, color: on == null ? p.textTertiary : AppColors.accent),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: clayDecoration(p, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption(context)),
          const SizedBox(height: 6),
          Row(
            children: [
              btn(Icons.remove_rounded, onMinus),
              Expanded(
                child: Text(value,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: p.text)),
              ),
              btn(Icons.add_rounded, onPlus),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip(
      {required this.label, required this.off, required this.onTap});
  final String label;
  final bool off;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 40,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: off ? AppColors.red.withValues(alpha: 0.14) : p.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: off ? AppColors.red.withValues(alpha: 0.5) : p.border),
        ),
        child: Text(label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: off ? AppColors.red : p.text,
            )),
      ),
    );
  }
}
