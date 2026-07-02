import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Per-shop cover colours so listings aren't all-blue. Premium shops use a
/// separate luxe gold-on-dark treatment.
const List<Color> kShopCoverColors = [
  Color(0xFF2E8BFF), // blue
  Color(0xFF18A999), // teal
  Color(0xFFE0683C), // terracotta
  Color(0xFF8E5BD0), // violet
  Color(0xFF2FA24E), // green
  Color(0xFFE0467E), // rose
];

/// The cover colour for a shop at [index] (premium overrides to gold).
Color shopCoverColor(int index, {bool premium = false}) =>
    premium ? AppColors.gold : kShopCoverColors[index % kShopCoverColors.length];

Color _shift(Color c, double amt) => amt >= 0
    ? Color.lerp(c, Colors.white, amt)!
    : Color.lerp(c, Colors.black, -amt)!;

/// Paints a stylised barbershop storefront: a striped scalloped awning, a
/// warm-lit window with a barber-chair silhouette, and a classic red/white/blue
/// pole. [base] tints the wall + awning; [premium] swaps to a gold-on-dark look.
class ShopCoverPainter extends CustomPainter {
  const ShopCoverPainter({required this.base, this.premium = false});

  final Color base;
  final bool premium;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wallTop = premium ? const Color(0xFF2C2433) : _shift(base, 0.20);
    final wallBot = premium ? const Color(0xFF141019) : _shift(base, -0.30);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [wallTop, wallBot],
        ).createShader(Offset.zero & size),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.88, w, h * 0.12),
      Paint()..color = _shift(wallBot, -0.12),
    );

    // Window (warm-lit) with a barber chair inside.
    final win = Rect.fromLTWH(w * 0.09, h * 0.40, w * 0.54, h * 0.46);
    canvas.drawRRect(
      RRect.fromRectAndRadius(win.inflate(3), const Radius.circular(7)),
      Paint()..color = _shift(wallBot, -0.18),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(win, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE9BC), Color(0xFFE9B968)],
        ).createShader(win),
    );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(win, const Radius.circular(4)));
    final chair = Paint()..color = const Color(0xCC3A2A22);
    final cxw = win.left + win.width * 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cxw - win.width * 0.20, win.top + win.height * 0.20,
            win.width * 0.40, win.height * 0.34),
        const Radius.circular(6),
      ),
      chair,
    );
    canvas.drawRect(
      Rect.fromLTWH(cxw - win.width * 0.26, win.top + win.height * 0.50,
          win.width * 0.52, win.height * 0.12),
      chair,
    );
    canvas.drawRect(
      Rect.fromLTWH(cxw - win.width * 0.05, win.top + win.height * 0.60,
          win.width * 0.10, win.height * 0.40),
      chair,
    );
    canvas.restore();

    // Barber pole (right of the window).
    final poleW = w * 0.058;
    final poleX = w * 0.78;
    final poleTop = h * 0.36;
    final poleH = h * 0.46;
    final poleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(poleX, poleTop, poleW, poleH), Radius.circular(poleW / 2));
    canvas.save();
    canvas.clipRRect(poleRect);
    canvas.drawRect(Rect.fromLTWH(poleX, poleTop, poleW, poleH),
        Paint()..color = Colors.white);
    final stripe = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = poleW * 0.5;
    var k = 0;
    for (double yy = poleTop - poleW;
        yy < poleTop + poleH + poleW;
        yy += poleW * 0.9) {
      stripe.color =
          (k++ % 2 == 0) ? const Color(0xFFE5484D) : const Color(0xFF2E6BE5);
      canvas.drawLine(Offset(poleX - poleW, yy + poleW),
          Offset(poleX + poleW * 2, yy - poleW), stripe);
    }
    canvas.restore();
    final cap = Paint()..color = const Color(0xFFB6BECB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(
              poleX - poleW * 0.2, poleTop - h * 0.045, poleW * 1.4, h * 0.055),
          const Radius.circular(3)),
      cap,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(poleX - poleW * 0.2, poleTop + poleH - h * 0.01,
              poleW * 1.4, h * 0.055),
          const Radius.circular(3)),
      cap,
    );

    // Awning (striped + scalloped), drawn last so it sits in front.
    final awH = h * 0.26;
    final awA = premium ? const Color(0xFFE9C45E) : _shift(base, 0.06);
    final awB = premium ? const Color(0xFF7A6224) : _shift(base, -0.34);
    const stripes = 7;
    final sw = w / stripes;
    for (var i = 0; i < stripes; i++) {
      final c = i.isEven ? awA : awB;
      final paint = Paint()..color = c;
      canvas.drawRect(Rect.fromLTWH(i * sw, 0, sw + 0.5, awH), paint);
      canvas.drawCircle(Offset((i + 0.5) * sw, awH), sw * 0.5, paint);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, awH + sw * 0.5 - 2, w, 3),
      Paint()..color = const Color(0x22000000),
    );
  }

  @override
  bool shouldRepaint(ShopCoverPainter old) =>
      old.base != base || old.premium != premium;
}

/// Paints a stylised interior "photo" for the shop gallery. [variant] picks the
/// scene: 0 = chair + mirror, 1 = vanity mirror with bulbs, 2 = product shelf,
/// 3 = tools on a counter. [base] tints the room.
class ShopInteriorPainter extends CustomPainter {
  const ShopInteriorPainter({
    required this.base,
    required this.variant,
    this.premium = false,
  });

