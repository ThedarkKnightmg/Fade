import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// The barber's check-in poster: one QR to print and stick on the window or
/// desk. Clients scan it with Fade when they arrive (see
/// AppState.clientCheckIn), so the barber never has to scan anyone.
///
/// The poster itself is drawn in fixed light colours (it's paper, not a
/// screen), trilingual, and exported as a sharp PNG to share or print.
class CheckinPosterScreen extends StatefulWidget {
  const CheckinPosterScreen({super.key});

  @override
  State<CheckinPosterScreen> createState() => _CheckinPosterScreenState();
}

class _CheckinPosterScreenState extends State<CheckinPosterScreen> {
  final _poster = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    HapticFeedback.selectionClick();
    try {
      final boundary =
          _poster.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 4); // print-sharp
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) return;
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(png.buffer.asUint8List(),
              mimeType: 'image/png', name: 'fade-checkin-qr.png'),
        ],
        fileNameOverrides: const ['fade-checkin-qr.png'],
        text: L.posterTitle,
      ));
    } catch (_) {
      // Sharing unavailable (e.g. some desktop builds): nothing to do.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final s = AppState.instance;
    final me = s.meBarber;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                CircleBtn(
                  icon: Icons.arrow_back_rounded,
                  size: 42,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(L.posterTitle, style: AppTypography.h2(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(L.posterSub, style: AppTypography.bodySmall(context)),
            const SizedBox(height: 18),
            Center(
              child: RepaintBoundary(
                key: _poster,
                child: _Poster(
                  payload: s.barberCheckInPayload,
                  barber: me.barber.name,
                  shop: me.shop.name,
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: L.posterShare,
              icon: Icons.ios_share_rounded,
              height: 56,
              onPressed: _sharing ? null : _share,
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.payload, required this.barber, required this.shop});
  final String payload;
  final String barber;
  final String shop;

  static const _ink = Color(0xFF121417);

  @override
  Widget build(BuildContext context) {
    TextStyle t(double size, FontWeight w, [Color c = _ink]) =>
        GoogleFonts.nunito(fontSize: size, fontWeight: w, color: c, height: 1.15);
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E6EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0B1220), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.content_cut_rounded,
                    size: 17, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text('Fade', style: t(22, FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          // Trilingual on purpose: the poster is read by everyone who walks in.
          Text('Keldingizmi? Skanerlang', textAlign: TextAlign.center,
              style: t(20, FontWeight.w900)),
          const SizedBox(height: 2),
          Text('Пришли? Отсканируйте · Arrived? Scan',
              textAlign: TextAlign.center,
              style: t(12.5, FontWeight.w700, const Color(0xFF5B6270))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.accent, width: 3),
            ),
            child: QrImageView(
              data: payload,
              size: 220,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square, color: AppColors.accentDeep),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square, color: _ink),
            ),
          ),
          const SizedBox(height: 12),
          Text(barber, textAlign: TextAlign.center, style: t(17, FontWeight.w900)),
          Text(shop, textAlign: TextAlign.center,
              style: t(13, FontWeight.w700, const Color(0xFF5B6270))),
          const SizedBox(height: 10),
          Text('Fade ilovasi · Приложение Fade · Fade app',
              textAlign: TextAlign.center,
              style: t(11, FontWeight.w700, const Color(0xFF8A919E))),
        ],
      ),
    );
  }
}
