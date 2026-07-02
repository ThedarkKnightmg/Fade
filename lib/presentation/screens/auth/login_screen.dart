import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../data/app_state.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../root_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // No prefilled credentials — a real-looking password in the field trips
  // secret scanners and leaks into screenshots/recordings.
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitted = false;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _emailError = Validators.email(_email.text);
      _passwordError = Validators.password(_password.text);
    });
  }

  void _signIn() {
    _submitted = true;
    _validate();
    if (_emailError != null || _passwordError != null) return;
    AppState.instance.signIn();
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FadeSlideIn(child: BarberLogo(size: 38)),
              const SizedBox(height: 30),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome\n',
                        style: AppTypography.display(context),
                      ),
                      markerBoxSpan('back!', AppTypography.display(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: Text(
                  'Your chair is exactly where you left it.',
                  style: AppTypography.bodySmall(context),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: AppTextField(
                  label: 'Email',
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
                  label: 'Password',
                  hint: '••••••••',
                  controller: _password,
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline_rounded,
                  maxLength: 128,
                  errorText: _passwordError,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signIn(),
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
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      final err = Validators.email(_email.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err != null
                              ? 'Enter your email first, then tap again.'
                              : 'Reset link sent to ${_email.text.trim()}'),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: p.textSecondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accent,
                        decorationThickness: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 340),
                child: PrimaryButton(
                  label: 'Sign in',
                  height: 62,
                  onPressed: _signIn,
                ),
              ),
              const SizedBox(height: 26),
              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: p.divider, thickness: 1.4)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or continue with',
                          style: AppTypography.caption(context)),
                    ),
                    Expanded(child: Divider(color: p.divider, thickness: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 460),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialCircle(label: 'G', onTap: _signIn),
                    const SizedBox(width: 14),
                    _SocialCircle(
                        icon: Icons.apple_rounded, onTap: _signIn),
                    const SizedBox(width: 14),
                    _SocialCircle(label: 'f', onTap: _signIn),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              FadeSlideIn(
                delay: const Duration(milliseconds: 520),
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      FadeThroughPageRoute(child: const RegisterScreen()),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'New here?  ',
                            style: AppTypography.body(context),
                          ),
                          markerBoxSpan(
                            'Create account',
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

class _SocialCircle extends StatelessWidget {
  const _SocialCircle({this.label, this.icon, this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Material(
      color: p.card,
      shape: CircleBorder(side: BorderSide(color: p.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 26, color: p.text)
                : Text(
                    label!,
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: p.text,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
