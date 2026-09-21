import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/animations/motion.dart';
import '../../core/i18n/strings.dart';
import '../../core/supabase/apple_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/app_state.dart';
import 'paper_kit.dart';

/// "Continue with Apple".
///
/// Ships because App Store Review Guideline 4.8 requires it wherever another
/// third-party sign-in is offered — an iOS build without it is rejected. It is
/// also the most private option in the sheet: Apple can relay a hidden email,
/// so someone can book a haircut without handing over a real address.
///
/// Renders only on Apple platforms. On Android and web it returns nothing at
/// all, because a sign-in button that cannot sign anyone in is worse than no
/// button.
class AppleLoginButton extends StatefulWidget {
  const AppleLoginButton({
    super.key,
    this.fallbackName,
    this.role = AppRole.client,
    this.onSignedIn,
  });

  /// Name typed on the register form. Apple only returns a name on the FIRST
  /// authorisation ever, so this is the backstop for every later sign-in.
  final String? fallbackName;

  final AppRole role;
  final VoidCallback? onSignedIn;

  /// Whether this build should render the button at all.
  static bool get visible => AppleAuth.available;

  @override
  State<AppleLoginButton> createState() => _AppleLoginButtonState();
}

class _AppleLoginButtonState extends State<AppleLoginButton> {
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      final profile = await AppleAuth.signIn();
      if (profile == null) {
        // Sheet dismissed — a choice, not a failure. Stay quiet.
        if (mounted) setState(() => _busy = false);
        return;
      }
      final typed = widget.fallbackName?.trim() ?? '';
      final name = profile.name.trim().isNotEmpty
          ? profile.name.trim()
          : (typed.isNotEmpty ? typed : L.tgDefaultName);
      // Keyed on the verified email, matching the Google path. Apple relay
      // addresses are stable per app, so this stays the same account across
      // sign-ins even when the address is hidden.
      AppState.instance.signInWithIdentity(
        id: 'a_${profile.email}',
        fullName: name,
        email: profile.email,
        role: widget.role,
        method: AuthMethod.google,
      );
      if (!mounted) return;
      widget.onSignedIn?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(L.appleFailed),
          behavior: SnackBarBehavior.floating,
        ));
      debugPrint('Apple sign-in failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return PressableScale(
      onTap: _start,
      child: AnimatedOpacity(
        opacity: _busy ? 0.6 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 58,
          decoration: clayDecoration(p, radius: 18, borderColor: p.border),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Apple's mark must not be recoloured or restyled; the system
              // glyph is the sanctioned form and follows the theme's ink.
              Icon(Icons.apple, size: 26, color: p.text),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  L.continueWithApple,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.button(context, color: p.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
