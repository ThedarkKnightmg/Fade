import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Thin wrapper around the Supabase client.
///
/// [init] runs once at startup (see main.dart). Initializing is local — it sets
/// up the client and restores any saved session, but never blocks on the
/// network — so it's safe even offline. The rest of the app is migrated onto
/// this incrementally; until then the client simply sits ready.
class SupabaseService {
  SupabaseService._();

  static bool _ready = false;
  static bool get isReady => _ready;

  static Future<void> init() async {
    if (_ready || !SupabaseConfig.isSet) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    _ready = true;
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// The signed-in auth user, or null when nobody is logged in.
  static User? get currentUser =>
      _ready ? Supabase.instance.client.auth.currentUser : null;
}
