import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format/money.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/app_state.dart';
import 'paper_kit.dart';

/// States the cancellation policy in plain language with the concrete fee for
/// this service in so'm. Gold "shield" surface — it protects the barber's time
/// while making the terms honest and unmissable at booking.
class CancellationPolicyCard extends StatelessWidget {
  const CancellationPolicyCard({super.key, required this.servicePriceUsd});
  final double servicePriceUsd;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final policy = AppState.instance.cancellationPolicy;
    final fee = Money.som(policy.feeUsd(servicePriceUsd));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: clayDecoration(p, radius: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_user_rounded,
                size: 20, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.policyTitle, style: AppTypography.h4(context)),
                const SizedBox(height: 6),
                _line(context, Icons.check_circle_rounded, L.policyFreeUntil,
                    AppColors.green),
                const SizedBox(height: 4),
                _line(context, Icons.schedule_rounded, L.policyFeeLine,
                    p.textSecondary),
                const SizedBox(height: 6),
                Text(L.policyFeeAmount(fee),
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTypography.bodySmall(context))),
      ],
    );
  }
}
