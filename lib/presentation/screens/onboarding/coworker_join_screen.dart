import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/photo/photo_source.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../root_shell.dart';

/// ════════════════════════════════════════════════════════════════════════
/// FLOW B — COWORKER ONBOARDING ("Regular Barber Joining")
///
/// The mirror of the Leader Loop: a barber joins a shop someone *else* already
/// put on the map. Reached when a barber taps "I work here" on a claimed shop
/// (or, in production, from a Leader's deep-link invite).
///
///   1 · Invite landing  — the shop, the roster, "[Leader] invited you"
///   2 · Make it yours    — bio, price override, 5-photo portfolio grid
///   3 · Pending approval — a live 72h auto-pass countdown + a keep-busy
///                          checklist (payouts, availability) so the wait
///                          never feels like a dead end (Dead-Leader failsafe).
/// ════════════════════════════════════════════════════════════════════════
class CoworkerJoinScreen extends StatefulWidget {
  const CoworkerJoinScreen({
    super.key,
    required this.shop,
    required this.firstName,
    required this.surname,
    required this.age,
    required this.phone,
    this.photo,
  });

  final Barbershop shop;
  final String firstName;
  final String surname;
  final int age;
  final String phone;
  final Uint8List? photo;

  @override
  State<CoworkerJoinScreen> createState() => _CoworkerJoinScreenState();
}

class _CoworkerJoinScreenState extends State<CoworkerJoinScreen> {
  final _bio = TextEditingController();
  final _priceNote = TextEditingController();
  final List<Uint8List> _portfolio = [];

  int _step = 0; // 0 landing · 1 customize · 2 pending
  bool _forward = true;
  JoinRequest? _request;

  // Keep-busy checklist on the pending screen.
  bool _payoutsDone = false;
  bool _availabilityDone = false;

  Timer? _tick;

  String get _leaderName =>
      widget.shop.barbers.isNotEmpty ? widget.shop.barbers.first.name : L.theTeam;

  @override
  void dispose() {
    _tick?.cancel();
    _bio.dispose();
    _priceNote.dispose();
    super.dispose();
  }

  void _go(int next, {bool forward = true}) {
    setState(() {
      _forward = forward;
      _step = next;
    });
  }

