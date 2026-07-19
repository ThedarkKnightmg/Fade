import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// A flat filter pill — the app's standard row filter (Home + Explore).
/// Selected = accent fill; idle = a quiet tonal chip with a hairline. No drop
/// shadow, so a row of them settles instead of floating. A gentle scale-pop
/// marks the selection.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Optional leading glyph — makes each filter recognisable at a glance
  /// (⭐ featured, 📍 nearby, ❤ saved…) instead of a plain word.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.97,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(icon != null ? 12 : 16, 9, 16, 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : p.cardAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.accent : p.border,
            ),
            // A soft accent glow lifts the SELECTED chip out of the row.
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      blurRadius: 12,
                      spreadRadius: -3,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  // Idle icons carry a touch of accent so the row isn't a wall
                  // of grey; selected goes white to sit on the fill.
                  color: selected ? Colors.white : AppColors.accent,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter chip with a count badge — "All Notes (26)" style.
/// Active: ink pill, white text, lime count bubble.
/// Idle: white pill, hairline border, grey count.
class CountChip extends StatelessWidget {
  const CountChip({
    super.key,
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(18, 10, count == null ? 18 : 8, 10),
        decoration: BoxDecoration(
          color: selected ? p.action : p.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : p.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? p.onAction : p.text,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : p.cardAlt,
                  shape: BoxShape.circle,
                  border: selected
                      ? null
                      : Border.all(color: p.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.ink : p.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
