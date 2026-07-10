import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';

/// How long the barber has to respond before it auto-declines.
const int _respondSeconds = 20;

/// Show the live incoming-request pop-up. Returns when it's accepted, declined,
/// or timed out.
Future<void> showIncomingRequestSheet(
    BuildContext context, IncomingRequest req) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    builder: (_) => _IncomingRequestSheet(req: req),
  );
}

/// Open a waiting inbox request in the SAME rich sheet as the live pop-up —
/// client hero, note, meta chips, estimated pay, big Accept/Decline. No
/// countdown: it's already sitting in the inbox.
Future<void> showBookingRequestSheet(BuildContext context, Booking b) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RequestDetailSheet(booking: b),
  );
}

class _RequestDetailSheet extends StatelessWidget {
  const _RequestDetailSheet({required this.booking});
  final Booking booking;

  void _finish(BuildContext context, bool accept) {
    final b = booking;
    final name = b.clientName ?? L.youWord;
    final messenger = ScaffoldMessenger.of(context);
    if (accept) {
      HapticFeedback.mediumImpact();
      AppState.instance.confirmBooking(b.id);
    } else {
      HapticFeedback.lightImpact();
      AppState.instance.declineBooking(b.id);
    }
    Navigator.of(context).maybePop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(accept ? L.confirmedToast(name) : L.declinedToast),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final b = booking;
    final name = b.clientName ?? L.youWord;
    // Deterministic mock trust meta (rating · jobs · distance), stable per
    // client — mirrors the live pop-up until real profiles sync.
    final h = name.hashCode.abs();
    final rating = 4.5 + (h % 5) / 10.0;
    final jobs = 3 + h % 37;
    final km = 0.8 + (h % 50) / 10.0;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, -8)),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 18 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: p.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            // Header.
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: const Text('!',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(L.newBookingRequest,
                      style: AppTypography.h3(context)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Client.
            Row(
              children: [
                _Squircle(
                    initial: name.isNotEmpty ? name[0].toUpperCase() : '?'),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: p.text)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text(
                            L.ratingJobs(rating.toStringAsFixed(1), jobs),
                            style: AppTypography.bodySmall(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child:
                      Icon(b.service.icon, color: AppColors.accent, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if ((b.note ?? '').isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(
                      left: BorderSide(color: AppColors.accent, width: 3)),
                ),
                child: Text(b.note!,
                    style:
                        AppTypography.body(context).copyWith(height: 1.35)),
              ),
              const SizedBox(height: 14),
            ],
            // Meta chips: when · service length · distance. Wrap so longer
            // localized date/distance text can flow onto a second line instead
            // of overflowing on narrow screens.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  icon: Icons.schedule_rounded,
                  text: DateFormat('EEE d MMM · HH:mm').format(b.dateTime),
                ),
                _Chip(
                  icon: Icons.timer_outlined,
                  text: b.service.formattedDuration,
                ),
                _Chip(
                  icon: Icons.near_me_rounded,
                  text: L.kmAway(km.toStringAsFixed(1)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Estimated pay.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.estimatedPay,
                      style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: const Color(0xFF177A48))),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Money.som(b.service.price),
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF137A45)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Actions.
            Row(
              children: [
                Expanded(
                  child: _Btn(
                    label: L.decline,
                    filled: false,
                    onTap: () => _finish(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _Btn(
                    label: L.acceptBooking,
                    icon: Icons.arrow_forward_rounded,
                    filled: true,
                    onTap: () => _finish(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingRequestSheet extends StatefulWidget {
  const _IncomingRequestSheet({required this.req});
  final IncomingRequest req;

  @override
  State<_IncomingRequestSheet> createState() => _IncomingRequestSheetState();
}

class _IncomingRequestSheetState extends State<_IncomingRequestSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _respondSeconds),
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish(false);
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _finish(bool accept) {
    if (_done) return;
    _done = true;
    if (accept) {
      HapticFeedback.mediumImpact();
      AppState.instance.acceptIncoming();
    } else {
      AppState.instance.declineIncoming();
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final req = widget.req;
    final b = req.booking;
    final name = b.clientName ?? L.youWord;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, -8)),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 18 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + countdown ring.
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: const Text('!',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(L.newBookingRequest,
                      style: AppTypography.h3(context)),
                ),
                _CountdownRing(controller: _c),
              ],
            ),
            const SizedBox(height: 18),
            // Client.
            Row(
              children: [
                _Squircle(initial: name.isNotEmpty ? name[0].toUpperCase() : '?'),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: p.text)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text(
                            L.ratingJobs(
                                req.rating.toStringAsFixed(1), req.jobs),
                            style: AppTypography.bodySmall(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(b.service.icon, color: AppColors.accent, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Note.
            if ((b.note ?? '').isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(
                      left: BorderSide(color: AppColors.accent, width: 3)),
                ),
                child: Text(b.note!,
                    style: AppTypography.body(context)
                        .copyWith(height: 1.35)),
              ),
            const SizedBox(height: 14),
            // Meta chips.
            Row(
              children: [
                Flexible(
                  child: _Chip(
                    icon: Icons.location_on_rounded,
                    text: b.barbershop.address,
                  ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.schedule_rounded,
                  text: DateFormat('HH:mm').format(b.dateTime),
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.near_me_rounded,
                  text: L.kmAway(req.distanceKm.toStringAsFixed(1)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Estimated pay.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(L.estimatedPay,
                            style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: const Color(0xFF177A48))),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Money.som(b.service.price),
                            maxLines: 1,
                            softWrap: false,
                            style: GoogleFonts.nunito(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF137A45)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (req.urgent) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(L.urgentWord,
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Actions.
            Row(
              children: [
                Expanded(
                  child: _Btn(
                    label: L.decline,
                    filled: false,
                    onTap: () => _finish(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _Btn(
                    label: L.acceptBooking,
                    icon: Icons.arrow_forward_rounded,
                    filled: true,
                    onTap: () => _finish(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final remaining = (_respondSeconds * (1 - controller.value)).ceil();
        final low = remaining <= 5;
        final color = low ? AppColors.red : AppColors.accent;
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: 1 - controller.value,
                  strokeWidth: 4,
                  backgroundColor: p.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text('$remaining',
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ],
          ),
        );
      },
    );
  }
}

class _Squircle extends StatelessWidget {
  const _Squircle({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F9CFF), AppColors.accentDeep],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(initial,
          style: GoogleFonts.nunito(
              fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: p.cardAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatefulWidget {
  const _Btn({
    required this.label,
    required this.filled,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool filled;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
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
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.accent : p.cardAlt,
            borderRadius: BorderRadius.circular(17),
            boxShadow: filled
                ? [
                    BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.34),
                        blurRadius: 16,
                        offset: const Offset(0, 7)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.label,
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: filled ? Colors.white : p.textSecondary)),
              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                Icon(widget.icon, size: 18, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
