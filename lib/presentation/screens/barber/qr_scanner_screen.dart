import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';

/// A real camera QR scanner. Returns the first decoded QR string via
/// [Navigator.pop], or null if the barber backs out. A framed cut-out with a
/// sweeping laser line + corner brackets makes the target obvious.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.title, this.hint});

  /// Optional overrides so the same scanner reads correctly on both sides
  /// (barber scanning a client's ticket vs. client scanning a barber's code).
  final String? title;
  final String? hint;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  late final AnimationController _laser = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);
  bool _handled = false;
  bool _torch = false;

  @override
  void dispose() {
    _laser.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) {
        _handled = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(v);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frame = size.width * 0.72;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: frame,
      height: frame,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live camera.
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Dark scrim with a transparent square window.
          Positioned.fill(
            child: CustomPaint(painter: _ScrimPainter(scanRect)),
          ),
          // Corner brackets + sweeping laser.
          Positioned.fromRect(
            rect: scanRect,
            child: _ScanFrame(laser: _laser),
          ),
          // Title + hint.
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(widget.title ?? L.scanClient,
                    style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text(widget.hint ?? L.scanPointHint,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
          // Top bar: close + torch.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundGlass(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _RoundGlass(
                  icon: _torch
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  active: _torch,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _controller.toggleTorch();
                    setState(() => _torch = !_torch);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundGlass extends StatelessWidget {
  const _RoundGlass(
      {required this.icon, required this.onTap, this.active = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
    );
  }
}

/// Dark overlay everywhere except the scan window.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.window);
  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(window, const Radius.circular(28)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      scrim,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.window != window;
}

/// Accent corner brackets + a laser line sweeping the window.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.laser});
  final Animation<double> laser;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BracketPainter()),
          ),
          AnimatedBuilder(
            animation: laser,
            builder: (context, _) => Align(
              alignment: Alignment(0, -1 + 2 * laser.value),
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0),
                      AppColors.accent,
                      AppColors.accent.withValues(alpha: 0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.7),
                        blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 34.0;
    const r = 28.0;
    final w = size.width, h = size.height;
    // Four L-brackets, one per corner.
    void corner(Offset o, int sx, int sy) {
      final path = Path()
        ..moveTo(o.dx, o.dy + sy * len)
        ..lineTo(o.dx, o.dy + sy * r)
        ..arcToPoint(Offset(o.dx + sx * r, o.dy),
            radius: const Radius.circular(r), clockwise: sx * sy > 0)
        ..lineTo(o.dx + sx * len, o.dy);
      canvas.drawPath(path, paint);
    }

    corner(const Offset(0, 0), 1, 1);
    corner(Offset(w, 0), -1, 1);
    corner(Offset(0, h), 1, -1);
    corner(Offset(w, h), -1, -1);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => false;
}
