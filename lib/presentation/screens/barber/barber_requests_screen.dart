import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/format/money.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/paper_kit.dart';

/// Incoming booking requests — confirm or decline. Swipe a card right to
/// confirm, left to decline, or use the buttons. Cards cascade in.
class BarberRequestsScreen extends StatelessWidget {
  const BarberRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final requests = AppState.instance.incomingRequests;
          return SafeArea(
            bottom: false,
            child: requests.isEmpty
                ? const _EmptyRequests()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                    children: [
                      _Header(count: requests.length),
                      const SizedBox(height: 18),
                      for (var i = 0; i < requests.length; i++) ...[
                        FadeSlideIn(
                          delay: Duration(milliseconds: 70 * i),
                          offset: const Offset(0, 0.12),
                          child: _RequestCard(booking: requests[i]),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(L.requestsTitle, style: AppTypography.h1(context)),
            const SizedBox(width: 10),
            // Count badge — flat accent pill.
            ScaleIn(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Text('$count',
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.swipe_rounded, size: 15, color: p.textTertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(L.swipeToAct,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(context)),
            ),
          ],
        ),
      ],
    );
  }
}

/// A request in the barber's queue.
///
/// Swiping already showed where the card goes (green right = accept, red left
/// = decline); tapping the buttons used to make it vanish. Now a tap plays
/// the same exit as the swipe: the card slides off revealing the coloured
/// lane, then its space closes up, and only then is the request answered.
class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.booking});
  final Booking booking;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard>
    with SingleTickerProviderStateMixin {
  Booking get booking => widget.booking;

  // Created up front, not lazily: a card answered by swipe never animates,
  // and a lazy controller would then be created inside dispose(), which
  // Flutter rejects.
  late final AnimationController _exit;

  @override
  void initState() {
    super.initState();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
  }

  /// +1 slides right (accept), -1 left (decline), 0 while idle.
  int _dir = 0;

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  Future<void> _leave(int dir, VoidCallback answer) async {
    if (_dir != 0) return; // already leaving
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      answer();
      return;
    }
    setState(() => _dir = dir);
    await _exit.forward();
    if (mounted) answer();
  }

  String _whenLabel(DateTime dt) {
    final now = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = d.difference(today).inDays;
    final time = DateFormat('HH:mm').format(dt);
    if (diff == 0) return '${L.today} · $time';
    if (diff == 1) return '${L.tomorrow} · $time';
    return '${DateFormat('EEE d MMM').format(dt)} · $time';
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  void _confirm(BuildContext context) {
    HapticFeedback.mediumImpact();
    AppState.instance.confirmBooking(booking.id);
    _toast(context, L.confirmedToast(booking.clientName ?? L.youWord));
  }

  void _decline(BuildContext context) {
    HapticFeedback.lightImpact();
    AppState.instance.declineBooking(booking.id);
    _toast(context, L.declinedToast);
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final card = Dismissible(
      key: ValueKey(b.id),
      background: _SwipeBg(
        color: AppColors.green,
        icon: Icons.check_rounded,
        label: L.confirmWord,
        alignLeft: true,
      ),
      secondaryBackground: _SwipeBg(
        color: AppColors.red,
        icon: Icons.close_rounded,
        label: L.decline,
        alignLeft: false,
      ),
      onDismissed: (dir) {
        if (dir == DismissDirection.startToEnd) {
          _confirm(context);
        } else {
          _decline(context);
        }
      },
      // Each request IS the full "registering" card — the same rich layout
      // as the live pop-up, inline. Swipe stays as the fast path.
      child: _CardBody(
        booking: b,
        whenLabel: _whenLabel(b.dateTime),
        onConfirm: () => _leave(1, () => _confirm(context)),
        onDecline: () => _leave(-1, () => _decline(context)),
      ),
    );
    if (_dir == 0) return card;

    // Slide off (first 70%), then close the gap (last 30%).
    final slide = CurvedAnimation(
        parent: _exit,
        curve: const Interval(0, 0.7, curve: Curves.easeInCubic));
    final close = CurvedAnimation(
        parent: _exit,
        curve: const Interval(0.62, 1, curve: Curves.easeInOutCubic));
    final accept = _dir > 0;
    return SizeTransition(
      sizeFactor: ReverseAnimation(close),
      axisAlignment: -1,
      child: Stack(
        children: [
          Positioned.fill(
            child: _SwipeBg(
              color: accept ? AppColors.green : AppColors.red,
              icon: accept ? Icons.check_rounded : Icons.close_rounded,
              label: accept ? L.confirmWord : L.decline,
              alignLeft: accept,
            ),
          ),
          SlideTransition(
            position: Tween(
              begin: Offset.zero,
              end: Offset(_dir * 1.1, 0),
            ).animate(slide),
            child: IgnorePointer(child: card),
          ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.booking,
    required this.whenLabel,
    required this.onConfirm,
    required this.onDecline,
  });
  final Booking booking;
  final String whenLabel;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final b = booking;
    final name = b.clientName ?? L.youWord;
    // Deterministic mock trust meta (rating · jobs · distance) — same as the
    // live pop-up, stable per client until real profiles sync.
    final h = name.hashCode.abs();
    final rating = 4.5 + (h % 5) / 10.0;
    final jobs = 3 + h % 37;
    final km = 0.8 + (h % 50) / 10.0;

    return Container(
      decoration: clayDecoration(p, radius: 22),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client hero — big squircle, name, trust line (like the pop-up).
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4F9CFF), AppColors.accentDeep],
                  ),
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.nunito(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w900,
                            color: p.text)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            L.ratingJobs(rating.toStringAsFixed(1), jobs),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(b.service.icon,
                    color: AppColors.accent, size: 21),
              ),
            ],
          ),
          // Client note, when they left one.
          if ((b.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.cardAlt,
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                    left: BorderSide(color: AppColors.accent, width: 3)),
              ),
              child: Text(b.note!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTypography.bodySmall(context).copyWith(height: 1.35)),
            ),
          ],
          const SizedBox(height: 12),
          // Meta chips: when · service · distance.
          Row(
            children: [
              // The time is what a barber needs most, so it keeps its full
              // width; the shorter chips share what's left. As three equal
              // Flexibles, "Today · 13:00" was cut to "Today · 1…".
              _MetaChip(
                  icon: Icons.schedule_rounded, text: whenLabel, shrink: false),
              const SizedBox(width: 8),
              Flexible(
                child: _MetaChip(
                    icon: Icons.timer_outlined,
                    text: b.service.formattedDuration),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _MetaChip(
                    icon: Icons.near_me_rounded,
                    text: L.kmAway(km.toStringAsFixed(1))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Estimated pay — the green block from the pop-up, compact.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L.estimatedPay,
                          style: GoogleFonts.nunito(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: const Color(0xFF177A48))),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Money.som(b.service.price),
                          maxLines: 1,
                          softWrap: false,
                          style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF137A45)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Flexible so the ellipsis can work: unconstrained, this
                // pushed the row past the card edge on small phones.
                Flexible(
                  child: Text(
                      '${L.tr(b.service.name)} · ${b.service.formattedDuration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF177A48))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Big accept / decline — the pop-up's action pair.
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: L.decline,
                  icon: Icons.close_rounded,
                  filled: false,
                  onTap: onDecline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _ActionBtn(
                  label: L.confirmBooking,
                  icon: Icons.check_rounded,
                  filled: true,
                  onTap: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small meta chip on the request card (time · duration · distance).
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text, this.shrink = true});
  final IconData icon;
  final String text;

  /// Whether the text may shrink (with an ellipsis) to fit a Flexible slot.
  /// The time chip sits outside any Flexible at its natural width, where a
  /// Flexible inside would get an unbounded width and fail layout.
  final bool shrink;

  Widget _label(PaperPalette p) => Text(text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.nunito(
          fontSize: 12, fontWeight: FontWeight.w700, color: p.textSecondary));

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: p.cardAlt,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accent),
          const SizedBox(width: 4),
          if (shrink)
            Flexible(child: _label(p))
          else
            _label(p),
        ],
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignLeft,
  });
  final Color color;
  final IconData icon;
  final String label;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 26),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final filled = widget.filled;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.accent : p.cardAlt,
            borderRadius: BorderRadius.circular(999),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: 17, color: filled ? Colors.white : p.textSecondary),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: filled ? Colors.white : p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRequests extends StatefulWidget {
  const _EmptyRequests();

  @override
  State<_EmptyRequests> createState() => _EmptyRequestsState();
}

class _EmptyRequestsState extends State<_EmptyRequests>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, -6 + 12 * _c.value),
              child: child,
            ),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.inbox_rounded,
                  size: 42, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 18),
          Text(L.allCaughtUpCut, style: AppTypography.h2(context)),
          const SizedBox(height: 6),
          Text(L.newRequestsAppearHere,
              style: AppTypography.bodySmall(context)),
        ],
      ),
    );
  }
}
