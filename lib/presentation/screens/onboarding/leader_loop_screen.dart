import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/location/geo_position.dart';
import '../../../core/map/fast_tiles.dart';
import '../../../core/photo/photo_source.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../root_shell.dart';

/// ════════════════════════════════════════════════════════════════════════
/// THE LEADER LOOP — first-barber onboarding.
///
/// A barber whose shop isn't on the map yet doesn't fill out paperwork; they
/// plant a flag. This flow is engineered to feel like a *reward*: a 60-second
/// run of geo-tag → "you're the FIRST here" pitch → one-tap proof → invite the
/// team, closed off with a confetti moment. Status, not a chore.
///
/// Launched from the shop-search screen when a barber taps "Can't find your
/// shop? Add it in 60 seconds." Personal details are already collected on the
/// registration screen and passed straight through.
/// ════════════════════════════════════════════════════════════════════════
class LeaderLoopScreen extends StatefulWidget {
  const LeaderLoopScreen({
    super.key,
    required this.firstName,
    required this.surname,
    required this.age,
    required this.phone,
    this.initialShopName = '',
    this.photo,
  });

  final String firstName;
  final String surname;
  final int age;
  final String phone;
  final String initialShopName;

  /// The barber's own portrait, carried from the registration screen. It used
  /// to stop there — the Flow B (join) branch passed it on, this one didn't —
  /// so a shop founder's photo silently vanished.
  final Uint8List? photo;

  @override
  State<LeaderLoopScreen> createState() => _LeaderLoopScreenState();
}

enum _Step { geo, pitch, trust, invite }

class _LeaderLoopScreenState extends State<LeaderLoopScreen> {
  final _map = MapController();
  final _name = TextEditingController();
  final _addr = TextEditingController();

  _Step _step = _Step.geo;
  bool _forward = true;

  // Geo-tag — the map pans under a fixed centre pin.
  LatLng _pin = const LatLng(41.3111, 69.2797);
  bool _pinLifted = false;
  bool _locating = false;
  Timer? _settle;

  bool _claimLeader = true;
  Uint8List? _proof;

