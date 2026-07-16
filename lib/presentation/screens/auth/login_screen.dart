import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/google_login_button.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/telegram_login_button.dart';
import '../onboarding/barber_registration_screen.dart';
import '../root_shell.dart';
import 'register_screen.dart';

/// The front door. Every route into Fade passes through here — first run and
/// post-sign-out alike.
///
/// It only offers providers that VERIFY the person, because everything
/// downstream (bookings, wallet, commission, no-show penalties) assumes an
/// account maps to a real human. There is deliberately no email/password form:
/// it proved nothing, and its "Forgot password?" SnackBarred a reset link in
/// three languages while sending nothing at all.
///
/// Telegram leads on purpose. It returns a Telegram-VERIFIED phone number —
/// tied to a SIM, which here is tied to a passport — which is both the thing a
/// barber actually dials and the thing that makes a ban stick. Google proves an
/// email: great for anyone without Telegram, but a fresh Gmail costs a minute,
/// so it plays second.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.role = AppRole.client});

  /// Which side of the marketplace this person is signing up for. Carried as a
  /// constructor arg rather than written into AppState up front, so a user who
  /// backs out of the gate leaves no half-made account behind. It is committed
  /// only once an identity actually lands.
  final AppRole role;

  bool get _isBarber => role == AppRole.barber;

  /// Where a fresh identity goes next. A client is done — Telegram already gave
  /// us their name and verified phone, so there is nothing left to ask. A
  /// barber still needs a chair.
  void _onSignedIn(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      FadeThroughPageRoute(
        child: _isBarber ? const BarberRegistrationScreen() : const RootShell(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // Never render a door that cannot open: each button hides itself unless its
    // provider is actually configured (release) or we're in debug.
    final tg = TelegramLoginButton.visible;
    final google = GoogleLoginButton.visible;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (Navigator.of(context).canPop())
                    CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  const Spacer(),
                  const ScaleIn(child: BarberLogo(size: 30)),
                ],
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _isBarber ? L.authBarberTitle : L.authClientTitle,
                        style: AppTypography.display(context),
                      ),
                      markerBoxSpan(
                        _isBarber ? L.authBarberTitleMark : L.authClientTitleMark,
                        AppTypography.display(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 90),
                child: Text(
                  // Says WHY we want the number, in the terms that matter to
                  // each side. A reason converts better than a demand.
                  _isBarber ? L.authBarberWhy : L.authClientWhy,
                  style: AppTypography.bodySmall(context),
                ),
              ),
              const SizedBox(height: 26),
              if (tg)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: TelegramLoginButton(
                    role: role,
                    onSignedIn: () => _onSignedIn(context),
                  ),
                ),
              if (tg && google) const SizedBox(height: 12),
              if (google)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 210),
                  child: GoogleLoginButton(
                    role: role,
                    onSignedIn: () => _onSignedIn(context),
                  ),
                ),
              // Third door, for whoever has neither Telegram nor Google.
              // Deliberately a quiet text link, not a button: SMS costs money
              // per login, so it should be the road less travelled.
              if (SupabaseConfig.smsAuthConfigured) ...[
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 250),
                  child: Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        FadeThroughPageRoute(
                          child: RegisterScreen(role: role),
                        ),
                      ),
                      child: Text(L.authPhoneInstead,
                          style: AppTypography.bodySmall(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          )),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FadeSlideIn(
                delay: const Duration(milliseconds: 270),
                child: _TrustNote(isBarber: _isBarber),
              ),
              // No provider configured at all — only reachable in a misbuilt
              // release. Say so instead of showing an empty screen.
              if (!tg && !google)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(L.authNoProviders,
                      style: AppTypography.bodySmall(context)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The quiet reassurance under the buttons — Fade never sees a password, and
/// the number is only ever used for the booking itself.
class _TrustNote extends StatelessWidget {
  const _TrustNote({required this.isBarber});

  final bool isBarber;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, size: 16, color: p.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isBarber ? L.authTrustBarber : L.authTrustClient,
            style: AppTypography.caption(context),
          ),
        ),
      ],
    );
  }
}
