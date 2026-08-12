import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/motion.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../auth/login_screen.dart';

/// "How will you use Fade?" — pick the client or barber side at sign-up.
///
/// This is the first screen anyone ever sees, so it carries the tone for the
/// whole app. Three layers of motion, in order of importance:
///   1. A slow ambient aura behind everything, so the page breathes instead of
///      sitting dead-flat. Radial gradients, not blur filters — free on the GPU.
///   2. A staggered entrance that reads top-to-bottom, landing on the two
///      choices last so the eye finishes where the decision is.
///   3. A commit moment: the tapped side swells and brightens while the other
///      recedes, acknowledging the choice before the screen changes.
/// Every one of them is skipped when the platform asks for reduced motion.
class RoleChoiceScreen extends StatefulWidget {
  const RoleChoiceScreen({super.key});

  @override
  State<RoleChoiceScreen> createState() => _RoleChoiceScreenState();
}

class _RoleChoiceScreenState extends State<RoleChoiceScreen> {
  /// Which side is mid-commit, so the cards can react before we navigate.
  AppRole? _committing;

  // Both sides go through the SAME gate — identity first, details after. The
  // role rides along as an argument and is only committed to AppState once a
  // provider has vouched for the person, so backing out leaves nothing behind.
  //
  // The client path used to push ClientRegistrationScreen ("Ismingiz nima?"),
  // which took a typed name and walked straight into the app. That screen is
  // deleted: Telegram already returns the name AND a verified phone, so the
  // form had nothing left to ask.
  Future<void> _go(AppRole role, {required bool reduced}) async {
    if (_committing != null) return; // ignore a double tap mid-transition
    setState(() => _committing = role);
    // Let the commit animation register before the route change swallows it.
    if (!reduced) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
    }
    await Navigator.of(context).push(
      FadeThroughPageRoute(child: LoginScreen(role: role)),
    );
    // Coming back should present a clean, unchosen screen again.
    if (mounted) setState(() => _committing = null);
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final reduced = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned.fill(child: _Aura(reduced: reduced)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FadeSlideIn(child: BarberLogo(size: 32)),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 90),
                    child: Text(L.howUseFade,
                        style: AppTypography.display(context)),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: Text(L.pickYourSide,
                        style: AppTypography.bodySmall(context)),
                  ),
                  // Weighted spacers float the choice slightly above centre —
                  // the old layout pinned both cards to the top and left the
                  // bottom 40% of the screen empty.
                  const Spacer(),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 250),
                    child: _RoleCard(
                      icon: Icons.person_rounded,
                      title: L.imAClient,
                      sub: L.clientRoleSub,
                      reduced: reduced,
                      state: _stateFor(AppRole.client),
                      onTap: () => _go(AppRole.client, reduced: reduced),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 330),
                    child: _RoleCard(
                      icon: Icons.content_cut_rounded,
                      title: L.imABarber,
                      sub: L.barberRoleSub,
                      accent: true,
                      reduced: reduced,
                      state: _stateFor(AppRole.barber),
                      onTap: () => _go(AppRole.barber, reduced: reduced),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _CardState _stateFor(AppRole role) => switch (_committing) {
        null => _CardState.idle,
        final c when c == role => _CardState.chosen,
        _ => _CardState.receding,
      };
}

/// How a card should present while a choice is being made.
enum _CardState { idle, chosen, receding }

/// Slow-drifting accent haze behind the content. Two radial gradients — no
/// BackdropFilter, so this costs essentially nothing per frame.
class _Aura extends StatelessWidget {
  const _Aura({required this.reduced});

  final bool reduced;

  Widget _blob(Alignment at, double size, double alpha) => Align(
        alignment: at,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: alpha),
                  AppColors.accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final blobs = [
      _blob(const Alignment(-1.1, -0.85), 360, 0.20),
      _blob(const Alignment(1.25, 0.15), 420, 0.13),
    ];
    if (reduced) return Stack(children: blobs);
    // Counter-drifting on a long period: perceptible as "alive", never as
    // movement competing with the content.
    return Breathe(
      period: const Duration(milliseconds: 9000),
      builder: (context, t) => Stack(
        children: [
          Transform.translate(
            offset: Offset(0, -18 + 36 * t),
            child: blobs[0],
          ),
          Transform.translate(
            offset: Offset(0, 20 - 34 * t),
            child: blobs[1],
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    required this.state,
    required this.reduced,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final _CardState state;
  final bool reduced;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final chosen = state == _CardState.chosen;
    final receding = state == _CardState.receding;

    // Glow tracks the commit: idle keeps the accent card lifted, chosen throws
    // a wider, stronger pool of light, receding drops it entirely.
    final double glow = switch (state) {
      _CardState.chosen => 0.45,
      _CardState.receding => 0.0,
      _CardState.idle => accent ? 0.30 : 0.0,
    };

    return PressableScale(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: AppCurves.easeOutQuart,
        opacity: receding ? 0.45 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 240),
          curve: AppCurves.easeOutQuart,
          scale: chosen ? 1.03 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: AppCurves.easeOutQuart,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accent ? AppColors.accent : p.card,
              borderRadius: BorderRadius.circular(26),
              border: accent ? null : Border.all(color: p.border),
              boxShadow: glow == 0
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: glow),
                        blurRadius: chosen ? 30 : 20,
                        offset: Offset(0, chosen ? 12 : 8),
                      ),
                    ],
            ),
            child: Row(
              children: [
                _IconTile(
                  icon: icon,
                  accent: accent,
                  reduced: reduced,
                  chosen: chosen,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h3(context)
                            .copyWith(color: accent ? Colors.white : null),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sub,
                        style: AppTypography.bodySmall(context).copyWith(
                            color: accent
                                ? Colors.white.withValues(alpha: 0.85)
                                : null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // The arrow leans forward as the choice is taken — a small
                // "off you go" that reads as momentum into the next screen.
                AnimatedSlide(
                  duration: const Duration(milliseconds: 240),
                  curve: AppCurves.easeOutQuart,
                  offset: chosen ? const Offset(0.35, 0) : Offset.zero,
                  child: Icon(Icons.arrow_forward_rounded,
                      color: accent ? Colors.white : p.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The rounded glyph tile. Idle it drifts almost imperceptibly (the barber's
/// shears tilt, the client's avatar swells) so the choice feels inhabited
/// rather than printed; on commit it snaps square and bright.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.accent,
    required this.reduced,
    required this.chosen,
  });

  final IconData icon;
  final bool accent;
  final bool reduced;
  final bool chosen;

  @override
  Widget build(BuildContext context) {
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: AppCurves.easeOutQuart,
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: accent
            ? Colors.white.withValues(alpha: chosen ? 0.34 : 0.22)
            : AppColors.accent.withValues(alpha: chosen ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon,
          size: 30, color: accent ? Colors.white : AppColors.accent),
    );

    if (reduced || chosen) return tile;

    // Shears rock a couple of degrees; the avatar breathes in scale. Different
    // motions so the two cards don't pulse in lockstep.
    return Breathe(
      period: Duration(milliseconds: accent ? 3400 : 4600),
      builder: (context, t) => accent
          ? Transform.rotate(angle: (t - 0.5) * 0.10, child: tile)
          : Transform.scale(scale: 1 + (t - 0.5) * 0.05, child: tile),
    );
  }
}
