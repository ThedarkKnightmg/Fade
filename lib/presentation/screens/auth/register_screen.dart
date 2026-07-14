import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/supabase/auth_service.dart';
import '../../../core/supabase/telegram_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../data/app_state.dart';
import '../../../data/models/user.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../root_shell.dart';
import 'phone_verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitted = false;
  bool _tgBusy = false;

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _nameError = Validators.fullName(_name.text);
      _emailError = Validators.email(_email.text);
      _phoneError = Validators.phone(_phone.text);
      _passwordError = Validators.password(_password.text);
    });
  }

  void _create() {
    _submitted = true;
    _validate();
    if (_nameError != null ||
        _emailError != null ||
        _phoneError != null ||
        _passwordError != null) {
      return;
    }
    HapticFeedback.selectionClick();
    // Persist the validated, trimmed profile; the phone is confirmed by an SMS
    // code before we actually land inside the app.
    AppState.instance.updateUser(
      AppUser(
        id: 'u_local',
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
      ),
    );
    final phoneE164 = AuthService.normalizePhone(_phone.text.trim());
    Navigator.of(context).push(
      FadeThroughPageRoute(
        child: PhoneVerifyScreen(
          phoneE164: phoneE164,
          onVerified: () {
            AppState.instance.signIn();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              FadeThroughPageRoute(child: const RootShell()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  /// "Continue with Telegram" — the market-native primary sign-in. Opens the
  /// bot deep link and waits for the webhook to confirm; unconfigured builds
  /// demo the same choreography locally so the flow is testable today.
  Future<void> _telegramLogin() async {
    if (_tgBusy) return;
    _tgBusy = true;
    HapticFeedback.selectionClick();
    final code = TelegramAuth.newCode();
    var cancelled = false;
    // The waiting sheet — swiping it away cancels the wait.
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TelegramWaitSheet(),
    ).whenComplete(() => cancelled = true);

    var ok = false;
    String? tgName;
    if (TelegramAuth.configured) {
      await launchUrl(TelegramAuth.deepLink(code),
          mode: LaunchMode.externalApplication);
      for (var i = 0; i < 30 && !cancelled; i++) {
        await Future.delayed(const Duration(seconds: 2));
        try {
          final (verified, name) = await TelegramAuth.check(code);
          if (verified) {
            ok = true;
            tgName = name;
            break;
          }
        } catch (_) {
          // Transient network error — keep polling.
        }
      }
    } else {
      // Demo until the bot is wired (SupabaseConfig.telegramBot).
      await Future.delayed(const Duration(milliseconds: 2200));
      ok = !cancelled;
    }
    _tgBusy = false;
    if (!mounted) return;
    final sheetStillOpen = !cancelled;
    if (sheetStillOpen) Navigator.of(context).pop(); // close the wait sheet
    if (!ok) {
      if (sheetStillOpen) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(L.tgFailed),
            behavior: SnackBarBehavior.floating,
          ));
      }
      return;
    }
    final typed = _name.text.trim();
    final name = (tgName != null && tgName.trim().isNotEmpty)
        ? tgName.trim()
        : (typed.isNotEmpty ? typed : L.tgDefaultName);
    AppState.instance.updateUser(
      AppUser(id: 'u_tg', fullName: name, email: '', phone: ''),
    );
    AppState.instance.signIn();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      FadeThroughPageRoute(child: const RootShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const ScaleIn(child: BarberLogo(size: 30)),
                ],
              ),
              const SizedBox(height: 26),
              FadeSlideIn(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: L.authGrabYour,
                        style: AppTypography.display(context),
                      ),
                      markerBoxSpan(
                          L.authOwnChair, AppTypography.display(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  L.authOneMinute,
                  style: AppTypography.bodySmall(context),
                ),
              ),
              const SizedBox(height: 22),
              // Telegram leads — the sign-in every local user already trusts
              // (free, instant, and bots can't fake it). Form is the fallback.
              FadeSlideIn(
                delay: const Duration(milliseconds: 110),
                child: _TelegramButton(onTap: _telegramLogin),
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                delay: const Duration(milliseconds: 125),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: p.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        L.tgOr,
                        style: AppTypography.caption(context),
                      ),
                    ),
                    Expanded(child: Divider(color: p.border)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: AppTextField(
                  label: L.authFullName,
                  hint: 'Alex Johnson',
                  controller: _name,
                  prefixIcon: Icons.badge_outlined,
                  maxLength: 60,
                  textInputAction: TextInputAction.next,
                  errorText: _nameError,
                  onChanged: (_) {
                    if (_submitted) _validate();
                  },
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: AppTextField(
                  label: L.emailWord,
                  hint: 'you@example.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                  textInputAction: TextInputAction.next,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_submitted) _validate();
                  },
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: AppTextField(
                  label: L.phoneWord,
                  hint: '+1 (555) 000-0000',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
                  errorText: _phoneError,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]')),
                  ],
                  onChanged: (_) {
                    if (_submitted) _validate();
                  },
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: AppTextField(
                  label: L.authPassword,
                  hint: L.authMin8Chars,
                  controller: _password,
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline_rounded,
                  maxLength: 128,
                  errorText: _passwordError,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _create(),
                  onChanged: (_) {
                    if (_submitted) _validate();
                  },
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: p.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              FadeSlideIn(
                delay: const Duration(milliseconds: 380),
                child: PrimaryButton(
                  label: L.authCreateAccount,
                  height: 62,
                  onPressed: _create,
                ),
              ),
              const SizedBox(height: 22),
              FadeSlideIn(
                delay: const Duration(milliseconds: 440),
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: L.authAlreadyHaveAcct,
                            style: AppTypography.body(context),
                          ),
                          markerBoxSpan(
                            L.authSignIn,
                            AppTypography.body(context)
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Telegram-blue primary sign-in button (paper-plane + label).
class _TelegramButton extends StatelessWidget {
  const _TelegramButton({required this.onTap});

  final VoidCallback onTap;

  static const _tgBlue = Color(0xFF2AABEE);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: _tgBlue,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _tgBlue.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              L.tgContinue,
              style: AppTypography.body(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "confirm in Telegram" waiting sheet — a pulsing plane while the app
/// polls for the bot's confirmation. Swipe down to cancel.
class _TelegramWaitSheet extends StatelessWidget {
  const _TelegramWaitSheet();

  static const _tgBlue = Color(0xFF2AABEE);

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Breathe(
              period: const Duration(milliseconds: 1600),
              builder: (context, t) {
                final pulse = 1 - (2 * t - 1).abs();
                return Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _tgBlue.withValues(alpha: 0.12 + 0.10 * pulse),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.send_rounded, color: _tgBlue, size: 28),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              L.tgWaiting,
              textAlign: TextAlign.center,
              style: AppTypography.h4(context),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: const SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  color: _tgBlue,
                  backgroundColor: Color(0x1F2AABEE),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
