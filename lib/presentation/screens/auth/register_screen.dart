import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/supabase/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../data/app_state.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../onboarding/barber_registration_screen.dart';
import '../root_shell.dart';
import 'phone_verify_screen.dart';

/// The SMS fallback — for whoever has neither Telegram nor Google.
///
/// Name + phone, then a real OTP. That's the whole form: the email and
/// password fields are gone, because the password was never checked against
/// anything and "Forgot password?" announced a reset link it never sent.
///
/// Reached from [LoginScreen] only when [SupabaseConfig.smsAuthConfigured] is
/// on, since SMS costs money per message and needs a live provider (Eskiz or
/// the Telegram Gateway) wired to the Supabase Send-SMS hook.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.role = AppRole.client});

  final AppRole role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _submitted = false;

  String? _nameError;
  String? _phoneError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _nameError = Validators.fullName(_name.text);
      _phoneError = Validators.phone(_phone.text);
    });
  }

  void _create() {
    _submitted = true;
    _validate();
    if (_nameError != null || _phoneError != null) return;
    HapticFeedback.selectionClick();

    final name = _name.text.trim();
    final phoneE164 = AuthService.normalizePhone(_phone.text.trim());

    // NOTHING is written to AppState here. The old code called updateUser()
    // before the OTP, so abandoning this screen left an unverified profile
    // persisted on the device. The identity is minted only on success, below.
    Navigator.of(context).push(
      FadeThroughPageRoute(
        child: PhoneVerifyScreen(
          phoneE164: phoneE164,
          onVerified: () {
            AppState.instance.signInWithIdentity(
              // Keyed on the verified number, like the Telegram path — so the
              // same human signing in either way lands on one identity.
              id: 'tg_$phoneE164',
              fullName: name,
              phone: phoneE164,
              role: widget.role,
              method: AuthMethod.phoneOtp,
            );
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              FadeThroughPageRoute(
                child: widget.role == AppRole.barber
                    ? const BarberRegistrationScreen()
                    : const RootShell(),
              ),
              (route) => false,
            );
          },
        ),
      ),
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
                child: Text(L.authSmsSub,
                    style: AppTypography.bodySmall(context)),
              ),
              const SizedBox(height: 24),
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
                  label: L.phoneWord,
                  hint: '+998 90 000 00 00',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  maxLength: 20,
                  textInputAction: TextInputAction.done,
                  errorText: _phoneError,
                  onSubmitted: (_) => _create(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]')),
                  ],
                  onChanged: (_) {
                    if (_submitted) _validate();
                  },
                ),
              ),
              const SizedBox(height: 26),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: PrimaryButton(
                  label: L.authSendCode,
                  height: 62,
                  onPressed: _create,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
