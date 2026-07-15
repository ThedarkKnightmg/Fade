/// Connection details for the Fade Supabase backend.
///
/// The anon/publishable key is SAFE to ship in the client — row-level security
/// (see supabase/schema.sql) is what actually protects the data. The
/// `service_role` key must NEVER appear here.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://vlpfxcvoqucthtnueaoh.supabase.co';

  /// Public publishable key (verified against the project; ASCII-safe).
  static const String publishableKey =
      'sb_publishable_N4DP2eGEfHlvozDf1F1kcw_Yx1Nvfzr';

  /// The Telegram bot username (no @) that powers "Continue with Telegram"
  /// via the telegram-login Edge Function. Empty = not configured yet — the
  /// app then demos the flow locally. Create one with @BotFather and see
  /// supabase/functions/telegram-login/index.ts for the full setup.
  static const String telegramBot = 'Fade_uz_bot';

  /// The Google Cloud **Web** OAuth client ID (…apps.googleusercontent.com)
  /// that powers "Continue with Google". Safe to ship — it's an identifier,
  /// not a secret, and it carries no client secret with it.
  ///
  /// It must be the WEB client, not the Android one: Google signs the ID token
  /// with this as the audience, and that's the value Supabase validates. The
  /// Android client (package `uz.fade.app` + the release SHA-1) still has to
  /// exist so Google trusts the app's signature, but it's never named here.
  ///
  /// Setup (once):
  ///   1. console.cloud.google.com → new project "Fade".
  ///   2. APIs & Services → OAuth consent screen → External → fill in the app
  ///      name, support email, and fade.uz as the authorized domain.
  ///   3. Credentials → Create Credentials → OAuth client ID → **Android**:
  ///        package `uz.fade.app`, SHA-1 of the keystore you ship with.
  ///   4. Credentials → Create Credentials → OAuth client ID → **Web**: add
  ///        https://vlpfxcvoqucthtnueaoh.supabase.co/auth/v1/callback
  ///      as an authorized redirect URI. Paste its client ID below.
  ///   5. Supabase → Authentication → Providers → Google → enable, paste the
  ///      Web client ID + secret, and add the same Web client ID under
  ///      "Authorized Client IDs" so the native ID token is accepted.
  ///
  /// Empty = the button hides itself in release builds (never a dead button).
  static const String googleWebClientId = '';

  static bool get isSet => url.isNotEmpty && publishableKey.isNotEmpty;

  static bool get telegramLoginConfigured => isSet && telegramBot.isNotEmpty;

  static bool get googleConfigured => isSet && googleWebClientId.isNotEmpty;
}
