import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/photo/photo_source.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../root_shell.dart';
import 'barber_shop_attach_screen.dart';
import 'coworker_join_screen.dart';
import 'leader_loop_screen.dart';

/// Barber sign-up: everything a client needs to see — photo, name, age, phone,
/// shop, and location.
class BarberRegistrationScreen extends StatefulWidget {
  const BarberRegistrationScreen({super.key});

  @override
  State<BarberRegistrationScreen> createState() =>
      _BarberRegistrationScreenState();
}

class _BarberRegistrationScreenState extends State<BarberRegistrationScreen> {
  final _first = TextEditingController();
  final _surname = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  Uint8List? _photo;
  Barbershop? _selectedShop;
  bool _isOwner = true;

  @override
  void dispose() {
    for (final c in [_first, _surname, _age, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final bytes = await capturePhoto();
    if (bytes != null && mounted) setState(() => _photo = bytes);
  }

  Future<void> _pickShop() async {
    final result = await Navigator.of(context).push<ShopAttachResult>(
      FadeThroughPageRoute(
        child: BarberShopAttachScreen(selectedId: _selectedShop?.id),
      ),
    );
    if (result == null || !mounted) return;
    if (result.isCreateNew) {
      // Their shop isn't on the map — into the Leader Loop. Personal details
      // must be filled first (the loop carries them straight through).
      final err = _validatePersonal();
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      Navigator.of(context).push(
        FadeThroughPageRoute(
          child: LeaderLoopScreen(
            firstName: _first.text.trim(),
            surname: _surname.text.trim(),
            age: int.parse(_age.text.trim()),
            phone: _phone.text.trim(),
            initialShopName: result.createName ?? '',
          ),
        ),
      );
    } else {
      // Joining a shop that's already on the map runs Flow B — the Leader
      // approves the roster. Keep the selection as a direct-finish fallback.
      final shop = result.shop!;
      setState(() => _selectedShop = shop);
      final err = _validatePersonal();
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      Navigator.of(context).push(
        FadeThroughPageRoute(
          child: CoworkerJoinScreen(
            shop: shop,
            firstName: _first.text.trim(),
            surname: _surname.text.trim(),
            age: int.parse(_age.text.trim()),
            phone: _phone.text.trim(),
            photo: _photo,
          ),
        ),
      );
    }
  }

  /// Just the barber's own details — used before the Leader Loop (which doesn't
  /// need a pre-selected shop, since it creates one).
  String? _validatePersonal() {
    if (_first.text.trim().isEmpty) return L.errFirstName;
    if (_surname.text.trim().isEmpty) return L.errSurname;
    final age = int.tryParse(_age.text.trim());
    if (age == null || age < 16 || age > 90) return L.errAge;
    if (_phone.text.trim().length < 7) return L.errPhone;
    return null;
  }

  String? _validate() {
    final personal = _validatePersonal();
    if (personal != null) return personal;
    if (_selectedShop == null) return L.errChooseShop;
    return null;
  }

  void _finish() {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    AppState.instance.registerBarber(RegisteredBarber(
      firstName: _first.text.trim(),
      surname: _surname.text.trim(),
      age: int.parse(_age.text.trim()),
      phone: _phone.text.trim(),
      shopId: _selectedShop!.id,
      isOwner: _isOwner,
      photo: _photo,
    ));
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
            Text(L.setUpBarberProfile,
                style: AppTypography.display(context)),
            const SizedBox(height: 6),
            Text(L.clientsSeeThis,
                style: AppTypography.bodySmall(context)),
            const SizedBox(height: 22),
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 112,
                  height: 112,
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
                                color: AppColors.accent, size: 28),
                            const SizedBox(height: 4),
                            Text(L.addPhoto,
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
            Row(
              children: [
                Expanded(
                    child: _Field(
                        controller: _age,
                        label: L.ageLabel,
                        icon: Icons.cake_outlined,
                        keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    flex: 2,
                    child: _Field(
                        controller: _phone,
                        label: L.phoneWord,
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone)),
              ],
            ),
            const SizedBox(height: 18),
            Text(L.chooseYourShop, style: AppTypography.h4(context)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickShop,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _selectedShop == null
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : p.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedShop == null
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : p.border,
                    width: _selectedShop == null ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                        _selectedShop == null
                            ? Icons.add_location_alt_rounded
                            : Icons.storefront_rounded,
                        color: AppColors.accent,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _selectedShop == null
                          ? Text(L.pickShopOnMap,
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedShop!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.h4(context)),
                                Text(_selectedShop!.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall(context)),
                              ],
                            ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(L.yourRoleHere, style: AppTypography.h4(context)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RolePill(
                    label: L.ownerRole,
                    sub: L.ownerRoleSub,
                    icon: Icons.verified_rounded,
                    selected: _isOwner,
                    onTap: () => setState(() => _isOwner = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RolePill(
                    label: L.staffRole,
                    sub: L.staffRoleSub,
                    icon: Icons.content_cut_rounded,
                    selected: !_isOwner,
                    onTap: () => setState(() => _isOwner = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            PrimaryButton(
              label: L.finishOpenBarber,
              height: 60,
              icon: Icons.check_rounded,
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
        labelStyle:
            GoogleFonts.nunito(fontWeight: FontWeight.w600, color: p.textSecondary),
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(AppColors.accent, 1.5),
      ),
    );
  }
}

/// One of the two role choices (owner / staff) at sign-up — a tappable card
/// that fills with the accent when picked.
class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.label,
    required this.sub,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sub;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.10)
              : p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : p.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? AppColors.accent : p.textTertiary),
                const Spacer(),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: const Icon(Icons.check_circle_rounded,
                      size: 18, color: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: selected ? AppColors.accent : p.text)),
            const SizedBox(height: 2),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(context)),
          ],
        ),
      ),
    );
  }
}
