import '../core/format/money.dart';
import '../core/supabase/supabase_config.dart';
import '../core/supabase/supabase_service.dart';

/// Writes the real client↔barber booking loop to Supabase.
///
/// The database (see supabase/schema.sql) already carries the whole lifecycle
/// under row-level security: a client may insert only their own request
/// (`bookings_client_insert`, client_id = auth.uid()) and cancel only their own
/// pending/confirmed one (`bookings_client_cancel`); a barber may accept/decline
/// only a request assigned to them (`bookings_barber_respond`); and an immutable
/// trigger freezes price/identity/time. So every method here is a thin,
/// best-effort write — the RLS is what actually enforces the rules, and the
/// caller keeps its local copy whether or not the write lands (offline-tolerant,
/// exactly like [ShopRepository]).
///
/// Nothing persists unless we're on the live catalogue path AND there's a real
/// session AND the ids are real DB UUIDs — mock-catalogue bookings (whose
/// barber/shop/service ids are demo strings) stay local-only, so the demo keeps
/// working untouched.
class BookingRepository {
  BookingRepository._();

  static bool get _live =>
      SupabaseConfig.useRealCatalogue &&
      SupabaseService.isReady &&
      SupabaseService.currentUser != null;

  /// Persist a client's new booking request. Returns the new server UUID, or
  /// null when we're not on the live path / there's no session / an id isn't a
  /// real UUID / the write fails. The caller keeps the local booking either way
  /// and maps its local id → this UUID so a later cancel can reach the row.
  static Future<String?> createBooking({
    required String barberId,
    String? shopId,
    String? serviceId,
    required DateTime startAt,
    required double price,
    String? note,
  }) async {
    if (!_live || !isUuid(barberId)) return null;
    final uid = SupabaseService.currentUser!.id;
    try {
      final row = await SupabaseService.client
          .from('bookings')
          .insert({
            'client_id': uid,
            'barber_id': barberId,
            if (shopId != null && isUuid(shopId)) 'shop_id': shopId,
            if (serviceId != null && isUuid(serviceId)) 'service_id': serviceId,
            'start_at': startAt.toUtc().toIso8601String(),
            // Store real so'm, matching services.price (see ShopRepository).
            'price': Money.toSom(price),
            if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
            // status defaults to 'requested' server-side.
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (_) {
      return null; // offline / RLS reject / conflict → stay local-only
    }
  }

  /// Every booking visible to the signed-in user — their own as a client AND
  /// the ones assigned to them as a barber. RLS (`bookings_read`) does the
  /// filtering server-side, so this is simply "select what I'm allowed to see".
  ///
  /// This is the read half of the two-sided loop: without it a client's request
  /// lands in the database but never reaches the barber's device.
  ///
  /// Returns raw rows (id, ids, start_at, status, price, note) — the caller
  /// resolves shop/barber/service against the loaded catalogue, because those
  /// objects already exist there and re-fetching them per booking would be
  /// wasteful.
  static Future<List<Map<String, dynamic>>> fetchMyBookings() async {
    if (!_live) return const [];
    try {
      final rows = await SupabaseService.client
          .from('bookings')
          .select(
              'id, client_id, barber_id, shop_id, service_id, start_at, status, price, note')
          .order('start_at');
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  /// The client's name + phone for a booking this barber owns. `profiles` is
  /// read-own-only, so this goes through the SECURITY DEFINER RPC that releases
  /// the contact ONLY to the barber the client actually booked.
  static Future<({String name, String phone})?> clientContact(
      String bookingId) async {
    if (!_live || !isUuid(bookingId)) return null;
    try {
      final r = await SupabaseService.client.rpc(
        'client_contact_for_booking',
        params: {'p_booking': bookingId},
      );
      final list = (r as List?) ?? const [];
      if (list.isEmpty) return null;
      final m = list.first as Map<String, dynamic>;
      return (
        name: (m['full_name'] as String?) ?? '',
        phone: (m['phone'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Client cancels their own still-pending/confirmed booking. RLS only lets the
  /// owning client flip it to 'cancelled'.
  static Future<bool> cancelBooking(String serverId) =>
      _setStatus(serverId, 'cancelled');

  /// Barber accepts/declines a request assigned to them. Ready for the
  /// barber-device path — RLS permits it only when auth.uid() owns barber_id, so
  /// a client calling it (single-device demo) is silently, harmlessly refused.
  static Future<bool> respond(String serverId, {required bool accept}) =>
      _setStatus(serverId, accept ? 'confirmed' : 'declined');

  static Future<bool> _setStatus(String serverId, String status) async {
    if (!_live || !isUuid(serverId)) return false;
    try {
      await SupabaseService.client
          .from('bookings')
          .update({'status': status}).eq('id', serverId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// True for a canonical v4-ish UUID (what Supabase generates). Guards against
  /// pushing mock ids like `inreq_…` or `u1` to the server.
  static bool isUuid(String s) => _uuidRe.hasMatch(s);
  static final RegExp _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
}
