import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format/money.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/app_state.dart';
import '../../data/models/booking.dart';
import 'primary_button.dart';

/// Shown when a client tries to cancel INSIDE the 4-hour window. It surfaces the
/// 50% fee honestly and, on accept, cancels via the policy-aware path. Returns
/// true if the booking was cancelled.
Future<bool> showLateCancelSheet(BuildContext context, Booking booking) async {
  final res = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LateCancelSheet(booking: booking),
  );
  return res ?? false;
}

class _LateCancelSheet extends StatelessWidget {
  const _LateCancelSheet({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final policy = AppState.instance.cancellationPolicy;
    final fee = Money.som(policy.feeUsd(booking.service.price));
    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          22, 12, 22, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.timelapse_rounded,
                    size: 22, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(L.lateCancelTitle,
                    style: AppTypography.h2(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(L.lateCancelBody, style: AppTypography.bodySmall(context)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    size: 18, color: AppColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(L.policyFeeAmount(fee),
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: p.text,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: L.keepIt,
            icon: Icons.favorite_rounded,
            style: PrimaryButtonStyle.lime,
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop(false);
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                AppState.instance.cancelBookingWithPolicy(booking.id);
                Navigator.of(context).pop(true);
              },
              child: Text(
                L.cancelAndPayFee(fee),
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
