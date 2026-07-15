import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/animations/app_animations.dart';
import '../../core/animations/motion.dart';
import '../../core/i18n/strings.dart';
import '../../core/supabase/google_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/app_state.dart';
import '../../data/models/user.dart';
import '../screens/root_shell.dart';
import 'paper_kit.dart';

/// Google's official four-colour "G". Inlined rather than shipped as an asset
/// so the button is one self-contained import — and drawn as vectors, so it
/// stays crisp at any density. Google's brand terms require the mark be used
/// unmodified, so these paths must not be recoloured or restyled.
const String _googleG = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18">
<path fill="#4285F4" d="M17.64 9.2045c0-.6381-.0573-1.2518-.1636-1.8409H9v3.4814h4.8436c-.2086 1.125-.8427 2.0782-1.7959 2.7164v2.2581h2.9087c1.7018-1.5668 2.6836-3.874 2.6836-6.615z"/>
<path fill="#34A853" d="M9 18c2.43 0 4.4673-.806 5.9564-2.1805l-2.9087-2.2581c-.8055.54-1.8368.8595-3.0477.8595-2.344 0-4.3282-1.5831-5.036-3.7104H.9573v2.3318C2.4382 15.9832 5.4818 18 9 18z"/>
<path fill="#FBBC05" d="M3.964 10.71c-.18-.54-.2823-1.1168-.2823-1.71s.1023-1.17.2823-1.71V4.9582H.9573A8.9965 8.9965 0 0 0 0 9c0 1.4523.3477 2.8268.9573 4.0418L3.964 10.71z"/>
<path fill="#EA4335" d="M9 3.5795c1.3214 0 2.5077.4541 3.4405 1.346l2.5813-2.5814C13.4632.8918 11.426 0 9 0 5.4818 0 2.4382 2.0168.9573 4.9582L3.964 7.29C4.6718 5.1627 6.6559 3.5795 9 3.5795z"/>
</svg>
''';

/// "Continue with Google" — one tap, no typing, no cost.
///
/// Google Play Services draws the account sheet, so the name, the verified
/// email, and even the profile photo arrive filled in; the user never touches
/// a form. Sits beside [TelegramLoginButton], which proves a phone instead.
///
/// Hides itself in release builds until [SupabaseConfig.googleWebClientId] is
/// set — a sign-in button that can't sign anyone in is worse than no button.
class GoogleLoginButton extends StatefulWidget {
  const GoogleLoginButton({super.key, this.fallbackName});

  /// Name typed on the register form, used only if Google has no display name.
  final String? fallbackName;

  /// Whether this build should render the button at all.
  static bool get visible => GoogleAuth.configured || kDebugMode;

  @override
  State<GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<GoogleLoginButton> {
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    HapticFeedback.selectionClick();

    if (!GoogleAuth.configured) {
      // Debug-only: the button is visible so the layout can be reviewed before
      // the OAuth client exists. Say so plainly instead of faking a sign-in.
      _toast(L.googleNotConfigured);
      return;
    }

    setState(() => _busy = true);
    try {
      final profile = await GoogleAuth.signIn();
      if (profile == null) {
        // Picker dismissed — that's a choice, not a failure. Stay quiet.
        if (mounted) setState(() => _busy = false);
        return;
      }
      final typed = widget.fallbackName?.trim() ?? '';
      final name = profile.name.trim().isNotEmpty
          ? profile.name.trim()
          : (typed.isNotEmpty ? typed : L.tgDefaultName);
      AppState.instance.updateUser(
        AppUser(
          id: 'u_google',
          fullName: name,
          // Verified by Google — no confirmation mail needed.
          email: profile.email,
          phone: '',
          avatarUrl: profile.photoUrl,
        ),
      );
      AppState.instance.signIn();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        FadeThroughPageRoute(child: const RootShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(L.googleFailed);
      debugPrint('Google sign-in failed: $e');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return PressableScale(
      onTap: _start,
      child: AnimatedOpacity(
        // Only feedback for the round trip — the sheet covers the screen
        // anyway, so anything louder would be noise.
        opacity: _busy ? 0.6 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 58,
          decoration: clayDecoration(p, radius: 18, borderColor: p.border),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: _busy
                    ? CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: p.textTertiary,
                      )
                    : SvgPicture.string(_googleG),
              ),
              const SizedBox(width: 12),
              Text(
                _busy ? L.googleSigningIn : L.googleContinue,
                style: AppTypography.body(context).copyWith(
                  color: p.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
