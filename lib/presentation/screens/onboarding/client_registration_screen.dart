import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/photo/photo_source.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../root_shell.dart';

/// Client sign-up — just the basics so we can greet them and put a name on
/// their bookings.
class ClientRegistrationScreen extends StatefulWidget {
  const ClientRegistrationScreen({super.key});

  @override
  State<ClientRegistrationScreen> createState() =>
      _ClientRegistrationScreenState();
}

class _ClientRegistrationScreenState extends State<ClientRegistrationScreen> {
  final _first = TextEditingController();
  final _surname = TextEditingController();
  final _phone = TextEditingController();
  Uint8List? _photo;

  @override
  void dispose() {
    _first.dispose();
    _surname.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final bytes = await capturePhoto();
    if (bytes != null && mounted) setState(() => _photo = bytes);
  }

  void _finish() {
    if (_first.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.errFirstName)),
      );
      return;
    }
    AppState.instance.registerClient(
      fullName: '${_first.text.trim()} ${_surname.text.trim()}'.trim(),
      phone: _phone.text.trim(),
      photo: _photo,
    );
    Navigator.of(context).pushAndRemoveUntil(
      FadeThroughPageRoute(child: const RootShell()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
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
              ],
            ),
            const SizedBox(height: 12),
            Text(L.whatsYourName, style: AppTypography.display(context)),
            const SizedBox(height: 6),
            Text(L.soBarberKnows,
                style: AppTypography.bodySmall(context)),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: p.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.border, width: 2),
                    image: _photo != null
                        ? DecorationImage(
                            image: MemoryImage(_photo!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _photo != null
                      ? null
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_rounded,
                                color: AppColors.accent, size: 26),
                            const SizedBox(height: 4),
                            Text(L.photoOptional,
                                style: AppTypography.caption(context)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _Field(
                        controller: _first,
                        label: L.firstNameLabel,
                        icon: Icons.person_outline_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _Field(
                        controller: _surname,
                        label: L.surnameLabel,
                        icon: Icons.badge_outlined)),
              ],
            ),
            const SizedBox(height: 12),
            _Field(
                controller: _phone,
                label: L.phoneOptional,
                icon: Icons.phone_outlined,
                keyboard: TextInputType.phone),
            const SizedBox(height: 26),
            PrimaryButton(
              label: L.continueWord,
              height: 60,
              icon: Icons.arrow_forward_rounded,
              onPressed: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: p.text),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19, color: p.textTertiary),
        filled: true,
        fillColor: p.card,
        labelStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w600, color: p.textSecondary),
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(AppColors.accent, 1.5),
      ),
    );
  }
}
