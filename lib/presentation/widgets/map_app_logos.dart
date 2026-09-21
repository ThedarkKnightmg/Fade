import 'package:flutter/material.dart';

/// Brand marks for the "get there" sheet.
///
/// These are drawn in code rather than bundled as image files. Two reasons:
/// nothing here ships a third party's trademarked artwork, and a painted mark
/// scales to any size and follows the theme without shipping six PNG densities.
///
/// They are built to be recognised at 40px — the size they actually appear at
/// — which means the brand's COLOUR and overall silhouette do the work, not
/// fine detail that would be invisible anyway.
///
/// If official brand assets are supplied later, swap the `child` of each row in
/// directions_sheet.dart for an Image.asset; nothing else needs to change.
class MapAppLogo extends StatelessWidget {
  const MapAppLogo({super.key, required this.app, this.size = 40});

  final MapApp app;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(app)),
    );
  }
}

enum MapApp { googleMaps, yandexMaps, yandexGo, uklon }

class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.app);

  final MapApp app;

  @override
  void paint(Canvas canvas, Size size) {
    switch (app) {
      case MapApp.googleMaps:
        _googleMaps(canvas, size);
      case MapApp.yandexMaps:
        _yandexMaps(canvas, size);
      case MapApp.yandexGo:
        _yandexGo(canvas, size);
      case MapApp.uklon:
        _uklon(canvas, size);
    }
  }

  /// Google Maps: the four-colour map plate with the red pin standing on it.
  void _googleMaps(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.24),
    );
    canvas.save();
    canvas.clipRRect(r);
    // The map plate: Google's green / blue / yellow bands.
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF34A853));
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.62, w, h * 0.38),
      Paint()..color = const Color(0xFF4285F4),
    );
    // The yellow road running across it.
    final road = Path()
      ..moveTo(0, h * 0.30)
      ..lineTo(w * 0.42, h * 0.30)
      ..lineTo(w, h * 0.86);
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFFFBBC04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.16,
    );
    canvas.restore();

    // The red pin.
    final c = Offset(w * 0.52, h * 0.42);
    final pin = Path()
      ..addOval(Rect.fromCircle(center: c, radius: w * 0.22))
      ..moveTo(c.dx - w * 0.13, c.dy + w * 0.13)
      ..lineTo(c.dx, c.dy + w * 0.40)
      ..lineTo(c.dx + w * 0.13, c.dy + w * 0.13)
      ..close();
    canvas.drawPath(pin, Paint()..color = const Color(0xFFEA4335));
    canvas.drawCircle(c, w * 0.085, Paint()..color = Colors.white);
  }

  /// Yandex Maps: the red locator arrow on a light plate.
  void _yandexMaps(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.24),
      ),
      Paint()..color = const Color(0xFFF5F5F5),
    );
    // Yandex's navigation chevron.
    final arrow = Path()
      ..moveTo(w * 0.50, h * 0.20)
      ..lineTo(w * 0.76, h * 0.78)
      ..lineTo(w * 0.50, h * 0.63)
      ..lineTo(w * 0.24, h * 0.78)
      ..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFFFF3333));
  }

  /// Yandex Go: the black plate with the yellow mark.
  void _yandexGo(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.24),
      ),
      Paint()..color = const Color(0xFF1A1A1A),
    );
    // A yellow "go" chevron pair.
    final p = Paint()
      ..color = const Color(0xFFFFCC00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.30, h * 0.30)
        ..lineTo(w * 0.54, h * 0.50)
        ..lineTo(w * 0.30, h * 0.70),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.56, h * 0.30)
        ..lineTo(w * 0.80, h * 0.50)
        ..lineTo(w * 0.56, h * 0.70),
      p,
    );
  }

  /// Uklon: the green plate with a white ride arrow.
  void _uklon(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.24),
      ),
      Paint()..color = const Color(0xFF00C24E),
    );
    final arrow = Path()
      ..moveTo(w * 0.22, h * 0.62)
      ..lineTo(w * 0.78, h * 0.30)
      ..lineTo(w * 0.66, h * 0.70)
      ..lineTo(w * 0.52, h * 0.55)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.app != app;
}
