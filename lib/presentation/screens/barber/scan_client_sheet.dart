import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/animations/app_animations.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'qr_scanner_screen.dart';

/// Barber "Scan Client": the verified handshake. Picking today's client
/// simulates scanning their QR → completes the booking and locks the commission
/// (real cross-device camera scan = hardware/backend). Overdue, unscanned
/// bookings surface here for the no-show fail-safe.
Future<void> showScanClientSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ScanClientSheet(),
  );
}

class _ScanClientSheet extends StatefulWidget {
  const _ScanClientSheet();

  @override
  State<_ScanClientSheet> createState() => _ScanClientSheetState();
}

class _ScanClientSheetState extends State<_ScanClientSheet> {
  String? _verifyingId;

  Future<void> _verify(Booking b) async {
    setState(() => _verifyingId = b.id);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    AppState.instance.verifyAndComplete(b.id);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${L.verifiedCheckedIn} · ${L.commissionCharged}'),
        behavior: SnackBarBehavior.floating,
      ));
  }

  /// Open the real camera scanner. A decoded QR of the form
  /// `fade:ticket:<bookingId>:<slice>` verifies that booking; any other code is
  /// rejected with a hint.
  Future<void> _openCamera() async {
    final messenger = ScaffoldMessenger.of(context);
    final raw = await Navigator.of(context).push<String>(
      FadeThroughPageRoute(child: const QrScannerScreen()),
    );
    if (raw == null || !mounted) return;
    // Extract a booking id from `fade:ticket:<id>:<slice>`.
    String? bookingId;
    final parts = raw.split(':');
    if (parts.length >= 3 && parts[0] == 'fade' && parts[1] == 'ticket') {
      bookingId = parts[2];
    }
    final scannable = AppState.instance.todayScannable;
    Booking? match;
    for (final b in scannable) {
      if (b.id == bookingId) {
        match = b;
        break;
      }
    }
    if (match != null) {
      await _verify(match);
    } else {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(bookingId == null ? L.scanNotTicket : L.scanEmpty),
          behavior: SnackBarBehavior.floating,
        ));
    }
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
              maxHeight: MediaQuery.of(context).size.height * 0.8),
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
                  const Icon(Icons.qr_code_scanner_rounded,
                      size: 22, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Text(L.scanClient, style: AppTypography.h2(context)),
                ],
              ),
              const SizedBox(height: 16),
              // Open the REAL camera scanner.
              PrimaryButton(
                label: L.scanOpenCamera,
                icon: Icons.qr_code_scanner_rounded,
                height: 54,
                onPressed: _openCamera,
              ),
              const SizedBox(height: 18),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
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
                        '${DateFormat('HH:mm').format(booking.dateTime)} · ${booking.service.name}',
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
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded,
                          size: 15, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(L.scanClient,
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          )),
                    ],
                  ),
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
                      '${DateFormat('HH:mm').format(booking.dateTime)} · ${booking.service.name}',
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
