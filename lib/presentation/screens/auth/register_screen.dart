import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/supabase/auth_service.dart';
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
              const SizedBox(height: 26),
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
