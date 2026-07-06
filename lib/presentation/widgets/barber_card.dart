import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/barber.dart';
import 'paper_kit.dart';

/// A barber as a row card — crayon avatar, bold name, lime rating.
class BarberCard extends StatelessWidget {
  const BarberCard({
    super.key,
    required this.barber,
    required this.index,
    this.subtitle,
    this.isMyBarber = false,
    this.onTap,
  });

  final Barber barber;
  final int index;
  final String? subtitle;
  final bool isMyBarber;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return PaperCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          InitialAvatar(name: barber.name, size: 52, index: index),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        barber.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h4(context),
                      ),
                    ),
                    if (isMyBarber) ...[
                      const SizedBox(width: 6),
                      MiniPill(L.wdMyBarber),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? barber.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(context),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    MiniPill(
                      '★ ${barber.rating.toStringAsFixed(1)}',
                      style: MiniPillStyle.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      L.wdYearsReviews(
                          barber.yearsExperience, barber.reviewCount),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: p.textTertiary,
          ),
        ],
      ),
    );
  }
}
