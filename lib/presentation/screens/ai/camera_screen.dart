import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/photo/camera_capture.dart';
import '../../../core/photo/photo_source.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/primary_button.dart';

/// A live camera screen. Opens the device camera (web `getUserMedia`), shows
/// the feed, and returns a captured JPEG via `Navigator.pop`. If the camera
/// can't start (denied / unsupported / headless), it offers an Upload fallback.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraCapture _cam = createCamera();
  bool _starting = true;
  bool _live = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await _cam.start();
    if (!mounted) return;
    setState(() {
      _live = ok;
      _starting = false;
    });
  }

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  void _shoot() {
    final bytes = _cam.capture();
    if (bytes != null) {
      Navigator.of(context).pop<Uint8List>(bytes);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.stHoldStill)),
      );
    }
  }

  Future<void> _upload() async {
    setState(() => _busy = true);
    Uint8List? bytes;
    try {
      bytes = await capturePhoto(camera: false);
    } catch (_) {
      bytes = null;
    }
    if (!mounted) return;
    Navigator.of(context).pop<Uint8List>(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _starting
          ? const _Centered(child: _StartingView())
          : _live
              ? _LiveView(
                  viewType: _cam.viewType,
                  onShoot: _shoot,
                  onClose: () => Navigator.of(context).pop(),
                )
              : _Centered(
                  child: _UnavailableView(
                    busy: _busy,
                    onUpload: _upload,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(28),
        child: child,
      )));
}

class _StartingView extends StatelessWidget {
  const _StartingView();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: 16),
        Text(L.stOpeningCamera,
            style: AppTypography.h4(context).copyWith(color: Colors.white)),
      ],
    );
  }
}

class _LiveView extends StatelessWidget {
  const _LiveView({
    required this.viewType,
    required this.onShoot,
    required this.onClose,
  });

  final String viewType;
  final VoidCallback onShoot;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: viewType),
        // Top gradient + close.
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _RoundGlass(icon: Icons.close_rounded, onTap: onClose),
            ),
          ),
        ),
        // Shutter.
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: GestureDetector(
                onTap: onShoot,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundGlass extends StatelessWidget {
  const _RoundGlass({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({
    required this.busy,
    required this.onUpload,
    required this.onClose,
  });

  final bool busy;
  final VoidCallback onUpload;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.no_photography_rounded,
              color: Colors.white70, size: 32),
        ),
        const SizedBox(height: 16),
        Text(L.stCameraUnavailable,
            textAlign: TextAlign.center,
            style: AppTypography.h3(context).copyWith(color: Colors.white)),
        const SizedBox(height: 6),
        Text(
          L.stCameraUnavailableBody,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall(context)
              .copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: busy ? L.stOpening : L.uploadPhoto,
          icon: Icons.image_outlined,
          height: 54,
          onPressed: busy ? null : onUpload,
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: L.cancel,
          height: 50,
          style: PrimaryButtonStyle.ghost,
          onPressed: onClose,
        ),
      ],
    );
  }
}