  Barbershop? _created;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _name.text = widget.initialShopName.trim();
  }

  @override
  void dispose() {
    _settle?.cancel();
    _map.dispose();
    _name.dispose();
    _addr.dispose();
    super.dispose();
  }

  // ── Navigation between steps ───────────────────────────────
  void _go(_Step next, {bool forward = true}) {
    setState(() {
      _forward = forward;
      _step = next;
    });
  }

  void _onBack() {
    switch (_step) {
      case _Step.geo:
        Navigator.of(context).maybePop();
      case _Step.pitch:
        _go(_Step.geo, forward: false);
      case _Step.trust:
        _go(_Step.pitch, forward: false);
      case _Step.invite:
        _go(_Step.trust, forward: false);
    }
  }

  int get _stepIndex => _Step.values.indexOf(_step);

  // ── Step 1 · geo-tag ───────────────────────────────────────
  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await createLocator().position();
      if (pos != null && isInTashkent(pos.lat, pos.lng)) {
        final ll = LatLng(pos.lat, pos.lng);
        _pin = ll;
        _map.move(ll, 16);
        HapticFeedback.mediumImpact();
      } else {
        _toast(L.outsideCity);
      }
    } catch (_) {
      // Location denied / unsupported — the manual pin still works.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirmGeo() {
    if (_name.text.trim().isEmpty) return _toast(L.errShopName);
    if (_addr.text.trim().isEmpty) return _toast(L.errShopAddress);
    if (!isInTashkent(_pin.latitude, _pin.longitude)) {
      return _toast(L.outsideCity);
    }
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    _go(_Step.pitch);
  }

  // ── Step 2 · the pitch ─────────────────────────────────────
  void _claim() {
    HapticFeedback.mediumImpact();
    setState(() => _claimLeader = true);
    _go(_Step.trust);
  }

  void _skipLeader() {
    setState(() => _claimLeader = false);
    _createShop(); // ghost shop, joined as a regular barber
    _finish();
  }

  // ── Step 3 · trust capture ─────────────────────────────────
  Future<void> _capture() async {
    final bytes = await capturePhoto(camera: true);
    if (bytes != null && mounted) {
      HapticFeedback.selectionClick();
      setState(() => _proof = bytes);
    }
  }

  void _afterTrust() {
    _createShop(); // grant Leader access immediately; review happens later
    _go(_Step.invite);
  }

  // ── Shop creation (once) ───────────────────────────────────
  void _createShop() {
    if (_created != null) return;
    _created = AppState.instance.createShopAsLeader(
      firstName: widget.firstName,
      surname: widget.surname,
      age: widget.age,
      phone: widget.phone,
      shopName: _name.text,
      address: _addr.text,
      lat: _pin.latitude,
      lng: _pin.longitude,
      claimLeader: _claimLeader,
      leaderPhoto: widget.photo,
      shopProof: _proof,
    );
  }

  String get _inviteLink =>
      'https://fade.uz/join/${_created?.id ?? 'shop'}';
  String get _inviteMessage =>
      L.inviteMessageFor(_name.text.trim(), _inviteLink);

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      _copyInvite();
    }
  }

  void _shareTelegram() => _launch(
      'https://t.me/share/url?url=${Uri.encodeComponent(_inviteLink)}'
      '&text=${Uri.encodeComponent(_inviteMessage)}');

  void _shareWhatsapp() =>
      _launch('https://wa.me/?text=${Uri.encodeComponent(_inviteMessage)}');

  void _copyInvite() {
    Clipboard.setData(ClipboardData(text: _inviteMessage));
    HapticFeedback.selectionClick();
    _toast(L.inviteCopied);
  }

  // ── Finish → celebrate → into the app ──────────────────────
  void _finish() {
    setState(() => _celebrating = true);
  }

  void _enterApp() {
    Navigator.of(context).pushAndRemoveUntil(
      FadeThroughPageRoute(child: const RootShell()),
      (r) => false,
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  index: _stepIndex,
                  total: _Step.values.length,
                  onBack: _onBack,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) {
                      final slide = Tween<Offset>(
                        begin: Offset(_forward ? 0.10 : -0.10, 0),
                        end: Offset.zero,
                      ).animate(anim);
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        ...previous,
                        if (current != null) current,
                      ],
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(p),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_celebrating)
            Positioned.fill(
              child: _CelebrationOverlay(
                leader: _claimLeader,
                shopName: _name.text.trim(),
                onDone: _enterApp,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep(PaperPalette p) => switch (_step) {
        _Step.geo => _geoStep(p),
        _Step.pitch => _pitchStep(p),
        _Step.trust => _trustStep(p),
        _Step.invite => _inviteStep(p),
      };

  // ═══════════════════════════ STEP 1 · GEO-TAG ═══════════════════════════
  Widget _geoStep(PaperPalette p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
      children: [
        FadeSlideIn(child: Text(L.pinShopTitle, style: AppTypography.display(context))),
        const SizedBox(height: 6),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Text(L.pinShopSub, style: AppTypography.bodySmall(context)),
        ),
        const SizedBox(height: 18),
        // The map with a fixed centre pin — pan the city under the marker.
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 300,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: _pin,
                      initialZoom: 15,
                      minZoom: 10,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onPositionChanged: (camera, hasGesture) {
                        _pin = camera.center;
                        if (hasGesture && !_pinLifted) {
                          setState(() => _pinLifted = true);
                        }
                        _settle?.cancel();
                        _settle = Timer(
                          const Duration(milliseconds: 180),
                          () {
                            if (mounted) setState(() => _pinLifted = false);
                          },
                        );
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: cartoTileUrl(dark: p.isDark),
                        subdomains: cartoSubdomains,
                        tileProvider: CachedTileProvider(),
                        userAgentPackageName: 'com.barber.app',
                        keepBuffer: 3,
                        panBuffer: 1,
                      ),
                    ],
                  ),
                  // Ground shadow at the true centre.
                  IgnorePointer(
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: _pinLifted ? 16 : 11,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  // The pin — its tip sits on the centre; it lifts while dragging.
                  IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -23),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          scale: _pinLifted ? 1.14 : 1,
                          child: const _DropPin(),
                        ),
                      ),
                    ),
                  ),
                  // "Use my location" chip.
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _MapChip(
                      icon: _locating
                          ? Icons.hourglass_top_rounded
                          : Icons.my_location_rounded,
                      label: L.useMyLocation,
                      onTap: _locating ? null : _useMyLocation,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: _ClayField(
            controller: _name,
            label: L.shopNameLabel,
            icon: Icons.storefront_rounded,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: _ClayField(
            controller: _addr,
            label: L.streetAddressLabel,
            icon: Icons.location_on_rounded,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 240),
          child: PrimaryButton(
            label: L.continueWord,
            icon: Icons.arrow_forward_rounded,
            style: PrimaryButtonStyle.lime,
            onPressed: _confirmGeo,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════ STEP 2 · THE PITCH ═════════════════════════
  Widget _pitchStep(PaperPalette p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 2, 22, 28),
      children: [
        const SizedBox(height: 6),
        // "You're the FIRST" hero — a haloed crown over the shop name.
        Center(
          child: FadeSlideIn(
            child: SizedBox(
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _PulseHalo(),
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 46),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: MiniPill(L.firstHereTag,
                style: MiniPillStyle.gold, icon: Icons.bolt_rounded),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 90),
          child: Text(
            L.firstBarberHere,
            textAlign: TextAlign.center,
            style: AppTypography.display(context),
          ),
        ),
        const SizedBox(height: 6),
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: Text(
            _name.text.trim(),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: clayDecoration(p, radius: 24),
            child: Column(
              children: [
                Text(L.leaderPitchBody,
                    style: AppTypography.bodySmall(context)),
                const SizedBox(height: 14),
                _PerkRow(icon: Icons.dashboard_customize_rounded, text: L.leaderPerkStorefront),
                const SizedBox(height: 10),
                _PerkRow(icon: Icons.add_photo_alternate_rounded, text: L.leaderPerkPhoto),
                const SizedBox(height: 10),
                _PerkRow(icon: Icons.groups_rounded, text: L.leaderPerkInvite),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 190),
          child: PrimaryButton(
            label: L.claimLeaderRole,
            icon: Icons.workspace_premium_rounded,
            style: PrimaryButtonStyle.lime,
            onPressed: _claim,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: _skipLeader,
            child: Text(
              L.justJoinAsBarber,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: p.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════ STEP 3 · TRUST ═════════════════════════════
  Widget _trustStep(PaperPalette p) {
    final has = _proof != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
      children: [
        FadeSlideIn(child: Text(L.proveRealTitle, style: AppTypography.display(context))),
        const SizedBox(height: 6),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Text(L.proveRealSub, style: AppTypography.bodySmall(context)),
        ),
        const SizedBox(height: 20),
        // Viewfinder — corner brackets frame the shot (or the captured proof).
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: GestureDetector(
            onTap: _capture,
            child: _ProofFrame(photo: _proof),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 140),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _HintChip(icon: Icons.storefront_rounded, text: L.proofStorefront),
              _HintChip(icon: Icons.chair_alt_rounded, text: L.proofWorkstation),
              _HintChip(icon: Icons.badge_rounded, text: L.proofCard),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          delay: const Duration(milliseconds: 170),
          child: Row(
            children: [
              Icon(Icons.verified_user_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(L.tempLeaderGranted,
                    style: AppTypography.caption(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: PrimaryButton(
            label: has ? L.continueWord : L.takePhoto,
            icon: has ? Icons.arrow_forward_rounded : Icons.photo_camera_rounded,
            style: PrimaryButtonStyle.lime,
            onPressed: has ? _afterTrust : _capture,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: _afterTrust,
            child: Text(
              L.skipForNow,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: p.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════ STEP 4 · VIRAL ═════════════════════════════
  Widget _inviteStep(PaperPalette p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
      children: [
        FadeSlideIn(
          child: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(L.bringYourTeam,
                    style: AppTypography.h1(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Text(L.bringTeamSub, style: AppTypography.bodySmall(context)),
        ),
        const SizedBox(height: 18),
        // The pre-written message the leader fires off to coworkers.
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: clayDecoration(p, radius: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.link_rounded, size: 15, color: p.textTertiary),
                    const SizedBox(width: 6),
                    Text('fade.uz/join',
                        style: AppTypography.caption(context)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _inviteMessage,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 140),
          child: _ShareButton(
            icon: Icons.send_rounded,
            label: L.inviteViaTelegram,
            color: const Color(0xFF2AABEE),
            onTap: _shareTelegram,
          ),
        ),
        const SizedBox(height: 10),
        FadeSlideIn(
          delay: const Duration(milliseconds: 170),
          child: _ShareButton(
            icon: Icons.chat_rounded,
            label: L.inviteViaWhatsapp,
            color: const Color(0xFF25D366),
            onTap: _shareWhatsapp,
          ),
        ),
        const SizedBox(height: 10),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: _ShareButton(
            icon: Icons.content_copy_rounded,
            label: L.copyInvite,
            color: p.textSecondary,
            outlined: true,
            onTap: _copyInvite,
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 230),
          child: PrimaryButton(
            label: L.enterMyShop,
            icon: Icons.storefront_rounded,
            onPressed: _finish,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: _finish,
            child: Text(
              L.inviteLater,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: p.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════ CHROME ════════════════════════════════════

/// Back button + a segmented progress rail + a "≈60s" reassurance pill.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.index, required this.total, required this.onBack});

  final int index;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 6),
      child: Row(
        children: [
          CircleBtn(icon: Icons.arrow_back_rounded, size: 42, onTap: onBack),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < total; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= index
                            ? AppColors.accent
                            : p.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: p.textTertiary),
              const SizedBox(width: 2),
              Text(L.leaderStepOf(index + 1, total),
                  style: AppTypography.caption(context)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The centre map pin — a rounded teardrop with a white dot.
class _DropPin extends StatelessWidget {
  const _DropPin();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.location_on_rounded,
              size: 46,
              color: AppColors.accent,
              shadows: [
                Shadow(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]),
          Positioned(
            top: 11,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small frosted chip that floats over the map ("Use my location").
class _MapChip extends StatelessWidget {
  const _MapChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.accentDeep),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentDeep,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Expanding concentric rings — the halo behind the "first here" crown.
class _PulseHalo extends StatefulWidget {
  const _PulseHalo();

  @override
  State<_PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<_PulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: const Size(150, 150),
        painter: _HaloPainter(_c.value),
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = 46 + phase * 30;
      final alpha = (1 - phase) * 0.5;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.accent.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.t != t;
}

/// One benefit line in the Leader pitch card.
class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: p.text,
              )),
        ),
        Icon(Icons.check_circle_rounded, size: 18, color: AppColors.accent),
      ],
    );
  }
}

/// The trust-capture viewfinder: corner brackets over a live-looking frame,
/// swapped for the captured photo (with a ✓) once taken.
class _ProofFrame extends StatelessWidget {
  const _ProofFrame({this.photo});
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: p.isDark ? Colors.black26 : const Color(0xFFEDF1FA),
          borderRadius: BorderRadius.circular(22),
          image: photo != null
              ? DecorationImage(image: MemoryImage(photo!), fit: BoxFit.cover)
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo == null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_camera_rounded,
                        color: AppColors.accent, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(L.takePhoto, style: AppTypography.caption(context)),
                ],
              ),
            // Corner brackets.
            const Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CustomPaint(painter: _BracketPainter()),
              ),
            ),
            if (photo != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 15, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(L.retakePhoto,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 24.0;
    final w = size.width, h = size.height;
    // TL
    canvas.drawLine(const Offset(0, len), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    // TR
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    // BL
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    // BR
    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => false;
}

/// A small icon-labelled chip (proof suggestions).
class _HintChip extends StatelessWidget {
  const _HintChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: p.textSecondary),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: p.textSecondary,
              )),
        ],
      ),
    );
  }
}

/// A big colour-blocked share button (Telegram / WhatsApp / copy).
class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Material(
      color: outlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: outlined ? Border.all(color: p.border, width: 1.4) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: outlined ? p.textSecondary : Colors.white),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: outlined ? p.text : Colors.white,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// A clay-styled text field for the geo-tag step.
class _ClayField extends StatelessWidget {
  const _ClayField({
    required this.controller,
    required this.label,
    required this.icon,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: p.text),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: p.textTertiary),
        filled: true,
        fillColor: p.card,
        labelStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w600, color: p.textSecondary),
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(AppColors.accent, 1.5),
      ),
    );
  }
}

// ══════════════════════════ CELEBRATION ═══════════════════════════════════

/// Full-screen confetti reward — crown drops in, particles burst, "You lead X".
/// Auto-advances into the app after a beat (or on tap).
class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({
    required this.leader,
    required this.shopName,
    required this.onDone,
  });

  final bool leader;
  final String shopName;
  final VoidCallback onDone;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final List<_Particle> _particles;
  Timer? _auto;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    final rnd = math.Random(7);
    const colors = [
      AppColors.accent,
      AppColors.gold,
      Color(0xFF25D366),
      Color(0xFFFF6BAA),
      Colors.white,
    ];
    _particles = List.generate(52, (i) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 1.5;
      return _Particle(
        angle: angle,
        speed: 150 + rnd.nextDouble() * 240,
        color: colors[i % colors.length],
        size: 6 + rnd.nextDouble() * 9,
        spin: (rnd.nextDouble() - 0.5) * 10,
      );
    });
    _c.forward();
    _auto = Timer(const Duration(milliseconds: 2100), _done);
  }

  void _done() {
    if (_left) return; // guard the timer + tap both firing
    _left = true;
    _auto?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _done,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final crownScale = Curves.elasticOut.transform(t.clamp(0.0, 1.0));
          final textIn =
              Curves.easeOut.transform(((t - 0.25) / 0.5).clamp(0.0, 1.0));
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.accent, AppColors.accentDeep],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _ConfettiPainter(_particles, t)),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.4 + 0.6 * crownScale,
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2),
                          ),
                          child: Icon(
                            widget.leader
                                ? Icons.workspace_premium_rounded
                                : Icons.check_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Opacity(
                        opacity: textIn,
                        child: Column(
                          children: [
                            Text(
                              widget.leader
                                  ? L.welcomeLeader
                                  : L.joinedAsBarber,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                widget.leader
                                    ? L.youLeadNow(widget.shopName)
                                    : widget.shopName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 30,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              L.shopIsLive,
                              style: GoogleFonts.nunito(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.spin,
  });
  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double spin;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);
  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    for (final part in particles) {
      final dist = part.speed * t;
      final x = cx + math.cos(part.angle) * dist;
      final y = cy + math.sin(part.angle) * dist + 320 * t * t;
      final alpha = (1 - t).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(part.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: part.size, height: part.size * 0.6),
          const Radius.circular(1.5),
        ),
        Paint()..color = part.color.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
