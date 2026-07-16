import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/animations/app_animations.dart';
import '../../core/i18n/strings.dart';
import '../../core/supabase/telegram_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/app_state.dart';

/// "Continue with Telegram" — the whole flow in one drop-in button (used by
/// BOTH the login and register screens, so the market-native sign-in is the
/// primary path everywhere):
///
///   tap → mint a one-time code → open t.me/<bot>?start=<code> → the user taps
///   START → the bot's webhook marks the code verified → we poll, sign in with
///   their Telegram name, and land in the app.
///
/// Free (no SMS cost), instantly familiar locally, and bot accounts are hard to
/// fake. Unconfigured builds demo the choreography so the flow stays testable.
class TelegramLoginButton extends StatefulWidget {
  const TelegramLoginButton({
    super.key,
    this.fallbackName,
    this.role = AppRole.client,
    this.onSignedIn,
  });

  /// Optional name typed on the register form, used only if Telegram doesn't
  /// give us one.
  final String? fallbackName;

  /// Which side of the marketplace this sign-up is for.
  final AppRole role;

  /// Called once the identity has landed in AppState. The GATE owns routing —
  /// the button must not push RootShell itself, or the barber path (which has
  /// to detour through setup) would be impossible.
  final VoidCallback? onSignedIn;

  /// Whether this build should render the button at all. Mirrors
  /// [GoogleLoginButton.visible]: in release it appears only when the bot is
  /// actually configured, so it can never be a button that signs nobody in.
  static bool get visible => TelegramAuth.configured || kDebugMode;

  @override
  State<TelegramLoginButton> createState() => _TelegramLoginButtonState();
}

class _TelegramLoginButtonState extends State<TelegramLoginButton> {
  static const _tgBlue = Color(0xFF2AABEE);
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    _busy = true;
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
    String? tgPhone;
    if (TelegramAuth.configured) {
      await launchUrl(TelegramAuth.deepLink(code),
          mode: LaunchMode.externalApplication);
      // Give them time to tap START *and* the share-contact button.
      for (var i = 0; i < 60 && !cancelled; i++) {
        await Future.delayed(const Duration(seconds: 2));
        try {
          final (verified, name, phone) = await TelegramAuth.check(code);
          if (verified) {
            ok = true;
            tgName = name;
            tgPhone = phone;
            break;
          }
        } catch (_) {
          // Transient network error — keep polling.
        }
      }
    } else if (kDebugMode) {
      // Demo choreography for builds with no bot configured, so the flow stays
      // testable. DEBUG ONLY, and deliberately so: this branch hands out a
      // fully authenticated session with a blank phone to anyone who taps and
      // waits. Harmless while it can never run in a shipped build — which is
      // exactly what the kDebugMode gate guarantees.
      await Future.delayed(const Duration(milliseconds: 2200));
      ok = !cancelled;
    }
    _busy = false;
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
    final typed = widget.fallbackName?.trim() ?? '';
    final name = (tgName != null && tgName.trim().isNotEmpty)
        ? tgName.trim()
        : (typed.isNotEmpty ? typed : L.tgDefaultName);
    final phone = tgPhone ?? '';
    if (phone.isEmpty) {
      // Verified with no number should be impossible — the webhook only marks a
      // code verified once the contact is shared. Refuse rather than admit an
      // identity we can't key on; a barber must be callable.
      _fail(L.tgNeedsContactShare);
      return;
    }
    // The phone came from Telegram's own contact card — verified at their
    // signup — so the account lands with a PROVEN number and no SMS cost.
    // The id derives from it: it used to be the constant 'u_tg', which gave
    // every Telegram user on earth the same account id.
    AppState.instance.signInWithIdentity(
      id: 'tg_$phone',
      fullName: name,
      phone: phone,
      role: widget.role,
      method: AuthMethod.telegram,
    );
    if (!mounted) return;
    widget.onSignedIn?.call();
  }

  void _fail(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _start,
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
            const SizedBox(height: 6),
            Text(
              L.tgVerifiesNumber,
              textAlign: TextAlign.center,
              style: AppTypography.caption(context),
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
