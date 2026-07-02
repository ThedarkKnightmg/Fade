import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

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
