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

  static bool get isSet => url.isNotEmpty && publishableKey.isNotEmpty;
}
