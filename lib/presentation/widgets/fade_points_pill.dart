import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format/money.dart';

/// The Fade Points balance, in the app's one signature treatment.
///
/// Extracted from the home header so every surface that shows points looks
/// identical. That consistency is the point: Fade Points are money, and money
/// that changes appearance between screens reads as a score in one place and a
/// currency in another. Wherever this pill appears, it means the same thing.
///
/// The gradient is deliberately the loudest thing in the app — everything else
/// is the calm "paper" palette with a single blue accent. Points get the one
/// exception because they are the reward, and a reward that blends in isn't
/// one.
class FadePointsPill extends StatelessWidget {
  const FadePointsPill({
    super.key,
    required this.som,
    this.onTap,
    this.scale = 1,
    this.animate = true,
  });

  /// Balance in so'm (1 Fade Point = 1 UZS).
  final int som;
  final VoidCallback? onTap;

  /// 1 = the home-header size; larger for hero placements.
  final double scale;

  /// Count up from zero on appear. Off when the pill rebuilds constantly (in a
  /// game loop, say) or it would restart its animation every frame.
  final bool animate;

  static const gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF2D7E), Color(0xFF7A3CF0), Color(0xFF2E8BFF)],
  );

  @override
  Widget build(BuildContext context) {
    final coin = 30.0 * scale;
    final text = GoogleFonts.nunito(
      fontSize: 15 * scale,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(13 * scale, 5 * scale, 5 * scale, 5 * scale),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7A3CF0).withValues(alpha: 0.35),
              blurRadius: 12 * scale,
              offset: Offset(0, 4 * scale),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (animate)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: som.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(Money.group(v.round()), style: text),
              )
            else
              Text(Money.group(som), style: text),
            SizedBox(width: 8 * scale),
            Container(
              width: coin,
              height: coin,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.stars_rounded,
                  size: 17 * scale, color: const Color(0xFF7A3CF0)),
            ),
          ],
        ),
      ),
    );
  }
}
