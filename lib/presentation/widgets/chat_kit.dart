import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';

/// Telegram brand blues.
const _tgTop = Color(0xFF2AABEE);
const _tgBottom = Color(0xFF229ED9);

/// The Telegram paper-plane logo — the official plane in a blue gradient disc.
/// Used in the Chats header to signal the Telegram-style messaging.
class TelegramMark extends StatelessWidget {
  const TelegramMark({super.key, this.size = 30});

  final double size;

  // The classic Telegram plane, white on the gradient disc.
  static const String _plane = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
<path fill="#ffffff" d="M9.04 15.9l-.37 4.06c.5 0 .72-.22.98-.48l2.36-2.25 4.9 3.58c.9.5 1.54.24 1.78-.83l3.23-15.13h.01c.28-1.34-.48-1.86-1.36-1.53L1.13 9.5C-.18 10.01-.16 10.75.9 11.08l4.98 1.55L18.4 5.1c.5-.33.96-.15.58.19"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_tgTop, _tgBottom],
        ),
      ),
      padding: EdgeInsets.all(size * 0.22),
      child: SvgPicture.string(_plane),
    );
  }
}

/// A soft, Telegram-style chat wallpaper: a gentle tinted ground with a faint
/// repeating doodle so the bubbles sit on texture, not flat colour.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // A cool tint in light mode, deep navy in dark — echoing Telegram's default
    // wallpaper without copying its exact art.
    final base = p.isDark ? const Color(0xFF0E1621) : const Color(0xFFD9E6F2);
    return DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: CustomPaint(
        painter: _DoodlePainter(
          tint: (p.isDark ? Colors.white : const Color(0xFF7FA8CC))
              .withValues(alpha: p.isDark ? 0.035 : 0.10),
        ),
        child: child,
      ),
    );
  }
}

/// A faint scattered pattern (soft rings + plus marks) — barely-there texture,
/// the way Telegram's wallpaper reads from a distance.
class _DoodlePainter extends CustomPainter {
  _DoodlePainter({required this.tint});

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const step = 66.0;
    for (double y = 20; y < size.height + step; y += step) {
      for (double x = 16; x < size.width + step; x += step) {
        // Stagger every other row and alternate ring / plus.
        final off = ((y ~/ step) % 2) * step / 2;
        final cx = x + off;
        final odd = ((x ~/ step) + (y ~/ step)) % 2 == 0;
        if (odd) {
          canvas.drawCircle(Offset(cx, y), 9, paint);
        } else {
          canvas.drawLine(Offset(cx - 7, y), Offset(cx + 7, y), paint);
          canvas.drawLine(Offset(cx, y - 7), Offset(cx, y + 7), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => old.tint != tint;
}

/// A Telegram-style message bubble — coloured fill with a small tail on the
/// sender's side, the text, and an inline time + double-tick footer tucked into
/// the bottom-right (blue "mine", white incoming).
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.mine,
    required this.at,
  });

  final String text;
  final bool mine;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // Outgoing = the app's blue (near-identical to Telegram's); incoming =
    // white card in light, slate in dark.
    final bubbleColor = mine
        ? AppColors.accent
        : (p.isDark ? const Color(0xFF182533) : Colors.white);
    final textColor = mine ? Colors.white : p.text;
    final metaColor =
        mine ? Colors.white.withValues(alpha: 0.75) : p.textTertiary;

    final time = DateFormat('HH:mm').format(at);
    final screenW = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 3,
        left: mine ? 60 : 8,
        right: mine ? 8 : 60,
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenW * 0.78),
          child: CustomPaint(
            painter: _BubbleBg(color: bubbleColor, mine: mine),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  mine ? 13 : 15, 7, mine ? 15 : 13, 7),
              // Stack lets the time float into the bottom-right, Telegram-style,
              // while the text reserves room for it on its last line.
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 46, bottom: 1),
                    child: Text(
                      text,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.28,
                        color: textColor,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: metaColor,
                          ),
                        ),
                        if (mine) ...[
                          const SizedBox(width: 3),
                          // Double tick — "read".
                          Icon(Icons.done_all_rounded,
                              size: 15, color: metaColor),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the bubble fill: a rounded rectangle with the tail-side bottom corner
/// squared off and a small tail flicking out — the Telegram silhouette.
class _BubbleBg extends CustomPainter {
  _BubbleBg({required this.color, required this.mine});

  final Color color;
  final bool mine;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final w = size.width;
    final h = size.height;
    const r = Radius.circular(16);
    const rSmall = Radius.circular(5);

    final body = RRect.fromLTRBAndCorners(
      0, 0, w, h,
      topLeft: r,
      topRight: r,
      bottomLeft: mine ? r : rSmall,
      bottomRight: mine ? rSmall : r,
    );
    final path = Path()..addRRect(body);

    // The little tail at the sender-side bottom corner.
    final tail = Path();
    if (mine) {
      tail
        ..moveTo(w - 9, h)
        ..quadraticBezierTo(w, h + 1, w + 5, h - 1)
        ..quadraticBezierTo(w - 1, h - 3, w - 2, h - 9)
        ..close();
    } else {
      tail
        ..moveTo(9, h)
        ..quadraticBezierTo(0, h + 1, -5, h - 1)
        ..quadraticBezierTo(1, h - 3, 2, h - 9)
        ..close();
    }
    canvas.drawPath(Path.combine(PathOperation.union, path, tail), paint);
  }

  @override
  bool shouldRepaint(_BubbleBg old) => old.color != color || old.mine != mine;
}

/// A tiny "Telegram-style" ribbon for the Chats header — the plane mark plus a
/// soft label, so the messaging's inspiration is legible without pretending the
/// chats are actual Telegram threads.
class TelegramStyleRibbon extends StatelessWidget {
  const TelegramStyleRibbon({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: _tgTop.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TelegramMark(size: 22),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _tgBottom,
            ),
          ),
        ],
      ),
    );
  }
}
