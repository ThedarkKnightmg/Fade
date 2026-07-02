import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';

/// Two rating chips side by side — barber talent (gold) and shop (blue) — so
/// the two axes always read distinctly. A brand-new subject shows "New".
class DualRatingRow extends StatelessWidget {
  const DualRatingRow({
    super.key,
    required this.barberStars,
    required this.barberCount,
    required this.shopStars,
    required this.shopCount,
  });

  final double barberStars;
  final int barberCount;
  final double shopStars;
  final int shopCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _RatingChip(
            label: L.talentRating,
            stars: barberStars,
            count: barberCount,
            color: AppColors.gold),
        _RatingChip(
            label: L.shopRatingWord,
            stars: shopStars,
            count: shopCount,
            color: AppColors.accent),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.label,
    required this.stars,
    required this.count,
    required this.color,
  });
  final String label;
  final double stars;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isNew = count == 0 && stars == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: color),
          const SizedBox(width: 3),
          Text(isNew ? L.newWord : stars.toStringAsFixed(1),
              style: GoogleFonts.nunito(
                  fontSize: 12.5, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

/// A tappable 1–5 star input, tinted per axis (gold = talent, blue = shop).
class StarInput extends StatelessWidget {
  const StarInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.color = AppColors.gold,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 32,
                color: i <= value ? color : color.withValues(alpha: 0.3),
              ),
            ),
          ),
      ],
    );
  }
}
