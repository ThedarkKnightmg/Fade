import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format/money.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/app_state.dart';

/// The card-on-file AUTHORIZATION intent sheet. It is a HOLD, not a charge, and
/// it takes NO card data — a real provider (Payme/Click/Stripe) owns the
/// authorization; here we only record that a hold exists via a stub.
Future<void> showCardOnFileSheet(
  BuildContext context, {
  required double amountUsd,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CardOnFileSheet(amountUsd: amountUsd),
  );
}

class _CardOnFileSheet extends StatelessWidget {
  const _CardOnFileSheet({required this.amountUsd});
  final double amountUsd;

  static const _providers = ['Payme', 'Click', 'Stripe'];

  Future<void> _authorize(BuildContext context, String provider) async {
    await AppState.instance.authorizeCardOnFile(provider);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(L.cardOnFileAdded),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
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
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.lock_rounded,
                    size: 22, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(L.cardOnFileTitle,
                    style: AppTypography.h2(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(L.cardOnFileBody, style: AppTypography.bodySmall(context)),
          const SizedBox(height: 14),
          // "It's a hold, not a charge" reassurance chip.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded,
                    size: 16, color: AppColors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${L.itsAHoldNotCharge} · ${Money.som(amountUsd)}',
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final prov in _providers) ...[
            _ProviderButton(
              provider: prov,
              onTap: () => _authorize(context, prov),
            ),
            const SizedBox(height: 10),
          ],
          Center(
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
              },
              child: Text(L.maybeLater,
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.textSecondary,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({required this.provider, required this.onTap});
  final String provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  size: 20, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(L.continueWithProvider(provider),
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: p.text,
                    )),
              ),
              Icon(Icons.chevron_right_rounded, color: p.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
