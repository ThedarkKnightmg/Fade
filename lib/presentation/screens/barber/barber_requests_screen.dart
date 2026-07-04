import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
            Text(L.swipeToAct, style: AppTypography.bodySmall(context)),
          ],
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.booking});
  final Booking booking;

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
    return Dismissible(
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
      child: _CardBody(
        booking: b,
        whenLabel: _whenLabel(b.dateTime),
        onConfirm: () => _confirm(context),
        onDecline: () => _decline(context),
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
    return Container(
      decoration: clayDecoration(p, radius: 22),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WHO + WHEN + status.
          Row(
            children: [
              InitialAvatar(
                  name: b.clientName ?? L.youWord, size: 44, index: 3),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.clientName ?? L.youWord,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h4(context)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(whenLabel,
                            style: AppTypography.bodySmall(context)),
                      ],
                    ),
                  ],
                ),
              ),
              MiniPill(L.tagPending, style: MiniPillStyle.gold),
            ],
          ),
          const SizedBox(height: 12),
          // WHAT + price — one clean line.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.cardAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(b.service.icon, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${b.service.name} · ${b.service.formattedDuration}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: p.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(b.service.formattedPrice,
                    style: AppTypography.h4(context)
                        .copyWith(color: AppColors.accent)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Accept / decline pills.
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
