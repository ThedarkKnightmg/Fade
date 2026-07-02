import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum PrimaryButtonStyle { ink, lime, ghost }

/// The big pill button. Ink-black by default ("Get started"),
/// lime for the loudest moments, ghost for secondary actions.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = PrimaryButtonStyle.ink,
    this.icon,
    this.height = 60,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final PrimaryButtonStyle style;
  final IconData? icon;
  final double height;
  final bool expanded;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final (bg, fg, border) = switch (widget.style) {
      PrimaryButtonStyle.ink => (p.action, p.onAction, null),
      PrimaryButtonStyle.lime => (AppColors.accent, AppColors.ink, null),
      PrimaryButtonStyle.ghost => (Colors.transparent, p.text, p.border),
    };

    return GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.97 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: widget.onPressed == null ? 0.45 : 1,
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border:
                  border == null ? null : Border.all(color: border, width: 1.4),
              // Puffy clay pop — a soft, colour-matched shadow beneath. Ghost
              // buttons stay flat. Fades out while pressed (compressed clay).
              boxShadow: (widget.style == PrimaryButtonStyle.ghost ||
                      widget.onPressed == null)
                  ? null
                  : [
                      BoxShadow(
                        color: bg.withValues(alpha: _pressed ? 0.18 : 0.42),
                        blurRadius: _pressed ? 8 : 18,
                        spreadRadius: -1,
                        offset: Offset(0, _pressed ? 3 : 9),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize:
                  widget.expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.button(context, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
