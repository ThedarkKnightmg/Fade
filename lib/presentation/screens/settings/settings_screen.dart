import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';
import 'calendar_sync_screen.dart';
import 'support_sheet.dart';
import 'verify_contact_screen.dart';

/// One home for the account + app preferences. Editing email or phone routes
/// through [VerifyContactScreen] so a new contact is confirmed before it sticks.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _toast(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _promptValue(
    BuildContext context, {
    required String title,
    required String label,
    required String initial,
    TextInputType? keyboard,
    String? helper,
  }) {
    final ctrl = TextEditingController(text: initial);
    final p = Paper.of(context);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTypography.h2(ctx)),
              if (helper != null) ...[
                const SizedBox(height: 6),
                Text(helper, style: AppTypography.bodySmall(ctx)),
              ],
              const SizedBox(height: 16),
              Text(label, style: AppTypography.h4(ctx)),
              const SizedBox(height: 6),
              TextField(
                controller: ctrl,
                keyboardType: keyboard,
                autofocus: true,
                maxLength: 120,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: p.text),
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: L.continueWord,
                height: 54,
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final v = await _promptValue(
      context,
      title: L.editNameTitle,
      label: L.nameWord,
      initial: AppState.instance.user.fullName,
    );
    if (v == null) return;
    if (!context.mounted) return;
    final err = Validators.fullName(v);
    if (err != null) {
      _toast(context, err);
      return;
    }
    AppState.instance.setUserName(v);
    _toast(context, L.profileUpdated);
  }

  /// Change email or phone — validate, then verify the NEW value before saving.
  Future<void> _changeContact(BuildContext context,
      {required bool isEmail}) async {
    final cur =
        isEmail ? AppState.instance.user.email : AppState.instance.user.phone;
    final v = await _promptValue(
      context,
      title: isEmail ? L.changeEmailTitle : L.changePhoneTitle,
      label: isEmail ? L.newEmailLabel : L.newPhoneLabel,
      initial: cur,
      keyboard:
          isEmail ? TextInputType.emailAddress : TextInputType.phone,
      helper: L.weWillVerify,
    );
    if (v == null) return;
    if (!context.mounted) return;
    final err = isEmail ? Validators.email(v) : Validators.phone(v);
    if (err != null) {
      _toast(context, err);
      return;
    }
    if (v == cur) return; // unchanged — nothing to verify
    final ok = await Navigator.of(context).push<bool>(
      FadeThroughPageRoute(
        child: VerifyContactScreen(target: v, isEmail: isEmail),
      ),
    );
    if (!context.mounted) return;
    if (ok != true) return;
    if (isEmail) {
      AppState.instance.setUserEmail(v);
    } else {
      AppState.instance.setUserPhone(v);
    }
    _toast(context, isEmail ? L.emailUpdated : L.phoneUpdated);
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

  Future<void> _signOut(BuildContext context) async {
    final p = Paper.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: p.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L.signOutQ, style: AppTypography.h2(ctx)),
              const SizedBox(height: 6),
              Text(L.signOutBody, style: AppTypography.bodySmall(ctx)),
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
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final state = AppState.instance;
          final user = state.user;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              children: [
                Row(
                  children: [
                    CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(L.settingsTitle, style: AppTypography.h1(context)),
                  ],
                ),
                const SizedBox(height: 20),

                // Account.
                FadeSlideIn(
                  child: _SectionLabel(L.accountSection),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 50),
                  child: _Card(
                    children: [
                      _Tile(
                        icon: Icons.person_outline_rounded,
                        label: L.nameWord,
                        value: user.fullName,
                        onTap: () => _editName(context),
                      ),
                      _Divider(),
                      _Tile(
                        icon: Icons.alternate_email_rounded,
                        label: L.emailWord,
                        value:
                            user.email.isEmpty ? L.tapToVerifyChange : user.email,
                        // Every stored contact went through VerifyContactScreen,
                        // so non-empty = verified; empty shows no badge.
                        badge: user.email.isEmpty ? null : _VerifiedBadge(),
                        onTap: () => _changeContact(context, isEmail: true),
                      ),
                      _Divider(),
                      _Tile(
                        icon: Icons.phone_outlined,
                        label: L.phoneWord,
                        value:
                            user.phone.isEmpty ? L.tapToVerifyChange : user.phone,
                        badge: user.phone.isEmpty ? null : _VerifiedBadge(),
                        onTap: () => _changeContact(context, isEmail: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Preferences.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 90),
                  child: _SectionLabel(L.preferencesSection),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _Card(
                    children: [
                      _Tile(
                        icon: Icons.dark_mode_rounded,
                        label: L.darkMode,
                        trailing: _MiniSwitch(
                          value: state.isDarkMode,
                          onChanged: (_) => state.toggleDarkMode(),
                        ),
                      ),
                      _Divider(),
                      _Tile(
                        icon: Icons.notifications_rounded,
                        label: L.reminders,
                        trailing: _MiniSwitch(
                          value: state.remindersOn,
                          onChanged: state.setReminders,
                        ),
                      ),
                      _Divider(),
                      _Tile(
                        icon: Icons.language_rounded,
                        label: L.language,
                        trailing: MiniPill(state.language.code,
                            style: MiniPillStyle.ghost),
                        onTap: () => _pickLanguage(context),
                      ),
                      _Divider(),
                      _Tile(
                        icon: Icons.event_available_rounded,
                        label: L.calendarSyncLabel,
                        trailing: MiniPill(
                          (state.googleCalConnected || state.appleCalConnected)
                              ? L.calConnected
                              : L.calNotConnected,
                          style: MiniPillStyle.ghost,
                        ),
                        onTap: () => Navigator.of(context).push(
                          FadeThroughPageRoute(
                              child: const CalendarSyncScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Help & feedback — report a bug, pitch an idea, or just talk.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 135),
                  child: _Card(
                    children: [
                      _Tile(
                        icon: Icons.support_agent_rounded,
                        label: L.helpFeedback,
                        value: L.helpFeedbackSub,
                        onTap: () => showSupportSheet(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Account actions.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: _Card(
                    children: [
                      _Tile(
                        icon: Icons.logout_rounded,
                        label: L.signOut,
                        labelColor: AppColors.red,
                        onTap: () => _signOut(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Text('Fade · ${L.appVersionLabel} 1.0.0',
                      style: AppTypography.caption(context)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text.toUpperCase(),
          style: AppTypography.caption(context).copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: Paper.of(context).textTertiary,
          )),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(color: Paper.of(context).divider, height: 1);
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.badge,
    this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final Widget? badge;
  final VoidCallback? onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
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
                color: p.cardAlt,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: p.border),
              ),
              child:
                  Icon(icon, size: 18, color: labelColor ?? p.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h4(context)
                                .copyWith(color: labelColor)),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        badge!,
                      ],
                    ],
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 1),
                    Text(value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(context)),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right_rounded,
                        size: 20, color: p.textTertiary)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded,
              size: 11, color: AppColors.green),
          const SizedBox(width: 3),
          Text(L.verifiedWord,
              style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green)),
        ],
      ),
    );
  }
}

/// Compact pill switch with an accent thumb (mirrors the profile switch).
class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.value, required this.onChanged});

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
          border: Border.all(color: value ? Colors.transparent : p.border),
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
