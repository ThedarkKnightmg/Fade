import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

// ============================================================
// The paper kit — small signature pieces shared by every screen.
// ============================================================

/// The shared **claymorphism** surface: a puffy tile with a top-left sheen,
/// a big soft ambient shadow, and a light highlight. Used by [PaperCard], the
/// home tiles, and any bespoke surface that wants the clay look — so the whole
/// app stays consistent.
BoxDecoration clayDecoration(
  PaperPalette p, {
  Color? color,
  double radius = 28,
  Color? borderColor,
  double depth = 1,
}) {
  final base = color ?? p.card;
  // Three-stop diagonal: a lit top-left sheen, the body, and a soft bottom-right
  // lowlight — the extra stop is what reads as a rounded, moulded clay surface.
  final sheen = Color.lerp(base, Colors.white, p.isDark ? 0.05 : 0.22)!;
  final lowlight = Color.lerp(base, Colors.black, p.isDark ? 0.11 : 0.05)!;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [sheen, base, lowlight],
      stops: const [0.0, 0.55, 1.0],
    ),
    borderRadius: BorderRadius.circular(radius),
    border:
        borderColor != null ? Border.all(color: borderColor, width: 1.4) : null,
    boxShadow: [
      // Big soft ambient shadow (bottom-right) — the clay pop.
      BoxShadow(
        color: p.shadow,
        blurRadius: 34 * depth,
        spreadRadius: -3,
        offset: Offset(0, 15 * depth),
      ),
      // Top-left highlight — lit from above, a touch stronger so it feels puffy.
      BoxShadow(
        color: p.clayLight,
        blurRadius: 18,
        spreadRadius: -1,
        offset: const Offset(-8, -9),
      ),
    ],
  );
}

/// The wordmark.
class BarberLogo extends StatelessWidget {
  const BarberLogo({super.key, this.size = 30, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'FADE',
      style: AppTypography.logo(context, size: size).copyWith(color: color),
    );
  }
}

/// Blue marker stroke behind a run of text (wraps across lines).
InlineSpan markerSpan(
  String text,
  TextStyle style, {
  Color color = AppColors.accent,
}) {
  return TextSpan(
    text: text,
    style: style.copyWith(
      background: Paint()..color = color,
      color: AppColors.ink,
    ),
  );
}

/// Blue marker box with padding + rounded corners (single-line phrases).
InlineSpan markerBoxSpan(
  String text,
  TextStyle style, {
  Color color = AppColors.accent,
  EdgeInsets padding = const EdgeInsets.fromLTRB(8, 1, 8, 3),
}) {
  return WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: style.copyWith(color: AppColors.ink)),
    ),
  );
}

/// White card with hairline border — the "note" every block sits on.
class PaperCard extends StatefulWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 28,
    this.color,
    this.borderColor,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends State<PaperCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final card = Container(
      decoration: clayDecoration(
        p,
        color: widget.color,
        radius: widget.radius,
        borderColor: widget.borderColor,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.radius),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(widget.radius),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );

    // Tappable cards get a subtle press-dip (the InkWell still ripples). A
    // passive Listener tracks the press without competing in the gesture arena.
    if (widget.onTap == null && widget.onLongPress == null) return card;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: (_pressed && !reduce) ? 0.975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

/// Circular icon button — white with hairline border, or filled ink.
class CircleBtn extends StatelessWidget {
  const CircleBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 46,
    this.filled = false,
    this.fillColor,
    this.iconColor,
    this.iconSize,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool filled;
  final Color? fillColor;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final bg = fillColor ?? (filled ? p.action : p.card);
    final fg = iconColor ?? (filled ? p.onAction : p.text);
    return Material(
      color: bg,
      elevation: 6,
      shadowColor: p.shadow,
      shape: CircleBorder(
        side: filled || fillColor != null
            ? BorderSide.none
            : BorderSide(color: p.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize ?? size * 0.46, color: fg),
        ),
      ),
    );
  }
}

/// Black circle with a white ↗ — the "open it" affordance.
class ArrowCircle extends StatelessWidget {
  const ArrowCircle({super.key, this.onTap, this.size = 44});

  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleBtn(
      icon: Icons.arrow_outward_rounded,
      onTap: onTap,
      size: size,
      filled: true,
      fillColor: AppColors.ink,
      iconColor: const Color(0xFFF6F4EE),
    );
  }
}

/// Circular checkbox — blue when checked.
class RoundCheck extends StatelessWidget {
  const RoundCheck({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 26,
    this.color = AppColors.blue,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final borderColor = Color.lerp(p.border, p.textTertiary, 0.5)!;
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? color : p.card,
          border: value ? null : Border.all(color: borderColor, width: 1.6),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          scale: value ? 1 : 0,
          child: Icon(
            Icons.check_rounded,
            size: size * 0.62,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Avatar: a blue-toned circle (or rounded square) with an initial.
/// No photos anywhere — paper world.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.index = 0,
    this.square = false,
    this.color,
  });

  final String name;
  final double size;
  final int index;
  final bool square;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? Paper.crayon(index),
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(size * 0.32) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.nunito(
          fontSize: size * 0.44,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// Tiny tag pill: accent, ink, or ghost.
enum MiniPillStyle { accent, ink, ghost, gold }

class MiniPill extends StatelessWidget {
  const MiniPill(
    this.text, {
    super.key,
    this.style = MiniPillStyle.accent,
    this.icon,
  });

  final String text;
  final MiniPillStyle style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final (bg, fg, border) = switch (style) {
      MiniPillStyle.accent => (AppColors.accent, AppColors.ink, null),
      MiniPillStyle.ink => (p.action, p.onAction, null),
      MiniPillStyle.ghost => (Colors.transparent, p.textSecondary, p.border),
      MiniPillStyle.gold => (AppColors.gold, AppColors.ink, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// A quiet centered side note.
class ScribbleNote extends StatelessWidget {
  const ScribbleNote(this.text, {super.key, this.size = 22});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.scribble(context, size: size),
    );
  }
}

/// Light diagonal grid — sketchbook paper texture (used by the map).
class SketchGridPainter extends CustomPainter {
  const SketchGridPainter({required this.color, this.gap = 42});

  final Color color;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final n = ((size.width + size.height) / gap).ceil();
    for (var i = 0; i <= n; i++) {
      final d = i * gap;
      // ↘ diagonals
      canvas.drawLine(Offset(d - size.height, 0), Offset(d, size.height), paint);
      // ↙ diagonals
      canvas.drawLine(
        Offset(size.width - d + size.height, 0),
        Offset(size.width - d, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SketchGridPainter old) =>
      old.color != color || old.gap != gap;
}