  final Color base;
  final int variant;
  final bool premium;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wallTop = premium ? const Color(0xFF2D2536) : _shift(base, 0.12);
    final wallBot = premium ? const Color(0xFF181220) : _shift(base, -0.30);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [wallTop, wallBot],
        ).createShader(Offset.zero & size),
    );
    final floorY = h * 0.74;
    canvas.drawRect(Rect.fromLTWH(0, floorY, w, h - floorY),
        Paint()..color = _shift(wallBot, -0.14));
    // warm ambient
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.06),
      w * 0.55,
      Paint()
        ..color = const Color(0x26FFE6B0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );

    switch (variant % 4) {
      case 0:
        _chair(canvas, w, h, floorY);
        break;
      case 1:
        _vanity(canvas, w, h, floorY);
        break;
      case 2:
        _shelf(canvas, w, h, floorY);
        break;
      default:
        _tools(canvas, w, h, floorY);
    }
  }

  void _mirror(Canvas c, Rect r) {
    c.drawRRect(
      RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(8)),
      Paint()..color = const Color(0xFF6B6256),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCFE0EC), Color(0xFF8FA6B6)],
        ).createShader(r),
    );
  }

  void _chair(Canvas c, double w, double h, double floorY) {
    _mirror(c, Rect.fromLTWH(w * 0.10, h * 0.16, w * 0.34, h * 0.42));
    final dark = Paint()..color = const Color(0xFF2A1F19);
    final cx = w * 0.66;
    // back
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.13, h * 0.26, w * 0.26, h * 0.30),
          const Radius.circular(8)),
      dark,
    );
    // seat
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.16, h * 0.52, w * 0.32, h * 0.12),
          const Radius.circular(6)),
      dark,
    );
    // pedestal + base
    c.drawRect(Rect.fromLTWH(cx - w * 0.03, h * 0.62, w * 0.06, floorY - h * 0.62),
        Paint()..color = const Color(0xFF9AA3AF));
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.14, floorY - 4, w * 0.28, 8),
          const Radius.circular(4)),
      Paint()..color = const Color(0xFFB6BECB),
    );
  }

  void _vanity(Canvas c, double w, double h, double floorY) {
    final r = Rect.fromLTWH(w * 0.20, h * 0.16, w * 0.60, h * 0.48);
    _mirror(c, r);
    // bulbs around the top
    final bulb = Paint()..color = const Color(0xFFFFE7B0);
    for (var i = 0; i < 5; i++) {
      c.drawCircle(
          Offset(r.left + r.width * (0.12 + 0.19 * i), r.top - 6), 4, bulb);
    }
    // counter
    c.drawRect(Rect.fromLTWH(0, h * 0.66, w, h * 0.05),
        Paint()..color = const Color(0xFF3A2E26));
  }

  void _shelf(Canvas c, double w, double h, double floorY) {
    _mirror(c, Rect.fromLTWH(w * 0.16, h * 0.12, w * 0.68, h * 0.30));
    // shelf
    c.drawRect(Rect.fromLTWH(w * 0.1, h * 0.50, w * 0.8, h * 0.045),
        Paint()..color = const Color(0xFF3A2E26));
    // bottles
    final cols = [
      const Color(0xFFE5C07B),
      const Color(0xFF8FB7C9),
      const Color(0xFFCB7A8A),
      const Color(0xFF9ED0A6),
    ];
    for (var i = 0; i < 4; i++) {
      final bx = w * (0.22 + 0.18 * i);
      final bh = h * (0.16 + (i.isEven ? 0.05 : 0.0));
      c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(bx, h * 0.50 - bh, w * 0.07, bh),
            const Radius.circular(3)),
        Paint()..color = cols[i],
      );
    }
  }

  void _tools(Canvas c, double w, double h, double floorY) {
    // counter
    c.drawRect(Rect.fromLTWH(0, h * 0.60, w, h * 0.4),
        Paint()..color = const Color(0xFF3A2E26));
    final metal = Paint()
      ..color = const Color(0xFFD7DEE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    // scissors: two blades crossing
    final sx = w * 0.34, sy = h * 0.40;
    c.drawLine(Offset(sx - w * 0.12, sy - h * 0.12),
        Offset(sx + w * 0.10, sy + h * 0.14), metal);
    c.drawLine(Offset(sx + w * 0.12, sy - h * 0.12),
        Offset(sx - w * 0.10, sy + h * 0.14), metal);
    c.drawCircle(Offset(sx - w * 0.11, sy + h * 0.16), 6, metal);
    c.drawCircle(Offset(sx + w * 0.11, sy + h * 0.16), 6, metal);
    // comb
    final comb = Paint()..color = const Color(0xFF1F2730);
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.56, h * 0.30, w * 0.30, h * 0.06),
          const Radius.circular(3)),
      comb,
    );
    for (var i = 0; i < 10; i++) {
      c.drawRect(
          Rect.fromLTWH(w * (0.57 + i * 0.028), h * 0.36, w * 0.012, h * 0.12),
          comb);
    }
  }

  @override
  bool shouldRepaint(ShopInteriorPainter old) =>
      old.base != base || old.variant != variant || old.premium != premium;
}
