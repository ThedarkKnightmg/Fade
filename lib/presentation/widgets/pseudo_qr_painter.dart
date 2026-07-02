import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A stylized, NON-scannable "QR" that reseeds every 30 seconds so it visibly
/// refreshes (deterring screenshots). Real QR generation + a camera scan are
/// backend/hardware — this only conveys the booking-ticket concept.
class PseudoQrView extends StatefulWidget {
  const PseudoQrView({
    super.key,
    required this.bookingId,
    this.size = 220,
    this.moduleColor,
  });

  final String bookingId;
  final double size;
  final Color? moduleColor;

  @override
  State<PseudoQrView> createState() => _PseudoQrViewState();
}

class _PseudoQrViewState extends State<PseudoQrView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reseed each 30-second bucket → the pattern flips every 30s.
    final bucket = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: PseudoQrPainter(
          seed: Object.hash(widget.bookingId, bucket),
          color: widget.moduleColor ?? AppColors.accentDeep,
        ),
      ),
    );
  }
}

class PseudoQrPainter extends CustomPainter {
  PseudoQrPainter({required this.seed, required this.color});
  final int seed;
  final Color color;

  static const int _n = 23;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final cell = size.width / _n;
    final radius = Radius.circular(cell * 0.3);
    final fill = Paint()..color = color;

    bool inFinder(int x, int y) {
      bool box(int ox, int oy) =>
          x >= ox && x < ox + 7 && y >= oy && y < oy + 7;
      return box(0, 0) || box(_n - 7, 0) || box(0, _n - 7);
    }

    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        if (inFinder(x, y)) continue;
        if (rnd.nextDouble() < 0.46) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x * cell + cell * 0.12, y * cell + cell * 0.12,
                  cell * 0.76, cell * 0.76),
              radius,
            ),
            fill,
          );
        }
      }
    }

    void finder(double cx, double cy) {
      // Ring (stroke) + core — no background-colour dependency.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + cell * 0.6, cy + cell * 0.6, cell * 5.8, cell * 5.8),
          Radius.circular(cell * 1.5),
        ),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + cell * 2.2, cy + cell * 2.2, cell * 2.6, cell * 2.6),
          Radius.circular(cell * 0.8),
        ),
        fill,
      );
    }

    finder(0, 0);
    finder(size.width - cell * 7, 0);
    finder(0, size.height - cell * 7);
  }

  @override
  bool shouldRepaint(PseudoQrPainter old) =>
      old.seed != seed || old.color != color;
}
