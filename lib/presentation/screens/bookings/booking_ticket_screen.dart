import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar_link.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../barber/qr_scanner_screen.dart';
import '../game/games_sheet.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// The client's "Booking Ticket" / check-in screen. Flipped model: the BARBER
/// shows a QR and the client scans it here to confirm the visit (locking the
/// barber's commission). The scan-streak toward VIP is ZERO-COST — it never
/// grants a free/discounted cut.
class BookingTicketScreen extends StatelessWidget {
  const BookingTicketScreen({super.key, required this.booking});
  final Booking booking;

  /// Open the camera, scan the barber's QR, and — if it's the barber on THIS
  /// booking — run the check-in handshake.
  Future<void> _checkIn(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final raw = await Navigator.of(context).push<String>(
      FadeThroughPageRoute(
          child: QrScannerScreen(
              title: L.checkInScanTitle, hint: L.checkInScanHint)),
    );
    if (raw == null || !context.mounted) return;
    final barberId = AppState.barberIdFromQr(raw);
    if (barberId == null) {
      _toast(messenger, L.checkInNotBarberQr);
      return;
    }
    if (barberId != booking.barber.id) {
      _toast(messenger, L.checkInWrongBarber);
      return;
    }
    HapticFeedback.mediumImpact();
    final blocked = AppState.instance.verifyAndComplete(booking.id);
    if (!context.mounted) return;
    if (blocked == null) {
      _toast(messenger, L.checkedInOk);
      Navigator.of(context).maybePop();
    } else {
      _toast(
          messenger,
          blocked == 'early'
              ? L.scanTooEarly
              : blocked == 'credit'
                  ? L.checkInTryLater
                  : L.scanAlreadyDone);
    }
  }

  void _toast(ScaffoldMessengerState m, String msg) {
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final visits = s.fadePoints; // THE Fade-points number, shown app-wide
          final atVip = visits >= AppState.fadePointsGoal;
          final progress = (visits / AppState.fadePointsGoal).clamp(0.0, 1.0);
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
                    Expanded(
                      child: Text(L.bookingTicket,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h2(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // The client SHOWS this QR; the barber scans it to complete the
                // visit server-side (minting points). A "checked in" state once
                // done. The scan-the-barber's-code path stays as a fallback.
                if (booking.verifiedAt == null &&
                    booking.status != BookingStatus.completed)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: s.bookingQrPayload(booking),
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: AppColors.accentDeep,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: Color(0xFF16213A),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                _CheckInCard(
                  checkedIn: booking.verifiedAt != null ||
                      booking.status == BookingStatus.completed,
                  onScan: () => _checkIn(context),
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
                    Expanded(
                      child: Text(L.noShowCaution,
                          style: AppTypography.caption(context)),
                    ),
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
                const SizedBox(height: 10),
                // This screen is what's open while you sit in the shop waiting
                // to be called, so it's where the wait actually happens — and
                // where a 40-second game belongs.
                PrimaryButton(
                  label: '${L.gamesTitle} · ${L.gameKillTime}',
                  icon: Icons.sports_esports_rounded,
                  height: 54,
                  style: PrimaryButtonStyle.ghost,
                  onPressed: () => showGamesSheet(context),
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

/// The check-in card: a prompt to scan the barber's QR, or a "checked in"
/// confirmation once the visit is verified.
class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.checkedIn, required this.onScan});
  final bool checkedIn;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    if (checkedIn) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded,
                size: 30, color: AppColors.green),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.checkedInTitle, style: AppTypography.h3(context)),
                  const SizedBox(height: 2),
                  Text(L.checkedInSub,
                      style: AppTypography.bodySmall(context)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                size: 32, color: AppColors.accent),
          ),
          const SizedBox(height: 14),
          Text(L.checkInPromptTitle,
              textAlign: TextAlign.center, style: AppTypography.h3(context)),
          const SizedBox(height: 4),
          Text(L.checkInPromptSub,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(context)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: L.checkInScanCta,
            icon: Icons.qr_code_scanner_rounded,
            height: 54,
            onPressed: onScan,
          ),
        ],
      ),
    );
  }
}
