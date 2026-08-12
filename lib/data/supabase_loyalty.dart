import '../core/supabase/supabase_service.dart';

/// Thin client over the server-authoritative loyalty RPCs (migration
/// 20260725100000_loyalty_ledger.sql). Every call needs a real session; each
/// returns null / false on no-session or failure so callers can fall back to
/// the local mirror. The SERVER is the source of truth — these just read/ask.
class SupabaseLoyalty {
  SupabaseLoyalty._();

  static bool get _live =>
      SupabaseService.isReady && SupabaseService.currentUser != null;

  /// Spendable Fade-Points balance (so'm), server-computed. Null = unknown.
  static Future<int?> balance() async {
    if (!_live) return null;
    try {
      final r = await SupabaseService.client.rpc('points_balance');
      return (r as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// This user's stable referral code (lazily minted server-side). Null = fail.
  static Future<String?> myReferralCode() async {
    if (!_live) return null;
    try {
      final r = await SupabaseService.client.rpc('my_referral_code');
      return r as String?;
    } catch (_) {
      return null;
    }
  }

  /// Record who referred me. Server rejects self-referral / a second attempt.
  static Future<bool> setReferrer(String code) async {
    if (!_live) return false;
    try {
      final r = await SupabaseService.client
          .rpc('set_referrer', params: {'p_code': code});
      return r == true;
    } catch (_) {
      return false;
    }
  }

  /// Redeem up to [som] points (server enforces min 10,000 + balance).
  /// Returns the amount actually applied, or null on failure.
  static Future<int?> redeem(int som) async {
    if (!_live) return null;
    try {
      final r =
          await SupabaseService.client.rpc('points_redeem', params: {'p_amount': som});
      return (r as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Barber completes a booking (server-verified). Returns the points the
  /// client earned, or null on failure. The ONLY path to 'completed' + earning.
  static Future<int?> completeBooking(String bookingId) async {
    if (!_live) return null;
    try {
      final r = await SupabaseService.client
          .rpc('booking_complete', params: {'p_booking': bookingId});
      return (r as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }
}
