import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar_link.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// The client's "Booking Ticket": a dynamic QR the barber scans at the chair to
/// verify the visit (locking their commission). Refreshes every 30s. The
/// scan-streak toward VIP is ZERO-COST — it never grants a free/discounted cut.
class BookingTicketScreen extends StatelessWidget {
  const BookingTicketScreen({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final visits = s.loyaltyVisits; // the ONE shared loyalty metric
          final atVip = visits >= AppState.vipStreakGoal;
          final progress = (visits / AppState.vipStreakGoal).clamp(0.0, 1.0);
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(L.bookingTicket, style: AppTypography.h2(context)),
                  ],
                ),
                const SizedBox(height: 18),
                // The QR on a bright card.
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _TicketQr(bookingId: booking.id, size: 220),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.autorenew_rounded,
                                size: 13, color: Color(0xFF8A94A6)),
                            const SizedBox(width: 5),
                            Text(L.ticketRefreshHint,
                                style: GoogleFonts.nunito(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8A94A6),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(L.showAtCounter,
                      style: AppTypography.bodySmall(context)),
                ),
                const SizedBox(height: 18),
                // Booking details.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: clayDecoration(p, radius: 22),
                  child: Column(
                    children: [
                      _Row(
                          icon: Icons.person_outline_rounded,
                          label: L.barberLabel,
                          value: booking.barber.name),
                      const SizedBox(height: 10),
                      _Row(
                          icon: Icons.content_cut_rounded,
                          label: L.serviceLabel,
                          value: L.tr(booking.service.name)),
                      const SizedBox(height: 10),
                      _Row(
                          icon: Icons.event_rounded,
                          label: L.whenLabel,
                          value: DateFormat('EEE, d MMM · HH:mm')
                              .format(booking.dateTime)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Zero-cost scan-streak toward VIP.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: clayDecoration(p, radius: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(atVip ? Icons.workspace_premium_rounded : Icons.qr_code_scanner_rounded,
                              size: 18, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              atVip
                                  ? L.vipUnlockedTitle
                                  : L.vipProgressLine(
                                      visits, AppState.vipStreakGoal),
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: p.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: p.border,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.gold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(L.vipPerkSub,
                          style: AppTypography.caption(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: p.textTertiary),
                    const SizedBox(width: 6),
                    Text(L.noShowCaution,
                        style: AppTypography.caption(context)),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: L.addToCalendar,
                  icon: Icons.calendar_month_rounded,
                  height: 54,
                  style: PrimaryButtonStyle.ghost,
                  onPressed: () => addBookingToCalendar(context, booking),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 12),
        Text(label, style: AppTypography.caption(context)),
        const Spacer(),
        Flexible(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: p.text,
              )),
        ),
      ],
    );
  }
}

/// A REAL, scannable ticket QR. Encodes `fade:ticket:<bookingId>:<slice>`
/// where the slice advances every 30s — so the refresh promise is genuine and
/// a stale screenshot ages out.
class _TicketQr extends StatefulWidget {
  const _TicketQr({required this.bookingId, required this.size});
  final String bookingId;
  final double size;

  @override
  State<_TicketQr> createState() => _TicketQrState();
}

class _TicketQrState extends State<_TicketQr> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Re-encode on each 30s boundary.
    _timer = Timer.periodic(
        const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slice = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    return QrImageView(
      data: 'fade:ticket:${widget.bookingId}:$slice',
      version: QrVersions.auto,
      size: widget.size,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.circle,
        color: Color(0xFF1B2430),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.circle,
        color: Color(0xFF1B2430),
      ),
    );
  }
}
