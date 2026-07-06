import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/referral_card.dart';
import '../atelier/atelier_screen.dart';
import '../auth/login_screen.dart';
import '../booking/booking_flow_screen.dart';
import '../settings/settings_screen.dart';

/// Profile — your card in the shop's notebook.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      FadeThroughPageRoute(child: const SettingsScreen()),
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final p = Paper.of(context);
    final picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Text(L.language, style: AppTypography.h3(context)),
              const SizedBox(height: 8),
              for (final l in AppLanguage.values)
                ListTile(
                  title: Text(l.label, style: AppTypography.h4(context)),
                  trailing: l == AppState.instance.language
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.accent)
                      : null,
                  onTap: () => Navigator.pop(ctx, l),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (picked != null) AppState.instance.setLanguage(picked);
  }

  void _shareInvite(BuildContext context) {
    final code =
        'CUT-${(AppState.instance.user.hashCode.abs() % 9000) + 1000}';
    Clipboard.setData(ClipboardData(
      text: L.pfInviteShare(code),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L.inviteCopiedFriend)),
    );
  }

  void _signOut(BuildContext context) async {
    final p = Paper.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: p.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L.signOutQ, style: AppTypography.h2(ctx)),
              const SizedBox(height: 6),
              Text(
                L.signOutBody,
                style: AppTypography.bodySmall(ctx),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: L.stay,
                      height: 50,
                      style: PrimaryButtonStyle.ghost,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: L.signOut,
                      height: 50,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (yes == true && context.mounted) {
      AppState.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        FadeThroughPageRoute(child: const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final user = state.user;
        final my = state.myBarber;
        final cuts = state.totalCuts;
        final streak = 2 + (cuts % 7); // weeks on the books — "keep it lit"
        final upcoming =
            state.bookingsByStatus(BookingStatus.upcoming).length +
                state.bookingsByStatus(BookingStatus.requested).length;

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
            children: [
              // Header — the rust circle says hi.
              FadeSlideIn(
                child: Row(
                  children: [
                    if (AppState.instance.userPhoto != null)
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: MemoryImage(AppState.instance.userPhoto!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      InitialAvatar(
                        name: user.fullName,
                        size: 74,
                        color: AppColors.accentDeep,
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              style: AppTypography.h1(context)),
                          const SizedBox(height: 2),
                          Text(user.email,
                              style: AppTypography.bodySmall(context)),
                        ],
                      ),
                    ),
                    CircleBtn(
                      icon: Icons.settings_rounded,
                      size: 44,
                      onTap: () => _openSettings(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              // VIP progress — flat card, gold goal-gradient bar (VIP = gold).
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(L.vipClub, style: AppTypography.h3(context)),
                ),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: PaperCard(
                  radius: 24,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              size: 21,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0683C)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '🔥 $streak wks',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFE0683C),
                              ),
                            ),
                          ),
                          const Spacer(),
                          MiniPill('$cuts / 16 CUTS'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: (cuts / 16).clamp(0, 1)),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, t, __) => LinearProgressIndicator(
                            value: t,
                            minHeight: 10,
                            backgroundColor: p.cardAlt,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.gold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cuts >= 16 ? L.vipUnlocked : L.cutsToVip(16 - cuts),
                        style: AppTypography.bodySmall(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Stats row.
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Row(
                  children: [
                    _Stat(value: '$cuts', label: L.cutsLabel),
                    const SizedBox(width: 10),
                    _Stat(value: '$upcoming', label: L.upcomingLabel),
                    const SizedBox(width: 10),
                    _Stat(
                      value: '${state.favouriteShopIds.length}',
                      label: L.savedShops,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              // My barber note.
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: my == null
                    ? PaperCard(
                        radius: 24,
                        padding: const EdgeInsets.all(16),
                        onTap: () => Navigator.of(context).push(
                          FadeThroughPageRoute(
                              child: const AtelierScreen()),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accent
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.person_search_rounded,
                                size: 21,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                L.noBarberPinned,
                                style: AppTypography.h4(context),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                size: 22, color: p.textTertiary),
                          ],
                        ),
                      )
                    : PaperCard(
                        radius: 24,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                InitialAvatar(
                                  name: my.barber.name,
                                  size: 52,
                                  index: my.barber.id.hashCode,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              my.barber.name,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: AppTypography.h4(
                                                  context),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          MiniPill(L.pfMyBarber),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        L.pfAtShop(my.shop.name),
                                        style: AppTypography.bodySmall(
                                            context),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    label: L.bookAgain,
                                    height: 48,
                                    onPressed: () =>
                                        Navigator.of(context).push(
                                      FadeThroughPageRoute(
                                        child: BookingFlowScreen(
                                          shop: my.shop,
                                          preselectedBarberId:
                                              my.barber.id,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: PrimaryButton(
                                    label: L.changeWord,
                                    height: 48,
                                    style: PrimaryButtonStyle.ghost,
                                    onPressed: () =>
                                        Navigator.of(context).push(
                                      FadeThroughPageRoute(
                                          child: const AtelierScreen()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              // Invite / referral — relocated from Home to keep Home uncluttered.
              FadeSlideIn(
                delay: const Duration(milliseconds: 210),
                child: ReferralCard(onShare: () => _shareInvite(context)),
              ),
              const SizedBox(height: 12),
              // "Become a barber" — an aspirational blue-gradient upsell (like a
              // "Become a PRO" card), not a plain toggle. Opens the barber side.
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: _BecomeBarberCard(
                  onTap: () => state.setRole(AppRole.barber),
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: PaperCard(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      _SettingRow(
                        icon: Icons.dark_mode_rounded,
                        label: L.darkMode,
                        tint: AppColors.accent,
                        trailing: _PillSwitch(
                          value: state.isDarkMode,
                          onChanged: (_) => state.toggleDarkMode(),
                        ),
                      ),
                      Divider(color: p.divider, height: 1),
                      _SettingRow(
                        icon: Icons.notifications_rounded,
                        label: L.reminders,
                        tint: AppColors.accent,
                        trailing: _PillSwitch(
                          value: state.remindersOn,
                          onChanged: state.setReminders,
                        ),
                      ),
                      Divider(color: p.divider, height: 1),
                      _SettingRow(
                        icon: Icons.language_rounded,
                        label: L.language,
                        tint: AppColors.accent,
                        trailing: MiniPill(state.language.code,
                            style: MiniPillStyle.ghost),
                        onTap: () => _pickLanguage(context),
                      ),
                      Divider(color: p.divider, height: 1),
                      _SettingRow(
                        icon: Icons.logout_rounded,
                        label: L.signOut,
                        tint: AppColors.red,
                        labelColor: AppColors.red,
                        onTap: () => _signOut(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: Center(
                  child: Text(
                    '${L.memberSincePrefix} ${DateFormat('MMMM yyyy').format(state.memberSince)} · ${L.madeWith}',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(context)
                        .copyWith(color: p.textTertiary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Expanded(
      child: PaperCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: p.text,
              ),
            ),
            const SizedBox(height: 1),
            Text(label, style: AppTypography.caption(context)),
          ],
        ),
      ),
    );
  }
}

/// Aspirational blue-gradient "Become a barber" card (mirrors a "Become a PRO"
/// upsell): a glass icon chip, title + subtitle, and a white Start pill.
class _BecomeBarberCard extends StatelessWidget {
  const _BecomeBarberCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4AA3FF), Color(0xFF1E6FE0)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.38),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.content_cut_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.becomeBarber,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 2),
                  Text(L.becomeBarberSub,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: Colors.white.withValues(alpha: 0.9),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(L.becomeBarberCta,
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentDeep,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.labelColor,
    this.tint,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;

  /// Icon-chip tint (the system language: tinted fill + tinted glyph).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final chip = tint ?? AppColors.accent;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: chip.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 19, color: chip),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.h4(context)
                    .copyWith(color: labelColor),
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Pill switch — accent thumb on an action track when on.
class _PillSwitch extends StatelessWidget {
  const _PillSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? p.action : p.cardAlt,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: value ? Colors.transparent : p.border,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AppColors.accent : p.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

