import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'qr_scanner_screen.dart';

/// Barber "Check-in": the barber SHOWS this QR and the client scans it to
/// confirm the visit (flipped from the old model where the barber scanned the
/// client). The client's scan runs the verified handshake and locks the
/// commission. Today's bookings and the overdue no-show fail-safe live here
/// too, since this is where the barber manages the chair at the moment of
/// service. A manual tap-to-check-in remains as a fallback (client's phone
/// dead, etc.).
Future<void> showCheckInSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CheckInSheet(),
  );
}

class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet();

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  String? _verifyingId;

  /// Open the camera, scan a client's booking-ticket QR, and complete it on the
  /// server (which mints the client's points + any referral, verifying we're the
  /// assigned barber). Falls back to the local handshake for demo/offline.
  Future<void> _scanTicket() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final raw = await navigator.push<String>(
      FadeThroughPageRoute(
          child: QrScannerScreen(title: L.scanClient, hint: L.scanPointHint)),
    );
    if (raw == null || !mounted) return;
    final id = AppState.bookingIdFromQr(raw);
    if (id == null) {
      messenger.showSnackBar(SnackBar(content: Text(L.checkInNotBarberQr)));
      return;
    }
    HapticFeedback.mediumImpact();
    final earned = await AppState.instance.completeScannedBooking(id);
    if (!mounted) return;
    navigator.maybePop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(earned != null && earned > 0
            ? '${L.verifiedCheckedIn} · ${L.pointsEarnedToast(earned)}'
            : L.verifiedCheckedIn),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _verify(Booking b) async {
    setState(() => _verifyingId = b.id);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    final blocked = AppState.instance.verifyAndComplete(b.id);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(blocked == null
            ? '${L.verifiedCheckedIn} · ${L.commissionCharged}'
            : blocked == 'early'
                ? L.scanTooEarly
                : blocked == 'credit'
                    ? L.scanNeedTopUp
                    : L.scanAlreadyDone),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _noShow(Booking b) {
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();
    AppState.instance.markNoShow(b.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(L.markNoShowNoFee),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final scannable = s.todayScannable;
        final overdue = s.overdueBookings();
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86),
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 16 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded,
                      size: 22, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Text(L.checkInTitle, style: AppTypography.h2(context)),
                ],
              ),
              const SizedBox(height: 14),
              // Primary path: scan the client's ticket → server completion.
              PrimaryButton(
                label: L.scanClient,
                icon: Icons.qr_code_scanner_rounded,
                height: 52,
                onPressed: _scanTicket,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // The barber's QR — the client scans THIS to check in.
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
                          data: s.barberCheckInPayload,
                          size: 208,
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
                    const SizedBox(height: 12),
                    Center(
                      child: Text(L.checkInShowHint,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(context)),
                    ),
                    const SizedBox(height: 22),
                    Text(L.scanTodayTitle, style: AppTypography.h4(context)),
                    const SizedBox(height: 10),
                    if (scannable.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(L.scanEmpty,
                            style: AppTypography.bodySmall(context)),
                      )
                    else
                      for (final b in scannable)
                        _ScanRow(
                          booking: b,
                          verifying: _verifyingId == b.id,
                          onTap: _verifyingId == null ? () => _verify(b) : null,
                        ),
                    if (overdue.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 18, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Text(L.overdueTitle,
                              style: AppTypography.h4(context)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final b in overdue)
                        _OverdueRow(booking: b, onNoShow: () => _noShow(b)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A today's booking — tap to check in manually (fallback when the client
/// can't scan). The primary path is the client scanning the QR above.
class _ScanRow extends StatelessWidget {
  const _ScanRow(
      {required this.booking, required this.verifying, required this.onTap});
  final Booking booking;
  final bool verifying;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              InitialAvatar(name: booking.clientName ?? 'Client', size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.clientName ?? 'Client',
                        style: AppTypography.h4(context)),
                    Text(
                        '${DateFormat('HH:mm').format(booking.dateTime)} · ${L.tr(booking.service.name)}',
                        style: AppTypography.caption(context)),
                  ],
                ),
              ),
              if (verifying)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: AppColors.accent),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: p.cardAlt,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(L.checkInManual,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: p.textSecondary,
                      )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverdueRow extends StatelessWidget {
  const _OverdueRow({required this.booking, required this.onNoShow});
  final Booking booking;
  final VoidCallback onNoShow;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.clientName ?? 'Client',
                      style: AppTypography.h4(context)),
                  Text(
                      '${DateFormat('HH:mm').format(booking.dateTime)} · ${L.tr(booking.service.name)}',
                      style: AppTypography.caption(context)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onNoShow,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: p.border),
                ),
                child: Text(L.markNoShowNoFee,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: p.textSecondary,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