  void _onBack() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else if (_step == 1) {
      _go(0, forward: false);
    }
    // Step 2 (pending) has no back — the request is already in.
  }

  Future<void> _addPortfolio() async {
    if (_portfolio.length >= 5) return;
    final bytes = await capturePhoto();
    if (bytes != null && mounted) {
      HapticFeedback.selectionClick();
      setState(() => _portfolio.add(bytes));
    }
  }

  void _submit() {
    HapticFeedback.mediumImpact();
    _request = AppState.instance.submitJoinRequest(
      firstName: widget.firstName,
      surname: widget.surname,
      age: widget.age,
      phone: widget.phone,
      shopId: widget.shop.id,
      shopName: widget.shop.name,
      bio: _bio.text,
      priceNote: _priceNote.text,
      portfolioCount: _portfolio.length,
      photo: widget.photo,
    );
    _availabilityDone = false;
    _payoutsDone = false;
    // Live countdown on the holding screen.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _go(2);
  }

  void _enterApp() {
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
            _TopBar(index: _step, total: 3, onBack: _step == 2 ? null : _onBack),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
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
                  children: [...previous, if (current != null) current],
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    0 => _landing(p),
                    1 => _customize(p),
                    _ => _pending(p),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════ SCREEN 1 · INVITE LANDING ═════════════════════
  Widget _landing(PaperPalette p) {
    final shop = widget.shop;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        // Shop hero — cover with the name + address floated on a scrim.
        FadeSlideIn(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    shop.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                        color: AppColors.accentDeep),
                    loadingBuilder: (c, w, prog) =>
                        prog == null ? w : const ColoredBox(color: Color(0xFF16294B)),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC0B1422)],
                        stops: [0.4, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shop.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            )),
                        Row(
                          children: [
                            const Icon(Icons.place_rounded,
                                size: 13, color: Colors.white70),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(shop.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Invite banner — "[Leader] invited you to join the roster".
        FadeSlideIn(
          delay: const Duration(milliseconds: 70),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: clayDecoration(p, radius: 22),
            child: Row(
              children: [
                InitialAvatar(name: _leaderName, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.mail_rounded,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 5),
                          Text(L.youAreInvited,
                              style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                                letterSpacing: 0.4,
                              )),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(L.invitedToRoster(_leaderName),
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Roster preview — who's already here, plus "+You".
        FadeSlideIn(
          delay: const Duration(milliseconds: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L.theCrew, style: AppTypography.h4(context)),
              const SizedBox(height: 10),
              SizedBox(
                height: 76,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < shop.barbers.length && i < 6; i++)
                      _CrewChip(name: shop.barbers[i].name, index: i),
                    _CrewChip(name: widget.firstName, index: 99, isYou: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: PrimaryButton(
            label: L.joinThisStaff,
            icon: Icons.group_add_rounded,
            style: PrimaryButtonStyle.lime,
            onPressed: () => _go(1),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(L.notMyShop,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: p.textSecondary,
                )),
          ),
        ),
      ],
    );
  }

  // ══════════════════════ SCREEN 2 · MAKE IT YOURS ══════════════════════
  Widget _customize(PaperPalette p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        FadeSlideIn(child: Text(L.makeItYours, style: AppTypography.display(context))),
        const SizedBox(height: 6),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Text(L.makeItYoursSub, style: AppTypography.bodySmall(context)),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: _ClayField(
            controller: _bio,
            label: L.yourBioLabel,
            icon: Icons.edit_note_rounded,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 140),
          child: _ClayField(
            controller: _priceNote,
            label: L.priceOverrideLabel,
            icon: Icons.sell_rounded,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 170),
          child: Row(
            children: [
              Text(L.portfolioLabel, style: AppTypography.h4(context)),
              const SizedBox(width: 8),
              Text('${_portfolio.length}/5',
                  style: AppTypography.caption(context)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 5-photo portfolio grid.
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (var i = 0; i < _portfolio.length; i++)
                _PortfolioTile(
                  bytes: _portfolio[i],
                  onRemove: () => setState(() => _portfolio.removeAt(i)),
                ),
              if (_portfolio.length < 5)
                _AddPortfolioTile(onTap: _addPortfolio),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 240),
          child: PrimaryButton(
            label: L.sendJoinRequest,
            icon: Icons.send_rounded,
            style: PrimaryButtonStyle.lime,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }

  // ═════════════════════ SCREEN 3 · PENDING APPROVAL ════════════════════
  Widget _pending(PaperPalette p) {
    final req = _request;
    final frac = req == null
        ? 1.0
        : (req.timeLeft.inMinutes / (72 * 60)).clamp(0.0, 1.0);
    final hoursLeft = req == null ? 72 : req.timeLeft.inHours;
    final minsLeft = req == null ? 0 : req.timeLeft.inMinutes.remainder(60);

    final checklistDone =
        (_payoutsDone ? 1 : 0) + (_availabilityDone ? 1 : 0) +
            (_portfolio.isNotEmpty ? 1 : 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        // Countdown ring with the shop avatar in the middle.
        Center(
          child: FadeSlideIn(
            child: SizedBox(
              width: 168,
              height: 168,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(168, 168),
                    painter: _CountdownRing(frac),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InitialAvatar(name: widget.shop.name, size: 66, square: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Center(
            child: MiniPill(L.pendingWord,
                style: MiniPillStyle.gold, icon: Icons.hourglass_top_rounded),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 90),
          child: Text(L.waitingLeaderConfirm,
              textAlign: TextAlign.center,
              style: AppTypography.h1(context)),
        ),
        const SizedBox(height: 6),
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: Text(
            L.autoApproveIn(hoursLeft, minsLeft),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 22),
        // Keep-busy checklist — set up the rest while the Leader responds.
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: clayDecoration(p, radius: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(L.whileYouWait, style: AppTypography.h4(context)),
                    const Spacer(),
                    Text('$checklistDone/3',
                        style: AppTypography.caption(context)),
                  ],
                ),
                const SizedBox(height: 12),
                _ChecklistItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: L.setUpPayouts,
                  done: _payoutsDone,
                  onTap: () => setState(() => _payoutsDone = !_payoutsDone),
                ),
                const SizedBox(height: 10),
                _ChecklistItem(
                  icon: Icons.calendar_month_rounded,
                  label: L.setAvailability,
                  done: _availabilityDone,
                  onTap: () =>
                      setState(() => _availabilityDone = !_availabilityDone),
                ),
                const SizedBox(height: 10),
                _ChecklistItem(
                  icon: Icons.photo_library_rounded,
                  label: L.addPortfolioItem,
                  done: _portfolio.isNotEmpty,
                  onTap: _addPortfolio,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 190),
          child: PrimaryButton(
            label: L.enterAppWhileWait,
            icon: Icons.arrow_forward_rounded,
            onPressed: _enterApp,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════ PIECES ════════════════════════════════════

/// Back button + segmented progress rail (shared shape with the Leader Loop).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.index, required this.total, this.onBack});
  final int index;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 6),
      child: Row(
        children: [
          Opacity(
            opacity: onBack == null ? 0.35 : 1,
            child: CircleBtn(
                icon: Icons.arrow_back_rounded, size: 42, onTap: onBack),
          ),
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
                        color: i <= index ? AppColors.accent : p.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A stacked avatar + first name — the roster preview on the landing screen.
class _CrewChip extends StatelessWidget {
  const _CrewChip({required this.name, required this.index, this.isYou = false});
  final String name;
  final int index;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final first = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').first;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              InitialAvatar(
                name: name,
                size: 50,
                index: index,
                color: isYou ? AppColors.accent : null,
              ),
              if (isYou)
                const Positioned(
                  right: -1,
                  bottom: -1,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.add_rounded,
                        size: 13, color: AppColors.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 54,
            child: Text(
              isYou ? L.youWord : first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isYou ? AppColors.accent : p.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A portfolio thumbnail with a remove ✕.
class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.bytes, required this.onRemove});
  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// The dashed "+" tile that opens the camera / gallery.
class _AddPortfolioTile extends StatelessWidget {
  const _AddPortfolioTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_rounded,
                color: AppColors.accent, size: 24),
            const SizedBox(height: 4),
            Text(L.addWord,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                )),
          ],
        ),
      ),
    );
  }
}

/// A tappable checklist row on the pending screen.
class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.icon,
    required this.label,
    required this.done,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.green.withValues(alpha: 0.14)
                  : AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon,
                size: 18,
                color: done ? AppColors.green : AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                  decoration: done ? TextDecoration.lineThrough : null,
                )),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.green : Colors.transparent,
              border: done
                  ? null
                  : Border.all(color: p.textTertiary, width: 1.6),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}

/// The 72h auto-pass countdown ring.
class _CountdownRing extends CustomPainter {
  _CountdownRing(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    // Track.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = AppColors.accent.withValues(alpha: 0.14),
    );
    // Progress arc (remaining time).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // start at top
      6.2832 * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AppColors.accent, AppColors.accentDeep],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_CountdownRing old) => old.fraction != fraction;
}

/// Clay-styled text field (local to keep this flow self-contained).
class _ClayField extends StatelessWidget {
  const _ClayField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
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
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: p.text),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
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
