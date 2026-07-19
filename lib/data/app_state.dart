import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/format/money.dart';
import '../core/i18n/app_language.dart';
import '../core/i18n/strings.dart';
import '../core/notifications/notify.dart';
import 'models/barber.dart';
import 'models/barber_break.dart';
import 'models/barbershop.dart';
import 'models/booking.dart';
import 'models/cancellation_policy.dart';
import 'models/charge_intent.dart';
import 'models/chat_message.dart';
import 'models/review.dart';
import 'models/service.dart';
import 'models/user.dart';
import 'models/wallet_tx.dart';
import 'mock_data.dart';

/// Which side of the marketplace the user is currently using.
enum AppRole { client, barber }

/// How far a person has got through the front door. ONE value, because two
/// independent booleans (`_isAuthenticated` + `_hasCompletedOnboarding`) could
/// disagree — and the splash screen used to *repair* the disagreement by
/// calling signIn(), which meant identity could never block entry.
///
/// * [anonymous] — nobody has proved anything. Show the sign-in gate.
/// * [identified] — a provider vouched for this human (we hold a verified
///   phone or email), but their setup isn't finished. Only barbers land here:
///   they still need a chair. Resuming sends them back to finish it.
/// * [ready] — identity proved AND setup complete. The app opens.
enum AuthStage { anonymous, identified, ready }

/// Which provider vouched for the person. Never null once past [anonymous] —
/// that's the invariant that makes "authenticated" mean something.
enum AuthMethod { telegram, google, phoneOtp }

/// Everything a barber gives us when they sign up in the intro.
/// Barbers don't create shops — they **attach** to an existing one ([shopId])
/// that's already on the map (placed by its owner). This keeps one pin per
/// real location no matter how many barbers join it.
class RegisteredBarber {
  RegisteredBarber({
    required this.firstName,
    required this.surname,
    required this.age,
    required this.phone,
    required this.shopId,
    this.isOwner = true,
    this.photo,
  });

  final String firstName;
  final String surname;
  final int age;
  final String phone;

  /// The existing barbershop this barber works at (picked on the map).
  final String shopId;

  /// Whether this barber OWNS the shop (can edit its identity — location,
  /// photos, description) or is staff who simply works there. Owners manage the
  /// place; staff attach to it and run their own chair (services, schedule).
  final bool isOwner;
  final Uint8List? photo;

  String get fullName => '$firstName $surname'.trim();
}

/// A live incoming booking request that pops up over the barber UI — the
/// booking itself plus the extra context shown on the request card.
class IncomingRequest {
  const IncomingRequest({
    required this.booking,
    required this.rating,
    required this.jobs,
    required this.distanceKm,
    required this.urgent,
  });

  final Booking booking;
  final double rating;
  final int jobs;
  final double distanceKm;
  final bool urgent;
}

/// Where a coworker's roster request stands.
enum JoinStatus { pending, approved, denied }

/// A barber's request to join a claimed shop's roster (Flow B). The Leader
/// approves/denies it; if they ghost, the 72-hour [autoApproveAt] fail-safe
/// lets the barber in anyway so growth never freezes at a dead-Leader shop.
class JoinRequest {
  JoinRequest({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.barberName,
    required this.bio,
    required this.priceNote,
    required this.portfolioCount,
    required this.requestedAt,
    this.rating = 5.0,
    this.status = JoinStatus.pending,
    this.autoApproved = false,
  });

  final String id;
  final String shopId;
  final String shopName;
  final String barberName;
  final String bio;
  final String priceNote;
  final int portfolioCount;
  final DateTime requestedAt;
  final double rating;
  JoinStatus status;
  bool autoApproved;

  /// The Dead-Leader fail-safe deadline: 72h after the request, the barber is
  /// auto-passed onto the roster if the Leader still hasn't responded.
  DateTime get autoApproveAt => requestedAt.add(const Duration(hours: 72));
  Duration get timeLeft => autoApproveAt.difference(DateTime.now());
}

/// A reference to a barber together with the shop they work at.
/// Used by the "My Barber" feature so we can navigate from a saved
/// barber id back to the full shop + barber pair.
class BarberRef {
  const BarberRef({required this.shop, required this.barber});
  final Barbershop shop;
  final Barber barber;
}

/// A "Barber Fuel" micro-transaction pack — a bundle of Boosts ("Ups") sold at
/// a decreasing per-boost price, kept in the wallet and spent on dead hours.
class BoostPack {
  const BoostPack(this.id, this.priceSom, this.count);
  final String id;
  final int priceSom;
  final int count;
  int get perBoostSom => (priceSom / count).round();
}

/// Lightweight in-memory app state — the single source of truth for
/// the current user, their bookings, and the barber they've chosen
/// as their personal "master". Uses ChangeNotifier so any widget
/// can listen and rebuild when state changes.
class AppState extends ChangeNotifier {
  AppState._() {
    _seedBookings();
    _seedChats();
  }
  static final AppState instance = AppState._();

  // === Messaging ===
  final Map<String, List<ChatMessage>> _chats = {};
  int _replyIx = 0;

  List<ChatMessage> chatWith(String barberId) =>
      _chats[barberId] ?? const <ChatMessage>[];

  /// You can only message a barber you've actually booked with — texting is
  /// unlocked by a booking, never before.
  bool hasBookingWith(String barberId) =>
      _bookings.any((b) => b.barber.id == barberId && b.clientName == null);

  /// The barbers you can message: one per barber you've booked, most recently
  /// booked first. Drives the Messages tab (no static barber list anymore).
  List<BarberRef> get bookedBarbers {
    final sorted = _bookings.where((b) => b.clientName == null).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final seen = <String>{};
    final out = <BarberRef>[];
    for (final b in sorted) {
      if (seen.add(b.barber.id)) {
        out.add(BarberRef(shop: b.barbershop, barber: b.barber));
      }
    }
    return out;
  }

  void _seedChats() {
    // Seed a chat only for barbers the user has already booked — messaging is
    // a post-booking feature. Runs after _seedBookings(), so derive from those.
    for (final bk in _bookings.where((b) => b.clientName == null)) {
      _chats.putIfAbsent(
        bk.barber.id,
        () => [
          ChatMessage(
            text: 'Thanks for coming in — hope you loved the cut ✂️ '
                'Message me here anytime to rebook.',
            mine: false,
            at: bk.dateTime.add(const Duration(hours: 1)),
          ),
        ],
      );
    }
  }

  void sendChat(String barberId, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final list = _chats.putIfAbsent(barberId, () => <ChatMessage>[]);
    list.add(ChatMessage(text: t, mine: true, at: DateTime.now()));
    notifyListeners();
    // A short, friendly canned reply from the barber.
    Future.delayed(const Duration(milliseconds: 900), () {
      const replies = [
        'Sure, see you then! ✂️',
        'Got it 👍 Your slot is saved.',
        "Yes, I'm free — come through.",
        'Thanks! Looking forward to it.',
      ];
      list.add(ChatMessage(
        text: replies[_replyIx++ % replies.length],
        mine: false,
        at: DateTime.now(),
      ));
      notifyListeners();
    });
  }

  // === Barber-side messaging (barber ⇄ client) ===
  // Keyed by client name, since clients are just names on a [Booking] in the
  // mock. `mine == true` means the signed-in barber sent it (right-aligned,
  // accent bubble), matching the client-side chat convention.
  final Map<String, List<ChatMessage>> _barberChats = {};
  int _clientReplyIx = 0;

  List<ChatMessage> barberChatWith(String client) =>
      _barberChats[client] ?? const <ChatMessage>[];

  /// Client threads whose latest message came from the client (barber hasn't
  /// replied yet) — drives the unread badge on the dashboard Messages icon.
  int get barberUnreadCount {
    var n = 0;
    for (final b in barberClients) {
      final name = b.clientName;
      if (name == null) continue;
      final msgs = _barberChats[name];
      if (msgs != null && msgs.isNotEmpty && !msgs.last.mine) n++;
    }
    return n;
  }

  /// Distinct clients the signed-in barber has any relationship with (a pending
  /// request, a confirmed booking, or past history), most-recent booking first.
  /// One [Booking] per client — the latest — for the tile's subtitle/avatar.
  List<Booking> get barberClients {
    final mine = _mine()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final seen = <String>{};
    final out = <Booking>[];
    for (final b in mine) {
      final name = b.clientName;
      if (name != null && seen.add(name)) out.add(b);
    }
    return out;
  }

  void sendBarberChat(String client, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final list = _barberChats.putIfAbsent(client, () => <ChatMessage>[]);
    list.add(ChatMessage(text: t, mine: true, at: DateTime.now()));
    notifyListeners();
    // A short, friendly canned reply from the client.
    Future.delayed(const Duration(milliseconds: 900), () {
      const replies = [
        'Great, thank you! 🙏',
        'See you then ✂️',
        "Perfect, I'll be there.",
        'Thanks for confirming 👍',
      ];
      list.add(ChatMessage(
        text: replies[_clientReplyIx++ % replies.length],
        mine: false,
        at: DateTime.now(),
      ));
      notifyListeners();
    });
  }

  // === Role: client ⇄ barber (one app, two sides) ===
  AppRole _activeRole = AppRole.client;
  AppRole get activeRole => _activeRole;
  bool get isBarberMode => _activeRole == AppRole.barber;

  void setRole(AppRole role) {
    if (_activeRole == role) return;
    _activeRole = role;
    notifyListeners();
  }

  void toggleRole() =>
      setRole(isBarberMode ? AppRole.client : AppRole.barber);

  /// In barber mode the signed-in user IS this barber — either a fresh sign-up
  /// or, by default, the demo identity.
  static const String _meBarberId = 'shop1_b1';

  RegisteredBarber? _registeredBarber;
  RegisteredBarber? get registeredBarber => _registeredBarber;

  /// Trust photos captured in the Leader Loop, keyed by shop id — the evidence
  /// behind a "this shop is real" claim. Held so a later review can actually
  /// look at it; until then it is at least no longer thrown away.
  final Map<String, Uint8List> _shopProofs = {};
  Uint8List? shopProofFor(String shopId) => _shopProofs[shopId];

  /// A barber has finished setup (they have a chair) — open the app.
  ///
  /// This no longer *grants* the session: reaching here at all now requires an
  /// already-[AuthStage.identified] user, i.e. a provider-verified phone. It
  /// used to set `_isAuthenticated = true` off four typed fields, which handed
  /// out a public marketplace identity — and, via the Leader Loop, a shop pin
  /// on the live map — to anyone who typed a name and `1234567`.
  void registerBarber(RegisteredBarber barber) {
    assert(_stage != AuthStage.anonymous,
        'registerBarber requires a verified identity — go through the gate');
    _registeredBarber = barber;
    _activeRole = AppRole.barber;
    _stage = AuthStage.ready;
    // Any completed barber sign-up (existing shop OR Leader Loop, which
    // delegates here) counts as onboarded, so a later client<->barber switch is
    // an instant setRole — not a forced re-run of the "become a barber" intro.
    _barberOnboarded = true;
    _reseedBarberDemoForRegistered();
    notifyListeners();
  }

  /// The "Leader Loop": a barber whose shop isn't on the map yet **creates**
  /// it and (optionally) claims the Leader role. The new shop is appended to
  /// the live catalogue so it appears on the map + in discovery instantly,
  /// seeded with the standard menu and the founder as its first chair.
  /// Returns the freshly-created shop.
  Barbershop createShopAsLeader({
    required String firstName,
    required String surname,
    required int age,
    required String phone,
    required String shopName,
    required String address,
    required double lat,
    required double lng,
    required bool claimLeader,
    Uint8List? leaderPhoto,
    Uint8List? shopProof,
  }) {
    final id = 'ushop_${DateTime.now().millisecondsSinceEpoch}';
    final barberId = '${id}_b1';
    final leaderName = '$firstName $surname'.trim();
    // A brand-new shop borrows the standard service menu so clients can book
    // from day one; the leader can tune prices later.
    final menu = MockData.barbershops.isNotEmpty
        ? MockData.barbershops.first.services
        : const <BarberService>[];
    final shop = Barbershop(
      id: id,
      name: shopName.trim().isEmpty ? 'My Barbershop' : shopName.trim(),
      tagline: 'New on Fade',
      description: '',
      address: address.trim(),
      lat: lat,
      lng: lng,
      distanceKm: 0.0,
      rating: 0.0,
      reviewCount: 0,
      coverImageUrl: 'https://picsum.photos/seed/$id/800/600',
      galleryUrls: const [],
      services: menu,
      barbers: [
        Barber(
          id: barberId,
          name: leaderName.isEmpty ? 'Founder' : leaderName,
          specialty: 'Founder',
          rating: 5.0,
          reviewCount: 0,
          yearsExperience: (age - 18).clamp(1, 40),
          imageUrl: 'https://picsum.photos/seed/$barberId/600/600',
          bio: '',
        ),
      ],
      reviews: const [],
      openingHours: 'Set your hours',
      isFeatured: false,
      priceLevel: 2,
      tags: const ['New'],
    );
    MockData.barbershops.add(shop);
    // Keep the trust photo. The parameter was accepted and then never read, so
    // the whole "prove you're real" step was theatre — the evidence reached
    // here and hit the floor, leaving nothing for anyone to review later.
    if (shopProof != null) _shopProofs[id] = shopProof;
    // Register the founder against the new shop; claiming → owner/Leader.
    registerBarber(RegisteredBarber(
      firstName: firstName,
      surname: surname,
      age: age,
      phone: phone,
      shopId: id,
      isOwner: claimLeader,
      photo: leaderPhoto,
    ));
    return shop;
  }

  // ═══════════════════ Flow B — coworker onboarding ═══════════════════
  // A barber joining a *claimed* shop can't just walk onto the roster; the
  // Leader approves them. If the Leader ghosts, the 72h auto-pass fail-safe
  // (see [JoinRequest.autoApproveAt]) lets them in so growth never freezes.

  final List<JoinRequest> _joinRequests = [];
  final Set<String> _seededRosterShops = {};

  /// The signed-in coworker's own pending request (drives the holding screen).
  JoinRequest? _myJoinRequest;
  JoinRequest? get myJoinRequest => _myJoinRequest;

  /// Effective status with the fail-safe applied: a still-pending request past
  /// its 72h window counts as approved (auto-passed).
  JoinStatus effectiveStatus(JoinRequest r) {
    if (r.status == JoinStatus.pending && r.timeLeft.isNegative) {
      return JoinStatus.approved;
    }
    return r.status;
  }

  /// Submit a request to join a claimed shop's roster (Flow B). Registers the
  /// barber as pending staff and drops them into the app on the holding screen.
  JoinRequest submitJoinRequest({
    required String firstName,
    required String surname,
    required int age,
    required String phone,
    required String shopId,
    required String shopName,
    required String bio,
    required String priceNote,
    required int portfolioCount,
    Uint8List? photo,
  }) {
    final req = JoinRequest(
      id: 'join_${DateTime.now().millisecondsSinceEpoch}',
      shopId: shopId,
      shopName: shopName,
      barberName: '$firstName $surname'.trim(),
      bio: bio.trim(),
      priceNote: priceNote.trim(),
      portfolioCount: portfolioCount,
      requestedAt: DateTime.now(),
    );
    _joinRequests.add(req);
    _myJoinRequest = req;
    registerBarber(RegisteredBarber(
      firstName: firstName,
      surname: surname,
      age: age,
      phone: phone,
      shopId: shopId,
      isOwner: false, // joins as staff — pending the Leader's nod
      photo: photo,
    ));
    return req;
  }

  /// Pending roster requests the Leader must action (Screen 4). In the single
  /// user demo we seed a couple so an owner always has something to approve.
  List<JoinRequest> rosterRequestsForMyShop() {
    if (!isShopOwner) return const [];
    final shopId = meBarber.shop.id;
    _ensureDemoRosterRequests(shopId);
    return _joinRequests
        .where((r) => r.shopId == shopId && r.status == JoinStatus.pending)
        .toList()
      ..sort((a, b) => a.timeLeft.compareTo(b.timeLeft)); // most urgent first
  }

  void _ensureDemoRosterRequests(String shopId) {
    if (_seededRosterShops.contains(shopId)) return;
    _seededRosterShops.add(shopId);
    final now = DateTime.now();
    _joinRequests.addAll([
      JoinRequest(
        id: 'join_demo_${shopId}_1',
        shopId: shopId,
        shopName: '',
        barberName: 'Jasur Tursunov',
        bio: 'Skin fades & beard sculpting. 6 yrs behind the chair.',
        priceNote: 'Fade 70k · Beard 40k',
        portfolioCount: 5,
        requestedAt: now.subtract(const Duration(hours: 3)),
        rating: 4.9,
      ),
      JoinRequest(
        id: 'join_demo_${shopId}_2',
        shopId: shopId,
        shopName: '',
        barberName: 'Bekzod Aliyev',
        bio: 'Classic cuts, hot-towel shaves. Ex-Elite Fades.',
        priceNote: 'Cut 60k · Shave 50k',
        portfolioCount: 4,
        requestedAt: now.subtract(const Duration(hours: 61)), // 11h left — urgent
        rating: 4.7,
      ),
    ]);
  }

  void approveJoinRequest(String id) {
    final i = _joinRequests.indexWhere((r) => r.id == id);
    if (i == -1) return;
    _joinRequests[i].status = JoinStatus.approved;
    notifyListeners();
  }

  void denyJoinRequest(String id) {
    final i = _joinRequests.indexWhere((r) => r.id == id);
    if (i == -1) return;
    _joinRequests[i].status = JoinStatus.denied;
    notifyListeners();
  }

  /// Dead-Leader (30-day) fail-safe: if a shop's Leader has gone silent, the
  /// admin role passes to the shop's highest-rated active barber so the roster
  /// never stays locked. Backend runs this on a schedule; exposed here so the
  /// UI can show "Leader inactive — you can take over."
  bool leaderIsStale(String shopId, DateTime leaderLastActive) =>
      DateTime.now().difference(leaderLastActive).inDays >= 30;

  Uint8List? _userPhoto;
  Uint8List? get userPhoto => _userPhoto;
  void setUserPhoto(Uint8List bytes) {
    _userPhoto = bytes;
    notifyListeners();
    _save();
  }

  // Preferred payment method (provider-handoff stub — Payme/Click/Uzum/cards).
  // No card data is stored; this is just the last-used provider id.
  String _payMethod = 'payme';
  String get payMethod => _payMethod;
  void setPayMethod(String id) {
    _payMethod = id;
    notifyListeners();
    _save();
  }

  // First-run barber setup (goal + photos) — shown once, then remembered.
  bool _barberOnboarded = false;
  bool get barberOnboarded => _barberOnboarded;
  void markBarberOnboarded() {
    _barberOnboarded = true;
    notifyListeners();
    _save();
  }

  // registerClient() is GONE. It minted a fully authenticated session from a
  // typed first name, and kept `id: _user.id` — which defaulted to the mock
  // user — so every client shared the id `u1`, the email
  // alex.johnson@example.com, and (phone being optional) a fake US number.
  // Clients now arrive through signInWithIdentity() with a provider-verified
  // identity and a unique id.

  /// The (shop, barber) the user operates as in barber mode — built from the
  /// sign-up details when present, otherwise the demo barber.
  BarberRef get meBarber {
    final r = _registeredBarber;
    if (r != null) {
      // The barber works AT an existing shop they attached to on the map.
      final shop = MockData.barbershops.firstWhere(
        (s) => s.id == r.shopId,
        orElse: () => MockData.barbershops.first,
      );
      final barber = Barber(
        id: _meBarberId,
        name: r.fullName,
        specialty: 'Barber',
        rating: 5,
        reviewCount: 0,
        yearsExperience: 0,
        imageUrl: '',
        bio: '',
      );
      return BarberRef(shop: shop, barber: barber);
    }
    final shop = MockData.barbershops.firstWhere(
      (s) => s.barbers.any((b) => b.id == _meBarberId),
      orElse: () => MockData.barbershops.first,
    );
    final barber = shop.barbers.firstWhere(
      (b) => b.id == _meBarberId,
      orElse: () => shop.barbers.first,
    );
    return BarberRef(shop: shop, barber: barber);
  }

  /// Whether the signed-in barber owns their shop — only owners can edit the
  /// shop's identity (location, photos, description). The default demo barber
  /// (no sign-up) is treated as the owner so the demo shows full editing.
  bool get isShopOwner => _registeredBarber?.isOwner ?? true;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Bookings the signed-in barber RECEIVED from clients. Excludes the current
  // user's own bookings (clientName == null) so that if you book your own
  // chair as a client, it never leaks into your barber requests/earnings.
  List<Booking> _mine() => _bookings
      .where((b) => b.barber.id == _meBarberId && b.clientName != null)
      .toList();

  /// Pending requests awaiting this barber's confirmation, soonest first.
  List<Booking> get incomingRequests => _mine()
      .where((b) => b.status == BookingStatus.requested)
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  /// Confirmed upcoming appointments, soonest first.
  List<Booking> get barberAgenda => _mine()
      .where((b) => b.status == BookingStatus.upcoming)
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  /// Finished/past appointments, most recent first.
  List<Booking> get barberHistory => _mine()
      .where((b) =>
          b.status == BookingStatus.completed ||
          b.status == BookingStatus.noShow)
      .toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  List<Booking> get barberToday =>
      barberAgenda.where((b) => _sameDay(b.dateTime, DateTime.now())).toList();

  /// Today's *expected* earnings (confirmed-but-not-yet-done cuts) in so'm.
  double get barberEarningsToday =>
      barberToday.fold(0.0, (sum, b) => sum + b.service.price);

  /// Today's *earned* so'm — cuts already completed today.
  double get barberEarnedToday => _mine()
      .where((b) =>
          b.status == BookingStatus.completed &&
          _sameDay(b.dateTime, DateTime.now()))
      .fold(0.0, (sum, b) => sum + b.service.price);

  /// Lifetime completed cuts + total earned (drives the history card).
  List<Booking> get _completedMine =>
      _mine().where((b) => b.status == BookingStatus.completed).toList();
  int get barberCompletedCount => _completedMine.length;
  double get barberTotalEarned =>
      _completedMine.fold(0.0, (sum, b) => sum + b.service.price);

  // === Weekly earnings goal (in so'm) ===
  int _weeklyGoalSom = 2800000;
  int get weeklyGoalSom => _weeklyGoalSom;
  void setWeeklyGoal(int som) {
    _weeklyGoalSom = som < 0 ? 0 : som;
    notifyListeners();
  }

  DateTime get _weekMonday {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day)
        .subtract(Duration(days: n.weekday - 1));
  }

  /// so'm earned (completed cuts) since Monday this week.
  int get barberEarnedThisWeekSom {
    final monday = _weekMonday;
    final nextMonday = monday.add(const Duration(days: 7));
    return _completedMine
        .where((b) =>
            !b.dateTime.isBefore(monday) && b.dateTime.isBefore(nextMonday))
        .fold(0, (s, b) => s + Money.toSom(b.service.price));
  }

  /// Earnings in so'm for each day of the current week, Monday → Sunday.
  /// Counts completed cuts (actual) **and** confirmed upcoming cuts (estimated)
  /// — so today's bar reflects what you'll earn from today's confirmed books.
  List<int> earningsThisWeekByDay() {
    final monday = _weekMonday;
    final out = List<int>.filled(7, 0);
    void tally(Iterable<Booking> bookings) {
      for (final b in bookings) {
        final d = DateTime(b.dateTime.year, b.dateTime.month, b.dateTime.day);
        final idx = d.difference(monday).inDays;
        if (idx >= 0 && idx < 7) out[idx] += Money.toSom(b.service.price);
      }
    }

    tally(_completedMine);
    tally(barberAgenda); // confirmed but not yet completed
    return out;
  }

  List<int> _byDay(Iterable<Booking> bookings) {
    final monday = _weekMonday;
    final out = List<int>.filled(7, 0);
    for (final b in bookings) {
      final d = DateTime(b.dateTime.year, b.dateTime.month, b.dateTime.day);
      final idx = d.difference(monday).inDays;
      if (idx >= 0 && idx < 7) out[idx] += Money.toSom(b.service.price);
    }
    return out;
  }

  /// Money already earned (completed) per weekday — the blue part of the chart.
  List<int> earnedThisWeekByDay() => _byDay(_completedMine);

  /// Money still expected (confirmed upcoming) per weekday — the green part.
  List<int> expectedThisWeekByDay() => _byDay(barberAgenda);

  /// Completed cuts within a time window (drives the history screen tabs).
  List<Booking> completedHistory({DateTime? since}) {
    final list = _completedMine
        .where((b) => since == null || !b.dateTime.isBefore(since))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  /// Whether the barber is online and accepting new bookings.
  bool _acceptingBookings = true;
  bool get acceptingBookings => _acceptingBookings;
  void toggleAccepting() {
    _acceptingBookings = !_acceptingBookings;
    notifyListeners();
  }

  // === Live incoming request (pops up over the barber UI) ===
  // In production this fires from a realtime Supabase booking insert; here we
  // simulate it so the flow is demoable while the barber is in the app.
  IncomingRequest? _incomingPopup;
  IncomingRequest? get incomingPopup => _incomingPopup;
  final Random _rng = Random();

  static const List<String> _demoClients = [
    'Aziz Karimov',
    'Bekzod Tursunov',
    'Sardor Aliyev',
    'Jasur Rakhimov',
    'Otabek Yusupov',
    'Michael Chen',
    'Eldor Nazarov',
    'Dilshod Umarov',
  ];
  static const List<String> _demoNotes = [
    'Can you do a skin fade today? Got an event tonight.',
    'Need a quick trim before work, please 🙏',
    'First time — classic cut + beard line-up.',
    'Same as last time, the low fade.',
    "Hair's gotten long — full cut + wash.",
    'Could you fit me in this afternoon?',
  ];

  /// Simulate a client booking arriving right now. Adds it to the request
  /// list and raises the pop-up. No-op if the barber is offline or a pop-up is
  /// already showing.
  void simulateIncomingRequest() {
    if (!_acceptingBookings || _incomingPopup != null) return;
    final ref = meBarber;
    final svcList =
        barberActiveServices.isNotEmpty ? barberActiveServices : _myServices;
    if (svcList.isEmpty) return;
    final svc = svcList[_rng.nextInt(svcList.length)];
    final when = DateTime.now().add(Duration(minutes: 30 + _rng.nextInt(150)));
    final booking = Booking(
      id: 'inreq_${DateTime.now().microsecondsSinceEpoch}',
      barbershop: ref.shop,
      barber: ref.barber,
      service: svc,
      dateTime: when,
      status: BookingStatus.requested,
      clientName: _demoClients[_rng.nextInt(_demoClients.length)],
      note: _demoNotes[_rng.nextInt(_demoNotes.length)],
    );
    _bookings.add(booking);
    _incomingPopup = IncomingRequest(
      booking: booking,
      rating: 4.5 + _rng.nextInt(6) / 10, // 4.5–5.0
      jobs: 3 + _rng.nextInt(38),
      distanceKm: (3 + _rng.nextInt(47)) / 10, // 0.3–4.9 km
      urgent: _rng.nextInt(3) == 0,
    );
    // Ping the barber's phone too — the request shouldn't rely on the app
    // being open on the Requests tab.
    if (_remindersOn) {
      Notify.show(L.notifNewRequestTitle,
          L.notifNewRequestBody(booking.clientName ?? '', _hhmm(when)));
    }
    notifyListeners();
  }

  /// Dismiss the pop-up (the underlying request stays in the list).
  void clearIncomingPopup() {
    if (_incomingPopup == null) return;
    _incomingPopup = null;
    notifyListeners();
  }

  /// Accept / decline straight from the pop-up.
  void acceptIncoming() {
    final b = _incomingPopup?.booking;
    if (b != null) confirmBooking(b.id);
    clearIncomingPopup();
  }

  void declineIncoming() {
    final b = _incomingPopup?.booking;
    if (b != null) declineBooking(b.id);
    clearIncomingPopup();
  }

  /// Every booking of mine on a given calendar day (any status), earliest
  /// first — drives the barber calendar.
  List<Booking> barberBookingsOn(DateTime day) => _mine()
      .where((b) => _sameDay(b.dateTime, day))
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  /// Count of active (pending + confirmed) bookings on a day — the calendar
  /// dot/number under each date.
  int barberActiveCountOn(DateTime day) => _mine()
      .where((b) =>
          _sameDay(b.dateTime, day) &&
          (b.status == BookingStatus.requested ||
              b.status == BookingStatus.upcoming))
      .length;

  // Barber actions on a booking.
  void _setBookingStatus(String id, BookingStatus status,
      {DateTime? completedAt}) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i == -1) return;
    _bookings[i] =
        _bookings[i].copyWith(status: status, completedAt: completedAt);
    notifyListeners();
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void confirmBooking(String id) {
    final b = _bookingById(id);
    _setBookingStatus(id, BookingStatus.upcoming);
    // The promised "we'll ping you" — a real device notification.
    if (_remindersOn && b != null) {
      Notify.show(L.notifConfirmedTitle,
          L.notifConfirmedBody(_hhmm(b.dateTime), b.barbershop.name));
    }
  }

  void declineBooking(String id) {
    final b = _bookingById(id);
    _setBookingStatus(id, BookingStatus.declined);
    if (_remindersOn && b != null) {
      Notify.show(
          L.notifDeclinedTitle, L.notifDeclinedBody(b.barbershop.name));
    }
  }
  void completeBooking(String id) {
    final b = _bookingById(id);
    if (b == null) return;
    // Terminal states are mutually exclusive — never resurrect a finished booking.
    if (b.status == BookingStatus.completed ||
        b.status == BookingStatus.noShow ||
        b.status == BookingStatus.cancelled ||
        b.status == BookingStatus.declined) {
      return;
    }
    _setBookingStatus(id, BookingStatus.completed,
        completedAt: DateTime.now());
    _chargeCommission(id); // the app delivered this client → small fee
    if (b.clientName == null) _awardVisitPerk(b); // loyalty pass earned by visit
  }
  // No-show marking records a fee intent (see the no-show shield below), so the
  // existing barber schedule button becomes shield-aware with no UI change.
  void markNoShow(String id) => markNoShowWithCharge(id);

  // ═══════════════════ No-show shield & cancellation policy (#4) ═══════════
  // Protect barber income: cancel <4h before, or no-show, and 50% of the price
  // applies. Nothing is charged up front; high-value/repeat-canceller slots ask
  // for a card-on-file HOLD via a provider (stubbed — no card data here).

  final CancellationPolicy cancellationPolicy = CancellationPolicy.standard;

  /// A slot above this price (USD-ish) is "high value" and asks for a hold.
  static const double _highValueThresholdUsd = 24;

  /// How many times this client has cancelled or no-showed (name-keyed in mock).
  int repeatCancellerCount(String clientName) => _bookings
      .where((b) =>
          b.clientName == clientName &&
          (b.status == BookingStatus.cancelled ||
              b.status == BookingStatus.noShow))
      .length;

  /// Whether a slot should ask for a card-on-file authorization hold.
  bool slotNeedsAuthorization(double servicePriceUsd, {String? clientName}) =>
      servicePriceUsd >= _highValueThresholdUsd ||
      (clientName != null && repeatCancellerCount(clientName) >= 2);

  // Card-on-file is a stub — the provider (Payme/Click/Stripe) owns the real
  // authorization; we only record that a hold exists. No card data is touched.
  bool _hasCardOnFile = false;
  bool get hasCardOnFile => _hasCardOnFile;
  Future<bool> authorizeCardOnFile(String provider) async {
    _hasCardOnFile = true;
    notifyListeners();
    return true;
  }

  void removeCardOnFile() {
    _hasCardOnFile = false;
    notifyListeners();
  }

  /// Policy-aware client cancel. Returns the fee (USD-ish, 0 when free). Records
  /// a late-cancel [ChargeIntent] only when inside the window.
  double cancelBookingWithPolicy(String id) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i == -1) return 0;
    final b = _bookings[i];
    final inside = cancellationPolicy.isInsideWindow(b.dateTime);
    final double feeUsd =
        inside ? cancellationPolicy.feeUsd(b.service.price) : 0.0;
    _bookings[i] = b.copyWith(
      status: BookingStatus.cancelled,
      chargeIntent: inside
          ? ChargeIntent.forFee(
              reason: ChargeReason.lateCancel, amountUsd: feeUsd)
          : null,
    );
    notifyListeners();
    return feeUsd;
  }

  /// Barber marks a no-show and attaches the fee intent.
  void markNoShowWithCharge(String id) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i == -1) return;
    final b = _bookings[i];
    // A served (verified/completed) booking can't be flipped to a no-show.
    if (b.verifiedAt != null || b.status == BookingStatus.completed) return;
    _bookings[i] = b.copyWith(
      status: BookingStatus.noShow,
      chargeIntent: ChargeIntent.forFee(
        reason: ChargeReason.noShow,
        amountUsd: cancellationPolicy.feeUsd(b.service.price),
      ),
    );
    notifyListeners();
  }

  /// Barber waives a recorded fee (goodwill / zero-cost loyalty gesture).
  void waiveChargeIntent(String bookingId) {
    final i = _bookings.indexWhere((b) => b.id == bookingId);
    if (i == -1) return;
    final ci = _bookings[i].chargeIntent;
    if (ci == null) return;
    _bookings[i] = _bookings[i]
        .copyWith(chargeIntent: ci.copyWith(status: ChargeIntentStatus.waived));
    notifyListeners();
  }

  // === Barber's service menu (editable by the barber) ===
  // Seeded from the demo shop so the menu isn't empty, then fully owned by the
  // barber: they can re-price, switch services off, add new ones, or remove.
  late final List<BarberService> _myServices =
      MockData.barbershops.first.services.toList();

  /// The barber's full menu (including switched-off services).
  List<BarberService> get barberServices => List.unmodifiable(_myServices);

  /// Only the services currently switched on — what clients can book.
  List<BarberService> get barberActiveServices =>
      _myServices.where((s) => s.enabled).toList();

  int _svcIndex(String id) => _myServices.indexWhere((s) => s.id == id);

  /// Switch a service on/off without losing it from the menu.
  void toggleService(String id) {
    final i = _svcIndex(id);
    if (i == -1) return;
    _myServices[i] = _myServices[i].copyWith(enabled: !_myServices[i].enabled);
    notifyListeners();
  }

  /// Edit a service's price / duration / name in place.
  void updateService(
    String id, {
    String? name,
    double? price,
    int? durationMinutes,
  }) {
    final i = _svcIndex(id);
    if (i == -1) return;
    _myServices[i] = _myServices[i].copyWith(
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : null,
      price: (price != null && price >= 0) ? price : null,
      durationMinutes:
          (durationMinutes != null && durationMinutes > 0) ? durationMinutes : null,
    );
    notifyListeners();
  }

  /// Add a brand-new service to the menu.
  void addService({
    required String name,
    required double price,
    required int durationMinutes,
    IconData icon = Icons.content_cut_rounded,
  }) {
    _myServices.add(BarberService(
      id: 'svc_user_${_myServices.length}_${name.hashCode}',
      name: name.trim().isEmpty ? 'New service' : name.trim(),
      description: '',
      price: price < 0 ? 0 : price,
      durationMinutes: durationMinutes <= 0 ? 30 : durationMinutes,
      icon: icon,
    ));
    notifyListeners();
  }

  /// Remove a service from the menu entirely.
  void removeService(String id) {
    _myServices.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // === Breaks & lunch (barber blocks their own time) ===
  // Seeded with a daily lunch so the calendar shows the concept immediately;
  // the barber can edit, remove, or add more breaks on any day.
  final List<BarberBreak> _breaks = [
    const BarberBreak(
      id: 'brk_lunch',
      label: 'Lunch',
      startMinutes: 13 * 60,
      durationMinutes: 60,
      daily: true,
    ),
  ];

  /// Breaks/lunch that apply on a given day, earliest first.
  List<BarberBreak> barberBreaksOn(DateTime day) => _breaks
      .where((b) => b.appliesOn(day))
      .toList()
    ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

  /// Add a break/lunch block.
  void addBreak({
    required String label,
    required int startMinutes,
    required int durationMinutes,
    required bool daily,
    DateTime? date,
  }) {
    _breaks.add(BarberBreak(
      id: 'brk_${_breaks.length}_$startMinutes',
      label: label.trim().isEmpty ? 'Break' : label.trim(),
      startMinutes: startMinutes,
      durationMinutes: durationMinutes <= 0 ? 30 : durationMinutes,
      daily: daily,
      date: daily ? null : date,
    ));
    notifyListeners();
  }

  void removeBreak(String id) {
    _breaks.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  // ═══════════════════ Walk-ins & anti-double-booking (#5) ═══════════════════
  // A walk-in is an offline client the barber logs on their own calendar —
  // free forever (Tier 1: 0 commission, no ledger). It's a Booking with
  // [isWalkIn], so it shows on the schedule AND greys the slot for clients.

  /// Log a walk-in on the signed-in barber's calendar. No commission, no ledger.
  /// Returns false if the chosen slot already holds a booking/walk-in
  /// (anti-double-booking, now enforced in BOTH directions).
  bool addWalkIn({
    required DateTime dateTime,
    required String name,
    required BarberService service,
    String? note,
  }) {
    final me = meBarber;
    final aligned = DateTime(dateTime.year, dateTime.month, dateTime.day,
        dateTime.hour, dateTime.minute >= 30 ? 30 : 0);
    if (blockedSlotsFor(shopId: me.shop.id, barberId: me.barber.id, day: dateTime)
        .contains(aligned)) {
      return false;
    }
    _bookings.add(Booking(
      id: 'walkin_${DateTime.now().microsecondsSinceEpoch}',
      barbershop: me.shop,
      barber: me.barber,
      service: service,
      dateTime: dateTime,
      status: BookingStatus.upcoming,
      clientName: name.trim().isEmpty ? 'Walk-in' : name.trim(),
      isWalkIn: true,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    ));
    notifyListeners();
    return true;
  }

  void removeWalkIn(String id) {
    _bookings.removeWhere((b) => b.id == id && b.isWalkIn);
    notifyListeners();
  }

  /// Slot start-times a client must NOT be able to pick for [shopId]/[barberId]
  /// on [day] — the barber's walk-ins + active bookings. This is the
  /// anti-double-booking union the client time-pickers fold into their slots.
  Set<DateTime> blockedSlotsFor({
    required String shopId,
    String? barberId,
    required DateTime day,
  }) {
    final out = <DateTime>{};
    // Block every 30-min slot the interval [start, start+minutes) touches, so a
    // long/combo cut (or a break) occupies its WHOLE duration, not just its start.
    void blockSpan(DateTime start, int minutes) {
      final end = start.add(Duration(minutes: minutes));
      var t = DateTime(start.year, start.month, start.day, start.hour,
          start.minute >= 30 ? 30 : 0);
      while (t.isBefore(end)) {
        out.add(t);
        t = t.add(const Duration(minutes: 30));
      }
    }

    for (final b in _bookings) {
      if (b.barbershop.id != shopId) continue;
      if (barberId != null && b.barber.id != barberId) continue;
      if (!_sameDay(b.dateTime, day)) continue;
      if (b.isWalkIn ||
          b.status == BookingStatus.requested ||
          b.status == BookingStatus.upcoming) {
        blockSpan(b.dateTime, b.service.durationMinutes);
      }
    }
    // The signed-in barber's breaks (lunch, etc.) block only THEIR OWN chair —
    // breaks are stored per-barber (the me-barber), so a colleague at the same
    // shop must not inherit them. Apply when no specific barber is requested or
    // when it's the me-barber being viewed.
    if (shopId == meBarber.shop.id &&
        (barberId == null || barberId == meBarber.barber.id)) {
      for (final br in barberBreaksOn(day)) {
        blockSpan(br.startOn(day), br.durationMinutes);
      }
    }
    return out;
  }

  /// Hours for a given shop. The signed-in barber's custom hours apply ONLY to
  /// the shop they registered at; every other shop uses the default 9–21, so a
  /// barber's schedule can't bound the availability of shops they don't work at.
  (int, int) shopHours(String shopId) =>
      _registeredBarber?.shopId == shopId ? (_workStart, _workEnd) : (9, 21);

  /// Off-days for a given shop (empty for shops the barber doesn't own).
  Set<int> shopOffDays(String shopId) =>
      _registeredBarber?.shopId == shopId ? _offDays : const <int>{};

  // === Calendar sync (stub connection; real two-way OAuth = backend) ===
  bool _googleCalConnected = false;
  bool _appleCalConnected = false;
  bool get googleCalConnected => _googleCalConnected;
  bool get appleCalConnected => _appleCalConnected;
  void setCalendarConnected({bool? google, bool? apple}) {
    if (google != null) _googleCalConnected = google;
    if (apple != null) _appleCalConnected = apple;
    notifyListeners();
  }

  // ═══════════════════ Barber wallet & commission ═══════════════════
  // The "vending machine": the barber pre-loads a small balance and the app
  // deducts a fee when it delivers a booking.
  //
  // WHAT ACTUALLY HAPPENS (see commissionSomFor): a FLAT 5% on every booking
  // made through Fade — first visit or fiftieth — halved to 2.5% for VIP.
  // Only walk-ins the barber logs himself are free, since Fade never handled
  // them. This block used to describe a four-tier scheme where regulars became
  // free after their first visit; that was never implemented, and the barber
  // intro was written from the comment rather than the code, so the app
  // promised "0% forever" and then charged 5% on visit two. If the tiers ever
  // do get built, change commissionSomFor and the copy in the same commit.

  static const int newClientFeePercent = 5;

  // VIP barbers pay HALF the new-client fee (2.5%) — the headline VIP perk.
  // The platform gives up 2.5 points here, but the give-back stays SMALL by
  // design: (1) it only touches brand-new Fade-delivered clients (walk-ins and
  // regulars are already 0%), (2) the monthly VIP subscription dwarfs any
  // realistic monthly discount, and (3) VIP placement drives MORE new-client
  // volume, so 2.5% of a bigger base ≈ 5% of the base — commission revenue
  // holds while the subscription is pure upside. Client-side for now;
  // enforced server-side once the backend lands.
  static const double vipNewClientFeePercent = 2.5;
  double get effectiveNewClientFeePercent =>
      barberVip ? vipNewClientFeePercent : newClientFeePercent.toDouble();

  int _walletSom = 42000;
  int get walletSom => _walletSom;
  bool get walletLow => _walletSom < 12000;

  // ── The three "coins" in the skeuomorphic wallet ──────────────────────
  // Credit = the prepaid spendable balance (walletSom; top-up refills it,
  // commission fees draw from it). Boost packs & VIP settle via an external
  // provider, not this balance. Earned = money made from completed cuts (real,
  // lifetime). Tips = a modest mock (~12% of earned). Total = the sum shown in
  // the wallet pocket; the week-gain drives the "▲ this week" delta line.
  int get walletEarnedSom => Money.toSom(barberTotalEarned);
  int get walletTipsSom => (walletEarnedSom * 0.12).round();
  int get walletTotalSom => _walletSom + walletEarnedSom + walletTipsSom;
  int get walletWeekGainSom => (barberEarnedThisWeekSom * 1.12).round();

  final List<WalletTx> _ledger = [];
  bool _ledgerSeeded = false;
  List<WalletTx> get walletLedger {
    _ensureLedgerSeed();
    return List.unmodifiable(_ledger);
  }

  void _ensureLedgerSeed() {
    if (_ledgerSeeded) return;
    _ledgerSeeded = true;
    final now = DateTime.now();
    _ledger.addAll([
      WalletTx(
          label: 'Top-up',
          amountSom: 50000,
          credit: true,
          at: now.subtract(const Duration(days: 6))),
      WalletTx(
          label: 'Sardor A.',
          sub: 'New-client fee',
          amountSom: 3500,
          credit: false,
          at: now.subtract(const Duration(days: 5))),
      WalletTx(
          label: 'Jasur T.',
          sub: 'New-client fee',
          amountSom: 4500,
          credit: false,
          at: now.subtract(const Duration(days: 3))),
    ]);
  }


  /// Flat commission: every Fade booking pays the platform rate — 5% standard,
  /// 2.5% for VIP. Only manually-logged walk-ins (the barber's own off-platform
  /// clients) are free, since Fade never handled them.
  int commissionSomFor(Booking b) {
    if (b.isWalkIn) return 0;
    return (Money.toSom(b.service.price) * effectiveNewClientFeePercent / 100)
        .round();
  }

  /// The undiscounted 5% fee — used to show a VIP barber what the discount saved.
  int commissionFullSomFor(Booking b) {
    if (b.isWalkIn) return 0;
    return (Money.toSom(b.service.price) * newClientFeePercent / 100).round();
  }

  void _chargeCommission(String id) {
    final b = _bookingById(id);
    if (b == null || b.isWalkIn) return; // off-platform walk-ins never charge
    _ensureLedgerSeed();
    final fee = commissionSomFor(b);
    if (fee <= 0) return;
    _walletSom -= fee;
    if (_walletSom < 0) _walletSom = 0; // never show a negative balance
    final vip = barberVip;
    if (vip) {
      final saved = commissionFullSomFor(b) - fee;
      if (saved > 0) _vipCommissionSavedSom += saved;
    }
    // Every booking is labelled with the rate applied so the barber SEES it.
    _ledger.insert(
      0,
      WalletTx(
        label: b.clientName ?? b.barber.name,
        sub: 'Booking fee · ${vip ? '2.5%' : '5%'} · ${b.service.name}',
        amountSom: fee,
        credit: false,
        at: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Booking? _bookingById(String id) {
    for (final b in _bookings) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Top-up is a provider-handoff stub — no real money moves here.
  void topUpWallet(int som) {
    _ensureLedgerSeed();
    _walletSom += som;
    _ledger.insert(0,
        WalletTx(label: 'Top-up', amountSom: som, credit: true, at: DateTime.now()));
    notifyListeners();
  }

  /// The barber's white-label handle + personal booking link (Tier 3 — a
  /// regular who books via this pays ~0 commission).
  String get barberHandle {
    final name =
        (_registeredBarber?.firstName ?? meBarber.barber.name).toLowerCase();
    final slug = name.replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return slug.isEmpty ? 'barber' : slug;
  }

  // Base host for a barber's public booking link. Change this ONE constant to
  // your deployed landing page (e.g. a free Cloudflare Worker at
  // 'your-name.workers.dev') and every shared link points at the live page.
  static const String bookingLinkBase = 'fade.uz';

  /// Display form (no scheme): fade.uz/b/handle.
  String get barberLink => '$bookingLinkBase/b/$barberHandle';

  /// The full, tappable URL to share/copy — opens the barber's booking page.
  String get barberBookingUrl => 'https://$barberLink';

  /// Slugify any barber's name the same way [barberHandle] does.
  static String handleFor(String name) {
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return slug.isEmpty ? 'barber' : slug;
  }

  /// Resolve a scanned booking code — a full URL, 'fade.uz/b/handle', or a
  /// bare handle — to the shop that barber works at. Null if unknown.
  Barbershop? shopFromBookingCode(String code) {
    final handle = _handleFromCode(code);
    if (handle == null) return null;
    // The signed-in barber's own link points at the shop they work at.
    if (handle == barberHandle) return meBarber.shop;
    for (final shop in MockData.barbershops) {
      for (final b in shop.barbers) {
        if (handleFor(b.name) == handle) return shop;
      }
    }
    return null;
  }

  static String? _handleFromCode(String code) {
    var c = code.trim();
    const marker = '/b/';
    final idx = c.indexOf(marker);
    if (idx >= 0) c = c.substring(idx + marker.length);
    c = c.split('?').first.split('#').first.split('/').first;
    final slug = c.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return slug.isEmpty ? null : slug;
  }

  // ═══════════════════ VIP Turbo Boost (Tier 4) ════════════════════════════
  // The paid accelerator a barber buys once the app proves it delivers clients:
  // gold map pin for their shop, top placement in search, a premium badge, and
  // the top slot on the shop's roster. Purchase hands off to a payment provider
  // (stub) — no real money moves here; the subscription itself is server-side
  // once the backend lands (session-only in the mock).

  // Priced at 199k — deliberately under the 200k "mental barrier" so a busy
  // barber signs up without hesitating.
  static const int vipMonthlySom = 199000;
  // Boosts bundled into the monthly VIP subscription — VIP is a business tool,
  // not a tax: you also get visibility fuel every month.
  static const int vipMonthlyBoosts = 5;
  DateTime? _vipUntil;
  // When the CURRENT continuous VIP period began. "Saved this month" only counts
  // bookings on/after this, so bookings charged the full 5% BEFORE subscribing
  // aren't mis-counted as savings.
  DateTime? _vipSince;
  bool get barberVip =>
      _vipUntil != null && _vipUntil!.isAfter(DateTime.now());
  DateTime? get vipUntil => _vipUntil;

  /// The day a booking counts toward "this month" metrics — its completion day,
  /// falling back to the appointment date for older records with no completedAt.
  DateTime _completionDate(Booking b) => b.completedAt ?? b.dateTime;

  // Running total of what the 2.5% VIP rate saved this barber vs. the full 5%.
  // A small, honest reinforcement — the real VIP payoff is more bookings, not
  // this figure (which is exactly why the platform's give-back stays small).
  int _vipCommissionSavedSom = 0;
  int get vipCommissionSavedSom => _vipCommissionSavedSom;

  /// The VIP "you saved X this month" figure: 2.5 points off every booking this
  /// month. (Break-even vs. the 200k subscription is ~8M so'm of monthly
  /// bookings — above that the barber comes out ahead on fees alone.)
  int get vipMonthlyFeeSavingEstSom {
    if (!barberVip) return 0; // no VIP → nothing was discounted
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    // Only bookings actually charged the 2.5% rate count — completed this month
    // AND on/after the VIP subscription began (pre-subscription cuts paid 5%).
    final from = (_vipSince != null && _vipSince!.isAfter(monthStart))
        ? _vipSince!
        : monthStart;
    final bookedSomThisMonth = _bookings
        .where((b) =>
            !b.isWalkIn &&
            b.status == BookingStatus.completed &&
            !_completionDate(b).isBefore(from))
        .fold<int>(0, (sum, b) => sum + Money.toSom(b.service.price));
    return (bookedSomThisMonth * 2.5 / 100).round();
  }

  // ── The "earn VIP pricing" milestone ──
  // Barbers who complete this many Fade bookings in a month have proven the app
  // delivers — the nudge point where VIP's 2.5% starts paying for itself. It
  // doesn't auto-grant VIP; it's the psychological trigger to subscribe.
  static const int vipMilestoneGoal = 20;
  int get completedBookingsThisMonth {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return _bookings
        .where((b) =>
            !b.isWalkIn &&
            b.status == BookingStatus.completed &&
            !_completionDate(b).isBefore(start))
        .length;
  }

  bool get vipMilestoneReached =>
      completedBookingsThisMonth >= vipMilestoneGoal;

  /// Per-service profitability for the analytics view (a VIP perk): completed
  /// Fade bookings grouped by service, richest first.
  List<({String name, int count, int revenueSom})> serviceBreakdown() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final byName = <String, ({int count, int revenueSom})>{};
    for (final b in _bookings) {
      if (b.isWalkIn || b.status != BookingStatus.completed) continue;
      if (_completionDate(b).isBefore(start)) continue; // "This month" only
      final cur = byName[b.service.name] ?? (count: 0, revenueSom: 0);
      byName[b.service.name] = (
        count: cur.count + 1,
        revenueSom: cur.revenueSom + Money.toSom(b.service.price),
      );
    }
    final list = byName.entries
        .map((e) =>
            (name: e.key, count: e.value.count, revenueSom: e.value.revenueSom))
        .toList()
      ..sort((a, b) => b.revenueSom.compareTo(a.revenueSom));
    return list;
  }

  /// Provider-handoff stub: pretend the provider confirmed the subscription.
  /// Bundles [vipMonthlyBoosts] visibility boosts into the month.
  void activateVipBoost() {
    final wasVip = barberVip;
    final base = wasVip ? _vipUntil! : DateTime.now();
    _vipUntil = base.add(const Duration(days: 30));
    // Mark the start of a fresh subscription period (renewing while still VIP
    // keeps the original start, so the savings window doesn't reset).
    if (!wasVip) _vipSince = DateTime.now();
    _boosts += vipMonthlyBoosts;
    notifyListeners();
  }

  // ── Barber Fuel — pay-as-you-go boosts ("Ups") ──
  // Micro-transactions instead of a subscription: buy a cheap pack of Ups, keep
  // them in the wallet, and spend one to fill a dead hour. An active Up (or VIP)
  // promotes the chair — top of search, gold map pin. Purchases are provider
  // stubs; nothing is server-enforced until the backend lands.
  static const List<BoostPack> boostPacks = [
    BoostPack('starter', 15000, 3),
    BoostPack('growth', 40000, 10),
    BoostPack('pro', 90000, 25),
  ];
  static const Duration boostDuration = Duration(hours: 1);

  int _boosts = 2; // seed a couple so "use a boost" is demoable immediately
  int get boosts => _boosts;

  DateTime? _boostActiveUntil;
  DateTime? get boostActiveUntil => _boostActiveUntil;
  bool get boostActive =>
      _boostActiveUntil != null && _boostActiveUntil!.isAfter(DateTime.now());

  /// The single source of truth for "is this barber promoted right now" — a live
  /// Up OR an active VIP subscription. (A future map/roster can read this to
  /// gold-pin + float them to the top.)
  bool get barberBoosted => boostActive || barberVip;

  /// Kept ONLY for the map's gold pin (wayfinding to your own boosted chair).
  /// Ranking no longer uses shop-level boost — the spotlight is isolated to
  /// the individual barber (see [barberSpotlightTier]), so a paying barber
  /// never floats their non-paying colleagues.
  bool shopIsBoosted(String shopId) =>
      barberBoosted && _registeredBarber?.shopId == shopId;

  // ── Spotlight isolation — status belongs to the individual STYLIST ──
  // The feed and rosters rank barbers, not shops. Demo seed below gives some
  // mock stylists VIP/boost so the hierarchy is visible; the signed-in
  // barber's own profile id reads their REAL wallet state instead (instant,
  // wallet-triggered — no admin in the loop).
  static const Set<String> _seedVipBarbers = {
    'shop1_b3', 'shop2_b1', 'shop4_b2', // demo stylists with a VIP sub
  };
  static const Set<String> _seedBoostedBarbers = {
    'shop2_b1', // demo Tier-1: VIP + live boost (spotlight card)
  };

  /// Does this stylist have an active VIP subscription?
  bool barberIsVip(String barberId) => barberId == meBarber.barber.id
      ? barberVip
      : _seedVipBarbers.contains(barberId);

  /// Is this stylist's own profile boosted right now?
  bool barberIsBoosted(String barberId) => barberId == meBarber.barber.id
      ? boostActive
      : _seedBoostedBarbers.contains(barberId);

  /// Spotlight tier for ranking: 0 = boosted (glowing aura, top),
  /// 1 = VIP, 2 = standard. Strictly per-barber — never inherited by
  /// colleagues at the same shop.
  int barberSpotlightTier(String barberId) => barberIsBoosted(barberId)
      ? 0
      : barberIsVip(barberId)
          ? 1
          : 2;

  /// Buy a Fuel pack — provider-handoff stub; adds Ups to the wallet.
  void buyBoostPack(String packId) {
    final pack = boostPacks.firstWhere((p) => p.id == packId,
        orElse: () => boostPacks.first);
    _boosts += pack.count;
    notifyListeners();
  }

  /// Spend one Up to fill a dead hour — promotes the chair for [boostDuration].
  /// Returns false when out of Ups.
  bool useBoost() {
    if (_boosts <= 0) return false;
    _boosts -= 1;
    final base = boostActive ? _boostActiveUntil! : DateTime.now();
    _boostActiveUntil = base.add(boostDuration);
    notifyListeners();
    return true;
  }

  // ═══════════════════ QR check-in handshake ═══════════════════════════════
  // The client shows a Booking Ticket (dynamic QR); the barber "scans" it to
  // start the appointment. The verified handshake completes the booking AND
  // locks the commission — so a barber can't fake a no-show to dodge the fee.

  // Verified-scan streak (ZERO-COST loyalty), name-keyed like the other counters.
  final Map<String, int> _verifiedScanStreak = {};
  static const int vipStreakGoal = 10; // verified visits → VIP (never a free cut)
  int verifiedScanStreakFor(String clientName) =>
      _verifiedScanStreak[clientName] ?? 0;
  bool isVipClient(String clientName) =>
      verifiedScanStreakFor(clientName) >= vipStreakGoal;

  // 3-strike no-show ban (anti-collusion — clients self-police the scan).
  static const int banStrikeLimit = 3;
  int clientNoShowCount(String clientName) => _bookings
      .where((b) =>
          b.clientName == clientName && b.status == BookingStatus.noShow)
      .length;
  bool clientIsBanned(String clientName) =>
      clientNoShowCount(clientName) >= banStrikeLimit;
  // The current user's own bookings carry clientName==null, so their strikes are
  // tracked separately (real per-user keying arrives with the backend). Held at
  // 0 in the mock — no organic ban path — but the logic is wired.
  final int _selfNoShowCount = 0;
  int get myNoShowCount => _selfNoShowCount;
  bool get iAmBanned => _selfNoShowCount >= banStrikeLimit;

  /// The verified handshake — the ONLY completion path the scan uses. Idempotent
  /// (guards on verifiedAt/completed) so the commission is charged at most once.
  /// Verify + complete a booking. Returns null on success, or a short reason
  /// key when blocked: 'done' (already finished), 'early' (before the slot),
  /// 'credit' (wallet can't cover the fee).
  String? verifyAndComplete(String id) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i == -1) return 'done';
    final b = _bookings[i];
    if (b.verifiedAt != null ||
        b.status == BookingStatus.completed ||
        b.status == BookingStatus.noShow ||
        b.status == BookingStatus.cancelled ||
        b.status == BookingStatus.declined) {
      return 'done';
    }
    // Can't complete before the appointment (15-min grace).
    if (DateTime.now()
        .isBefore(b.dateTime.subtract(const Duration(minutes: 15)))) {
      return 'early';
    }
    // Prepaid credit must cover the platform fee.
    if (_walletSom < commissionSomFor(b)) return 'credit';
    _bookings[i] = b.copyWith(verifiedAt: DateTime.now());
    final name = _bookings[i].clientName;
    if (name != null && !_bookings[i].isWalkIn) {
      _verifiedScanStreak[name] = (_verifiedScanStreak[name] ?? 0) + 1;
    }
    completeBooking(id); // → completed + _chargeCommission, exactly once
    return null;
  }

  /// Today's not-yet-checked-in upcoming bookings the barber can scan. Only
  /// confirmed (upcoming) bookings — a no-showed/cancelled one can't be re-scanned.
  List<Booking> get todayScannable => barberToday
      .where((b) =>
          b.verifiedAt == null && b.status == BookingStatus.upcoming)
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  /// Resolve a scanned ticket's booking id to a checkable booking — INCLUDES
  /// the user's own bookings (clientName == null), which the client ticket QR
  /// encodes. Without this the handshake only ever worked on seeded demo
  /// clients, never on a real client's ticket. Null if not checkable.
  Booking? scannableById(String bookingId) {
    for (final b in _bookings) {
      if (b.id != bookingId) continue;
      if (b.verifiedAt != null || b.status != BookingStatus.upcoming) {
        return null;
      }
      return b;
    }
    return null;
  }

  /// The payload the BARBER's check-in QR encodes. The client scans it, and the
  /// app confirms it matches the barber on their booking before checking in.
  /// (Flipped model: the barber shows a QR, the client scans — not the reverse.)
  String get barberCheckInPayload => 'fade:barber:${meBarber.barber.id}';

  /// Parse a scanned barber QR (`fade:barber:<id>`) to the barber id, or null.
  static String? barberIdFromQr(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 3 && parts[0] == 'fade' && parts[1] == 'barber') {
      return parts[2];
    }
    return null;
  }

  /// Overdue bookings (15+ min past, not checked in) — the no-show fail-safe.
  List<Booking> overdueBookings() {
    final now = DateTime.now();
    return _mine().where((b) => b.overdueAt(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Review gating: you can only review a shop you've actually engaged with (a
  /// verified visit in production; here: any of your own bookings there), so a
  /// barber can't harvest reviews from people who never came.
  bool canReviewShop(String shopId) => _bookings.any((b) =>
      b.clientName == null &&
      b.barbershop.id == shopId &&
      b.status == BookingStatus.completed);

  // === Working hours (barber-configurable) ===
  // Drives the schedule grid's open/close and the bookable slot range.
  int _workStart = 9; // 09:00
  int _workEnd = 21; // 21:00
  int get workStartHour => _workStart;
  int get workEndHour => _workEnd;
  void setWorkingHours(int start, int end) {
    if (start < 0 || end > 24 || end <= start) return;
    _workStart = start;
    _workEnd = end;
    notifyListeners();
    _save();
  }

  // Days off (weekday 1=Mon … 7=Sun). Shown on the shop profile + blocks
  // bookings on those days.
  final Set<int> _offDays = {};
  Set<int> get offDays => Set.unmodifiable(_offDays);
  void toggleOffDay(int weekday) {
    if (_offDays.contains(weekday)) {
      _offDays.remove(weekday);
    } else {
      _offDays.add(weekday);
    }
    notifyListeners();
    _save();
  }

  /// Set the signed-in user up to work AT an existing shop (not as owner) and
  /// flip into barber mode — used by the "choose your barbershop" step.
  void workAtExistingShop(String shopId) {
    final parts = _user.fullName.trim().split(' ');
    registerBarber(RegisteredBarber(
      firstName: parts.isNotEmpty ? parts.first : 'Barber',
      surname: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      age: 25,
      phone: _user.phone,
      shopId: shopId,
      isOwner: false,
      photo: _userPhoto,
    ));
    _save();
  }

  // === The barber's shop: photos + description ===
  final List<Uint8List> _shopPhotos = [];
  List<Uint8List> get shopPhotos => List.unmodifiable(_shopPhotos);
  void addShopPhoto(Uint8List bytes) {
    _shopPhotos.add(bytes);
    notifyListeners();
  }

  void removeShopPhotoAt(int index) {
    if (index >= 0 && index < _shopPhotos.length) {
      _shopPhotos.removeAt(index);
      notifyListeners();
    }
  }

  String _shopDescription = '';
  String get shopDescription => _shopDescription;
  void setShopDescription(String value) {
    _shopDescription = value.trim();
    notifyListeners();
  }

  // Editable shop location — overrides the registered/mock coordinates so the
  // barber can re-pin where their shop actually is.
  double? _shopLat;
  double? _shopLng;
  String? _shopAddr;
  double get shopLat => _shopLat ?? meBarber.shop.lat;
  double get shopLng => _shopLng ?? meBarber.shop.lng;
  String get shopAddress => (_shopAddr != null && _shopAddr!.isNotEmpty)
      ? _shopAddr!
      : meBarber.shop.address;
  void setShopLocation({
    required double lat,
    required double lng,
    String? address,
  }) {
    _shopLat = lat;
    _shopLng = lng;
    if (address != null && address.trim().isNotEmpty) {
      _shopAddr = address.trim();
    }
    notifyListeners();
  }

  /// Seed a couple of demo bookings so the UI has realistic content.
  void _seedBookings() {
    // Start with NO upcoming bookings — the "My Bookings" card only appears
    // once the user actually books. Keep one past cut for loyalty/history.
    final shop5 = MockData.barbershops[4];
    _bookings.add(
      Booking(
        id: 'b_seed_3',
        barbershop: shop5,
        barber: shop5.barbers[1],
        service: shop5.services[3],
        dateTime: DateTime.now().subtract(const Duration(days: 21)),
        status: BookingStatus.completed,
      ),
    );

    // Barber-side demo content for the signed-in barber, at THEIR shop.
    final me = meBarber;
    _seedBarberDemo(me.shop, me.barber);
  }

  /// Other clients' requests + confirmed/past cuts for the signed-in barber,
  /// attached to [shop]. Parametrised so a registered barber's demo content
  /// follows them to whatever shop they joined (not always shop1).
  void _seedBarberDemo(Barbershop shop, Barber barber) {
    final now = DateTime.now();
    DateTime at(int addDays, int hour) {
      final d = now.add(Duration(days: addDays));
      return DateTime(d.year, d.month, d.day, hour, 0);
    }

    void seedB(String id, String client, int svc, int days, int hour,
        BookingStatus st) {
      _bookings.add(Booking(
        id: id,
        barbershop: shop,
        barber: barber,
        service: shop.services[svc % shop.services.length],
        dateTime: at(days, hour),
        status: st,
        clientName: client,
      ));
    }

    seedB('req_0', 'Aziz Karimov', 0, 0, 15, BookingStatus.requested);
    seedB('req_1', 'Bobur Aliyev', 2, 0, 17, BookingStatus.requested);
    seedB('req_2', 'Jasur Tursunov', 1, 1, 11, BookingStatus.requested);
    seedB('conf_0', 'Davron Saidov', 0, 0, 13, BookingStatus.upcoming);
    seedB('conf_1', 'Sardor Mirzaev', 3, 1, 16, BookingStatus.upcoming);

    // Completed history — drives the history screen, 7-day chart & earnings.
    seedB('done_0', 'Lisa T.', 0, 0, 14, BookingStatus.completed);
    seedB('done_1', 'Marcus K.', 1, 0, 12, BookingStatus.completed);
    seedB('done_2', 'Jennifer L.', 2, -1, 16, BookingStatus.completed);
    seedB('done_3', 'Aziz R.', 4, -1, 10, BookingStatus.completed);
    seedB('done_4', 'Bek T.', 1, -2, 11, BookingStatus.completed);
    seedB('done_5', 'Sardor A.', 3, -3, 15, BookingStatus.completed);
    seedB('done_6', 'Otabek Y.', 0, -5, 13, BookingStatus.completed);
    seedB('done_7', 'Dilshod U.', 2, -9, 17, BookingStatus.completed);
    seedB('done_8', 'Eldor N.', 4, -14, 13, BookingStatus.completed);
    seedB('done_9', 'Kamol B.', 1, -20, 12, BookingStatus.completed);

    // Seed a few opening messages so the barber Messages screen isn't empty —
    // a couple of clients reaching out (unread, since they spoke last).
    _barberChats['Aziz Karimov'] = [
      ChatMessage(
        text: 'Salom! Just sent a booking request for today — '
            'are you free around 3? ✂️',
        mine: false,
        at: at(0, 9),
      ),
    ];
    _barberChats['Davron Saidov'] = [
      ChatMessage(
        text: 'See you later today, thanks for confirming 🙏',
        mine: false,
        at: at(0, 8),
      ),
    ];
  }

  /// After a barber registers (or is restored from disk), move their demo
  /// bookings onto the shop they actually attached to, so the dashboard,
  /// agenda and earnings all reference one consistent shop.
  void _reseedBarberDemoForRegistered() {
    if (_registeredBarber == null) return;
    final me = meBarber;
    _bookings.removeWhere(
        (b) => b.clientName != null && b.barber.id == _meBarberId);
    _seedBarberDemo(me.shop, me.barber);
  }

  AppUser _user = MockData.currentUser;
  AppUser get user => _user;

  bool _isDarkMode = false; // app opens in the light theme; toggle → navy
  bool get isDarkMode => _isDarkMode;

  // === Auth ===
  // One source of truth. The old pair of bools is now DERIVED from it, so they
  // can never drift apart — and nothing can flip "authenticated" on without an
  // identity, because only signInWithIdentity() moves this off `anonymous`.
  AuthStage _stage = AuthStage.anonymous;
  AuthStage get authStage => _stage;

  AuthMethod? _method;
  AuthMethod? get authMethod => _method;

  /// True once a provider has vouched for this person. Read-only by design:
  /// there is deliberately no setter, so no screen can grant itself a session.
  bool get isAuthenticated => _stage != AuthStage.anonymous;

  /// True once identity is proved AND setup is finished — i.e. the app opens.
  bool get hasCompletedOnboarding => _stage == AuthStage.ready;

  // === My Barber ===
  // We persist (shopId, barberId) so we can re-fetch the full Barber
  // and Barbershop objects on demand.
  String? _myBarberShopId = 'shop1';
  String? _myBarberId = 'shop1_b1';

  /// True if the user has chosen a personal barber.
  bool get hasMyBarber => _myBarberId != null && _myBarberShopId != null;

  /// Resolve the saved (shop, barber) pair, or null if none set or not found.
  BarberRef? get myBarber {
    if (_myBarberId == null || _myBarberShopId == null) return null;
    final shop = MockData.barbershops.firstWhere(
      (s) => s.id == _myBarberShopId,
      orElse: () => MockData.barbershops.first,
    );
    final barber = shop.barbers.firstWhere(
      (b) => b.id == _myBarberId,
      orElse: () => shop.barbers.first,
    );
    return BarberRef(shop: shop, barber: barber);
  }

  /// Set or replace the user's chosen barber.
  void setMyBarber({required String shopId, required String barberId}) {
    _myBarberShopId = shopId;
    _myBarberId = barberId;
    notifyListeners();
  }

  /// Clear the user's chosen barber.
  void clearMyBarber() {
    _myBarberShopId = null;
    _myBarberId = null;
    notifyListeners();
  }

  /// True when the given barber is currently saved as "my barber".
  bool isMyBarber(String barberId) => _myBarberId == barberId;

  // === Desired hairstyle ===
  // The look the user picked in the Style Studio. We store the id and
  // resolve the full Hairstyle on demand so the booking flow can show it.
  String? _desiredStyleId;

  String? get desiredStyleId => _desiredStyleId;
  bool get hasDesiredStyle => _desiredStyleId != null;

  void setDesiredStyle(String styleId) {
    _desiredStyleId = styleId;
    notifyListeners();
  }

  void clearDesiredStyle() {
    _desiredStyleId = null;
    notifyListeners();
  }

  // === Preferences / profile extras ===
  String? _address;
  String? get address => _address;
  void setAddress(String? value) {
    _address = (value == null || value.trim().isEmpty) ? null : value.trim();
    _save();
    notifyListeners();
  }

  bool _remindersOn = true;
  bool get remindersOn => _remindersOn;
  void setReminders(bool value) {
    _remindersOn = value;
    _save();
    notifyListeners();
  }

  // === Schedule view: timeline ⇄ booking-style slots (persisted — the
  // barber keeps whichever he likes) ===
  bool _scheduleSlotsView = false;
  bool get scheduleSlotsView => _scheduleSlotsView;
  void setScheduleSlotsView(bool v) {
    if (_scheduleSlotsView == v) return;
    _scheduleSlotsView = v;
    notifyListeners();
    _save();
  }

  // === Feedback / bug reports ===
  // Stored locally (and kept across restarts) so nothing a user writes is
  // lost; when the Supabase backend lands these sync to a `feedback` table.
  final List<String> _feedback = [];
  int get feedbackCount => _feedback.length;

  Future<void> submitFeedback({
    required String category,
    required String message,
    String? contact,
  }) async {
    final entry =
        '${DateTime.now().toIso8601String()}|$category|${contact ?? ''}|$message';
    _feedback.add(entry);
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList('feedback', _feedback);
    notifyListeners();
  }

  // === Earned perks (variable-reward loop) ===
  // The confirmation screen's "YOU JUST EARNED" pass is real now: perks are
  // stored here (persisted), listed in the home bonus sheet, and cleared when
  // used. Ids: 'priority' | 'skip' | 'double'.
  final List<String> _perks = [];
  List<String> get perks => List.unmodifiable(_perks);

  void addPerk(String id) {
    _perks.add(id);
    _save();
    notifyListeners();
  }

  // Loyalty passes are EARNED by completing a visit, not by requesting a
  // booking — dedup by booking id so a booking grants at most one, ever.
  final Set<String> _awardedPerkBookings = {};
  void _awardVisitPerk(Booking b) {
    if (_awardedPerkBookings.contains(b.id)) return;
    _awardedPerkBookings.add(b.id);
    final roll = b.id.hashCode.abs() % 100;
    final perk = roll < 8
        ? 'priority'
        : roll < 22
            ? 'skip'
            : roll < 42
                ? 'double'
                : null;
    if (perk != null) _perks.add(perk);
  }

  /// The ONE loyalty metric shown across the app — completed visits toward VIP
  /// (no cosmetic baseline), so the home sheet, ticket, and punch card agree.
  int get loyaltyVisits => _bookings
      .where((b) => b.clientName == null && b.status == BookingStatus.completed)
      .length;

  AppLanguage _language = AppLanguage.en;
  AppLanguage get language => _language;
  void setLanguage(AppLanguage value) {
    _language = value;
    // Keep date/time formatting in step with the UI language (weekday/month
    // names) — otherwise dates stay in whatever locale was set at startup.
    Intl.defaultLocale = value.name;
    notifyListeners();
    _save();
  }

  // === AI engine (persisted so it survives a relaunch) ===
  // Google Gemini image key — optional premium route. Empty by default.
  String _geminiKey = '';
  String get geminiKey => _geminiKey;
  void setGeminiKey(String value) {
    _geminiKey = value.trim();
    notifyListeners();
  }

  // The free image-AI endpoint (Cloudflare worker). Ships pointing at the
  // deployed worker so real renders work out of the box — no setup, no key.
  // Editable in-app (AI → Connect AI) and persisted across launches.
  String _aiEndpoint = 'https://wispy-limit-2937.gulamovmuhammad44.workers.dev';
  String get aiEndpoint => _aiEndpoint;
  void setAiEndpoint(String value) {
    _aiEndpoint = value.trim();
    notifyListeners();
  }

  /// True when any real AI engine (free worker or Gemini key) is connected.
  bool get hasAiKey =>
      _aiEndpoint.trim().isNotEmpty || _geminiKey.trim().isNotEmpty;

  /// Whether the user has agreed, once, to have their selfie sent to the AI
  /// service. The upload leaves the device, so it must not happen silently —
  /// the first render asks; after that it's remembered.
  bool _aiConsent = false;
  bool get aiConsent => _aiConsent;
  void grantAiConsent() {
    if (_aiConsent) return;
    _aiConsent = true;
    notifyListeners();
  }

  // === Favourites ===
  final Set<String> _favouriteShopIds = {'shop2', 'shop5'};
  Set<String> get favouriteShopIds => Set.unmodifiable(_favouriteShopIds);
  bool isFavourite(String shopId) => _favouriteShopIds.contains(shopId);
  void toggleFavourite(String shopId) {
    if (_favouriteShopIds.contains(shopId)) {
      _favouriteShopIds.remove(shopId);
    } else {
      _favouriteShopIds.add(shopId);
    }
    notifyListeners();
  }

  // === Bookings ===
  final List<Booking> _bookings = [];
  List<Booking> get bookings => List.unmodifiable(_bookings);

  List<Booking> bookingsByStatus(BookingStatus status) =>
      _bookings
          .where((b) => b.status == status && b.clientName == null)
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  /// Total completed cuts (used for stats / membership card).
  int get totalCuts =>
      _bookings
          .where((b) =>
              b.status == BookingStatus.completed && b.clientName == null)
          .length +
      11;

  /// "Member since" date — user joined when account was created.
  /// In mock data, treat 2024-03-12 as the member-since date.
  DateTime get memberSince => DateTime(2024, 3, 12);

  // === Dual-key reviews ===
  // Shop reviews (cleanliness/vibe) belong to the LOCATION; barber reviews
  // (talent) are keyed by barberId so they TRAVEL with the barber across shops.
  final Map<String, List<Review>> _shopReviews = {};
  final Map<String, List<Review>> _barberReviews = {};

  /// Back-compat: a shop's user-written reviews.
  List<Review> userReviewsFor(String shopId) =>
      List.unmodifiable(_shopReviews[shopId] ?? const <Review>[]);
  List<Review> barberReviewsFor(String barberId) =>
      List.unmodifiable(_barberReviews[barberId] ?? const <Review>[]);

  /// Back-compat: legacy single-axis add routes to the shop store.
  void addReview(String shopId, Review review) {
    (_shopReviews[shopId] ??= <Review>[]).insert(0, review);
    notifyListeners();
  }

  /// The one write entry point — splits a submitted review across the two
  /// stores. Only the rated axis is stored, so a shop-only or barber-only
  /// review never leaves a phantom 0-star card in the other list.
  void addDualReview({
    required String shopId,
    required String barberId,
    required String barberName,
    double? shopStars,
    String? shopText,
    double? barberStars,
    String? barberText,
  }) {
    final now = DateTime.now();
    if (shopStars != null) {
      (_shopReviews[shopId] ??= <Review>[]).insert(
        0,
        Review(
          id: 'rv_s_${now.microsecondsSinceEpoch}',
          author: _user.fullName,
          rating: shopStars,
          comment: shopText?.trim() ?? '',
          date: now,
        ),
      );
    }
    if (barberStars != null) {
      (_barberReviews[barberId] ??= <Review>[]).insert(
        0,
        Review(
          id: 'rv_b_${now.microsecondsSinceEpoch}',
          author: _user.fullName,
          rating: 0,
          comment: '',
          date: now,
          barberId: barberId,
          barberName: barberName,
          barberRating: barberStars,
          barberComment: barberText?.trim(),
        ),
      );
    }
    notifyListeners();
  }

  /// Shop running average (seed blended with user shop-reviews) — owned by the
  /// LOCATION. Returns the seed (may be 0 for a brand-new shop) when there are
  /// no user reviews.
  double shopRating(Barbershop shop) {
    final u = _shopReviews[shop.id] ?? const <Review>[];
    if (u.isEmpty) return shop.rating;
    final n = shop.reviewCount;
    final sum = shop.rating * n + u.fold(0.0, (s, r) => s + r.rating);
    return sum / (n + u.length);
  }

  int shopReviewCount(Barbershop shop) =>
      shop.reviewCount + (_shopReviews[shop.id]?.length ?? 0);

  /// Barber talent average — computed from _barberReviews so it TRAVELS with
  /// the barber to whatever shop they join.
  double barberTalentRating(Barber barber) {
    final rated = (_barberReviews[barber.id] ?? const <Review>[])
        .where((r) => r.barberRating != null)
        .toList();
    if (rated.isEmpty) return barber.rating;
    final n = barber.reviewCount;
    final sum =
        barber.rating * n + rated.fold(0.0, (s, r) => s + r.barberRating!);
    return sum / (n + rated.length);
  }

  int barberTalentCount(Barber barber) =>
      barber.reviewCount +
      (_barberReviews[barber.id]?.where((r) => r.barberRating != null).length ??
          0);

  // Whether the location-permission explainer has been shown this session,
  // so we only auto-prompt once.
  bool _locationPromptShown = false;
  bool get locationPromptShown => _locationPromptShown;
  void markLocationPromptShown() {
    if (_locationPromptShown) return;
    _locationPromptShown = true;
    // Persist without a UI rebuild (no notify) so the explainer only auto-shows
    // once, ever — not once per cold start.
    _save();
  }

  // === Persistence (shared_preferences) ===
  // Saves the profile + key prefs so the barber never re-enters their details
  // on relaunch. Any state change schedules a debounced save; `load()` restores
  // it on launch (called before runApp).
  bool _loaded = false;
  bool _saveQueued = false;

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (_loaded && !_saveQueued) {
      _saveQueued = true;
      Future.microtask(() {
        _saveQueued = false;
        _save();
      });
    }
  }

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    // Auth stage + the provider that vouched. Read together: a stage with no
    // method means the record is broken (or hand-edited), so we distrust it and
    // fall back to anonymous. No proof, no session.
    final rawStage = sp.getString('auth_stage');
    _stage = AuthStage.values.firstWhere(
      (s) => s.name == rawStage,
      orElse: () => AuthStage.anonymous,
    );
    final rawMethod = sp.getString('auth_method');
    _method = AuthMethod.values
        .where((m) => m.name == rawMethod)
        .cast<AuthMethod?>()
        .firstWhere((_) => true, orElse: () => null);
    if (_stage != AuthStage.anonymous && _method == null) {
      _stage = AuthStage.anonymous;
    }
    // Legacy installs are deliberately NOT migrated. Those identities were
    // created by typing a name; carrying them across would defeat the very
    // change that removes them. They re-authenticate once via Telegram, and
    // keep their bookings/chats/wallet — this is a re-auth, not a sign-out.
    await sp.remove('onboarded');
    await sp.remove('authed');
    _barberOnboarded = sp.getBool('barberOnboarded') ?? _barberOnboarded;
    _payMethod = sp.getString('payMethod') ?? _payMethod;
    _offDays
      ..clear()
      ..addAll((sp.getStringList('offDays') ?? const [])
          .map(int.tryParse)
          .whereType<int>());
    final role = sp.getString('role');
    if (role != null) {
      _activeRole = role == 'barber' ? AppRole.barber : AppRole.client;
    }
    _feedback
      ..clear()
      ..addAll(sp.getStringList('feedback') ?? const []);
    _scheduleSlotsView = sp.getBool('schedSlots') ?? _scheduleSlotsView;
    _address = sp.getString('address');
    _remindersOn = sp.getBool('reminders') ?? _remindersOn;
    _perks
      ..clear()
      ..addAll(sp.getStringList('perks') ?? const []);
    _awardedPerkBookings
      ..clear()
      ..addAll(sp.getStringList('awardedPerks') ?? const []);
    final lang = sp.getString('lang');
    if (lang != null) {
      _language = AppLanguage.values
          .firstWhere((l) => l.name == lang, orElse: () => _language);
    }
    _isDarkMode = sp.getBool('dark') ?? _isDarkMode;
    _workStart = sp.getInt('workStart') ?? _workStart;
    _workEnd = sp.getInt('workEnd') ?? _workEnd;
    _weeklyGoalSom = sp.getInt('goal') ?? _weeklyGoalSom;
    _shopDescription = sp.getString('shopDesc') ?? _shopDescription;
    final sLat = sp.getDouble('shopLat');
    final sLng = sp.getDouble('shopLng');
    if (sLat != null && sLng != null) {
      _shopLat = sLat;
      _shopLng = sLng;
      _shopAddr = sp.getString('shopAddr');
    }
    final rbShop = sp.getString('rb_shopId');
    if (rbShop != null) {
      _registeredBarber = RegisteredBarber(
        firstName: sp.getString('rb_first') ?? '',
        surname: sp.getString('rb_surname') ?? '',
        age: sp.getInt('rb_age') ?? 0,
        phone: sp.getString('rb_phone') ?? '',
        shopId: rbShop,
        isOwner: sp.getBool('rb_owner') ?? true,
        photo: _decodePhoto(sp.getString('rb_photo')),
      );
      // Move the barber demo content onto the shop they're attached to.
      _reseedBarberDemoForRegistered();
    }
    // Restore the profile ONLY for a real session; an anonymous install has no
    // profile to restore and must not inherit the mock user's details.
    if (_stage != AuthStage.anonymous) {
      _user = AppUser(
        // cl_id is what makes this person unique. It was never persisted
        // before, so `id` silently stayed MockData.currentUser.id ('u1').
        id: sp.getString('cl_id') ?? _user.id,
        fullName: sp.getString('cl_name') ?? _user.fullName,
        email: sp.getString('cl_email') ?? _user.email,
        phone: sp.getString('cl_phone') ?? _user.phone,
        avatarUrl: sp.getString('cl_avatar') ?? _user.avatarUrl,
      );
    } else {
      _user = AppUser.empty;
    }
    _userPhoto = _decodePhoto(sp.getString('cl_photo'));
    _aiEndpoint = sp.getString('aiEndpoint') ?? _aiEndpoint;
    _geminiKey = sp.getString('geminiKey') ?? _geminiKey;
    _aiConsent = sp.getBool('aiConsent') ?? _aiConsent;
    // Restore the user's own bookings, skipping any id already seeded.
    final raw = sp.getString('bookings');
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final existing = _bookings.map((b) => b.id).toSet();
        for (final m in list) {
          final b = _bookingFromMap(m);
          if (b != null && existing.add(b.id)) {
            _bookings.add(b);
            // Give the restored conversation its welcome note so the Messages
            // tab isn't an empty thread after a relaunch.
            _chats.putIfAbsent(
              b.barber.id,
              () => [
                ChatMessage(
                  text: 'Thanks for booking ✂️ Message me here anytime to '
                      'rebook or ask anything.',
                  mine: false,
                  at: b.dateTime,
                ),
              ],
            );
          }
        }
      } catch (_) {
        // Corrupt cache — fall back to the seeded bookings.
      }
    }
    // ── Wallet / boosts / VIP / loyalty — durable, like bookings. ──
    _walletSom = sp.getInt('walletSom') ?? _walletSom;
    _boosts = sp.getInt('boosts') ?? _boosts;
    _vipCommissionSavedSom = sp.getInt('vipSaved') ?? _vipCommissionSavedSom;
    _vipUntil = _readEpoch(sp, 'vipUntil');
    _boostActiveUntil = _readEpoch(sp, 'boostUntil');
    final mbShop = sp.getString('myBarberShop');
    if (mbShop != null) _myBarberShopId = mbShop.isEmpty ? null : mbShop;
    final mbId = sp.getString('myBarberId');
    if (mbId != null) _myBarberId = mbId.isEmpty ? null : mbId;
    final vscan = sp.getString('vscan');
    if (vscan != null && vscan.isNotEmpty) {
      try {
        _verifiedScanStreak
          ..clear()
          ..addAll((jsonDecode(vscan) as Map)
              .map((k, v) => MapEntry(k as String, (v as num).toInt())));
      } catch (_) {}
    }
    _ledgerSeeded = sp.getBool('ledgerSeeded') ?? _ledgerSeeded;
    final ledgerRaw = sp.getString('ledger');
    if (ledgerRaw != null && ledgerRaw.isNotEmpty) {
      try {
        _ledger
          ..clear()
          ..addAll((jsonDecode(ledgerRaw) as List)
              .cast<Map<String, dynamic>>()
              .map(_txFromMap));
      } catch (_) {}
    }
    final svcRaw = sp.getString('services');
    if (svcRaw != null && svcRaw.isNotEmpty) {
      try {
        final list = (jsonDecode(svcRaw) as List)
            .cast<Map<String, dynamic>>()
            .map(_serviceFromMap)
            .toList();
        if (list.isNotEmpty) {
          _myServices
            ..clear()
            ..addAll(list);
        }
      } catch (_) {}
    }
    final brkRaw = sp.getString('breaks');
    if (brkRaw != null && brkRaw.isNotEmpty) {
      try {
        _breaks
          ..clear()
          ..addAll((jsonDecode(brkRaw) as List)
              .cast<Map<String, dynamic>>()
              .map(_breakFromMap));
      } catch (_) {}
    }
    // Favourites — honor a stored (possibly empty) list over the seed defaults.
    final fav = sp.getStringList('favShops');
    if (fav != null) {
      _favouriteShopIds
        ..clear()
        ..addAll(fav);
    }
    _readReviewMap(_shopReviews, sp.getString('shopReviews'));
    _readReviewMap(_barberReviews, sp.getString('barberReviews'));
    final photos = sp.getStringList('shopPhotos');
    if (photos != null) {
      try {
        _shopPhotos
          ..clear()
          ..addAll(photos.map(base64Decode));
      } catch (_) {}
    }
    _locationPromptShown = sp.getBool('locPrompt') ?? _locationPromptShown;
    final ds = sp.getString('desiredStyle');
    if (ds != null) _desiredStyleId = ds.isEmpty ? null : ds;
    _vipSince = _readEpoch(sp, 'vipSince');
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('auth_stage', _stage.name);
    if (_method != null) {
      await sp.setString('auth_method', _method!.name);
    } else {
      await sp.remove('auth_method');
    }
    await sp.setBool('barberOnboarded', _barberOnboarded);
    await sp.setString('payMethod', _payMethod);
    await sp.setStringList(
        'offDays', _offDays.map((d) => d.toString()).toList());
    await sp.setString('role', _activeRole.name);
    await sp.setString('lang', _language.name);
    await sp.setBool('dark', _isDarkMode);
    await sp.setBool('schedSlots', _scheduleSlotsView);
    await sp.setInt('workStart', _workStart);
    await sp.setInt('workEnd', _workEnd);
    await sp.setInt('goal', _weeklyGoalSom);
    await sp.setString('shopDesc', _shopDescription);
    if (_shopLat != null && _shopLng != null) {
      await sp.setDouble('shopLat', _shopLat!);
      await sp.setDouble('shopLng', _shopLng!);
      await sp.setString('shopAddr', _shopAddr ?? '');
    }
    final rb = _registeredBarber;
    if (rb != null) {
      await sp.setString('rb_first', rb.firstName);
      await sp.setString('rb_surname', rb.surname);
      await sp.setInt('rb_age', rb.age);
      await sp.setString('rb_phone', rb.phone);
      await sp.setString('rb_shopId', rb.shopId);
      await sp.setBool('rb_owner', rb.isOwner);
      await _putPhoto(sp, 'rb_photo', rb.photo);
    } else {
      for (final k in [
        'rb_first',
        'rb_surname',
        'rb_age',
        'rb_phone',
        'rb_shopId',
        'rb_owner',
        'rb_photo',
      ]) {
        await sp.remove(k);
      }
    }
    // cl_id is the provider-verified identity key ('tg_<id>' / 'g_<email>').
    // Without it the restored user silently reverted to the mock id 'u1'.
    await sp.setString('cl_id', _user.id);
    await sp.setString('cl_name', _user.fullName);
    await sp.setString('cl_email', _user.email);
    await sp.setString('cl_phone', _user.phone);
    if (_user.avatarUrl != null) {
      await sp.setString('cl_avatar', _user.avatarUrl!);
    } else {
      await sp.remove('cl_avatar');
    }
    await _putPhoto(sp, 'cl_photo', _userPhoto);
    // Profile extras — the home address, reminder preference, and earned
    // perks survive restarts (they're all promised to the user as "saved").
    if (_address == null) {
      await sp.remove('address');
    } else {
      await sp.setString('address', _address!);
    }
    await sp.setBool('reminders', _remindersOn);
    await sp.setStringList('perks', _perks);
    await sp.setString('aiEndpoint', _aiEndpoint);
    await sp.setString('geminiKey', _geminiKey);
    await sp.setBool('aiConsent', _aiConsent);
    // Persist the user's OWN bookings (clientName == null) so appointments
    // survive a relaunch. Barber-side demo bookings are re-seeded each launch,
    // so we deliberately don't store them.
    final mine =
        _bookings.where((b) => b.clientName == null).map(_bookingToMap).toList();
    await sp.setString('bookings', jsonEncode(mine));
    // ── Wallet / boosts / VIP / loyalty — durable, like bookings. ──
    await sp.setInt('walletSom', _walletSom);
    await sp.setInt('boosts', _boosts);
    await sp.setInt('vipSaved', _vipCommissionSavedSom);
    await _putEpoch(sp, 'vipUntil', _vipUntil);
    await _putEpoch(sp, 'boostUntil', _boostActiveUntil);
    await sp.setString('myBarberShop', _myBarberShopId ?? '');
    await sp.setString('myBarberId', _myBarberId ?? '');
    await sp.setString('vscan', jsonEncode(_verifiedScanStreak));
    await sp.setBool('ledgerSeeded', _ledgerSeeded);
    await sp.setString('ledger', jsonEncode(_ledger.map(_txToMap).toList()));
    await sp.setString(
        'services', jsonEncode(_myServices.map(_serviceToMap).toList()));
    await sp.setString('breaks', jsonEncode(_breaks.map(_breakToMap).toList()));
    await sp.setStringList('awardedPerks', _awardedPerkBookings.toList());
    // Favourites, user reviews, shop gallery photos, the one-time location
    // prompt flag, the pending desired style, and the VIP-since marker — all
    // durable so they survive a relaunch like the rest of the user's content.
    await sp.setStringList('favShops', _favouriteShopIds.toList());
    await sp.setString(
        'shopReviews',
        jsonEncode(_shopReviews
            .map((k, v) => MapEntry(k, v.map((r) => r.toMap()).toList()))));
    await sp.setString(
        'barberReviews',
        jsonEncode(_barberReviews
            .map((k, v) => MapEntry(k, v.map((r) => r.toMap()).toList()))));
    await sp.setStringList(
        'shopPhotos', _shopPhotos.map(base64Encode).toList());
    await sp.setBool('locPrompt', _locationPromptShown);
    await sp.setString('desiredStyle', _desiredStyleId ?? '');
    await _putEpoch(sp, 'vipSince', _vipSince);
  }

  static void _readReviewMap(Map<String, List<Review>> target, String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map;
      target.clear();
      decoded.forEach((k, v) {
        target[k as String] = (v as List)
            .map((m) => Review.fromMap((m as Map).cast<String, dynamic>()))
            .toList();
      });
    } catch (_) {}
  }

  static Future<void> _putEpoch(
      SharedPreferences sp, String key, DateTime? d) async {
    if (d == null) {
      await sp.remove(key);
    } else {
      await sp.setInt(key, d.millisecondsSinceEpoch);
    }
  }

  static DateTime? _readEpoch(SharedPreferences sp, String key) {
    final v = sp.getInt(key);
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }

  static Map<String, dynamic> _txToMap(WalletTx t) => {
        'l': t.label,
        'a': t.amountSom,
        'c': t.credit,
        't': t.at.millisecondsSinceEpoch,
        's': t.sub,
      };
  static WalletTx _txFromMap(Map<String, dynamic> m) => WalletTx(
        // Tolerant casts: a single malformed/partial row must not throw and
        // discard the ENTIRE saved ledger (the decode runs inside one try).
        label: (m['l'] as String?) ?? '',
        amountSom: (m['a'] as num?)?.toInt() ?? 0,
        credit: (m['c'] as bool?) ?? false,
        at: DateTime.fromMillisecondsSinceEpoch((m['t'] as num?)?.toInt() ?? 0),
        sub: m['s'] as String?,
      );

  static Map<String, dynamic> _serviceToMap(BarberService s) => {
        'id': s.id,
        'n': s.name,
        'd': s.description,
        'p': s.price,
        'm': s.durationMinutes,
        'i': s.icon.codePoint,
        'e': s.enabled,
      };
  static BarberService _serviceFromMap(Map<String, dynamic> m) => BarberService(
        id: m['id'] as String,
        name: m['n'] as String,
        description: (m['d'] as String?) ?? '',
        price: (m['p'] as num).toDouble(),
        durationMinutes: (m['m'] as num).toInt(),
        // Map the stored codepoint back to a CONST icon so release-mode icon
        // tree-shaking still works (a runtime IconData(...) breaks the build).
        icon: _iconForCode((m['i'] as num).toInt()),
        enabled: (m['e'] as bool?) ?? true,
      );

  // The fixed palette of service icons used across the app.
  static const List<IconData> _serviceIconPalette = [
    Icons.content_cut_rounded,
    Icons.face_retouching_natural_rounded,
    Icons.water_drop_rounded,
    Icons.palette_rounded,
    Icons.child_care_rounded,
    Icons.auto_awesome_rounded,
  ];
  static IconData _iconForCode(int code) {
    for (final ic in _serviceIconPalette) {
      if (ic.codePoint == code) return ic;
    }
    return Icons.content_cut_rounded;
  }

  static Map<String, dynamic> _breakToMap(BarberBreak b) => {
        'id': b.id,
        'l': b.label,
        's': b.startMinutes,
        'm': b.durationMinutes,
        'daily': b.daily,
        'date': b.date?.millisecondsSinceEpoch,
      };
  static BarberBreak _breakFromMap(Map<String, dynamic> m) => BarberBreak(
        id: m['id'] as String,
        label: m['l'] as String,
        startMinutes: (m['s'] as num).toInt(),
        durationMinutes: (m['m'] as num).toInt(),
        daily: m['daily'] as bool,
        date: m['date'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((m['date'] as num).toInt()),
      );

  static Map<String, dynamic> _bookingToMap(Booking b) => {
        'id': b.id,
        'shopId': b.barbershop.id,
        'barberId': b.barber.id,
        's_id': b.service.id,
        's_name': b.service.name,
        's_price': b.service.price,
        's_dur': b.service.durationMinutes,
        'at': b.dateTime.millisecondsSinceEpoch,
        'st': b.status.index,
        'note': b.note,
        'ca': b.completedAt?.millisecondsSinceEpoch,
      };

  /// Rehydrate a stored booking, resolving the shop/barber from mock data by id.
  /// The service is rebuilt from its stored snapshot (so combined "Haircut +
  /// Beard" prices survive) with a const icon — never a dynamic [IconData],
  /// which would break release icon tree-shaking.
  static Booking? _bookingFromMap(Map<String, dynamic> m) {
    try {
      final shop = MockData.barbershops.firstWhere(
        (s) => s.id == m['shopId'],
        orElse: () => MockData.barbershops.first,
      );
      final barber = shop.barbers.firstWhere(
        (b) => b.id == m['barberId'],
        orElse: () => shop.barbers.first,
      );
      return Booking(
        id: m['id'] as String,
        barbershop: shop,
        barber: barber,
        service: BarberService(
          id: (m['s_id'] as String?) ?? 'svc',
          name: (m['s_name'] as String?) ?? 'Service',
          description: '',
          price: (m['s_price'] as num?)?.toDouble() ?? 0,
          durationMinutes: (m['s_dur'] as num?)?.toInt() ?? 30,
          icon: Icons.content_cut_rounded,
        ),
        dateTime:
            DateTime.fromMillisecondsSinceEpoch((m['at'] as num).toInt()),
        status: BookingStatus.values[(m['st'] as num).toInt()],
        note: m['note'] as String?,
        completedAt: m['ca'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((m['ca'] as num).toInt()),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _putPhoto(
      SharedPreferences sp, String key, Uint8List? bytes) async {
    if (bytes != null) {
      await sp.setString(key, base64Encode(bytes));
    } else {
      await sp.remove(key);
    }
  }

  static Uint8List? _decodePhoto(String? s) =>
      (s == null || s.isEmpty) ? null : base64Decode(s);

  /// The ONE way into the app. A provider (Telegram / Google / phone OTP) has
  /// just vouched for this person, so record who they are and open the door.
  ///
  /// There is no plain `signIn()` any more, and no `registerClient()`. Both let
  /// a caller assert a session out of thin air — `registerClient` did it on the
  /// strength of a non-empty first-name string. Requiring [id] and [method]
  /// here means every session is traceable to a provider that verified a real
  /// human, which is what the wallet, commissions and no-show penalties assume.
  ///
  /// [id] must derive from the VERIFIED credential (telegram id, email, phone)
  /// — never a constant. It used to be `_user.id`, which defaulted to the mock
  /// user, so every client on earth shared the id `u1`.
  ///
  /// A client is [AuthStage.ready] immediately: Telegram already gave us their
  /// name and phone, so there is nothing left to ask. A barber stops at
  /// [AuthStage.identified] — they still need a chair — and the splash screen
  /// resumes them into that setup on relaunch.
  void signInWithIdentity({
    required String id,
    required String fullName,
    required AppRole role,
    required AuthMethod method,
    String phone = '',
    String email = '',
    String? avatarUrl,
    Uint8List? photo,
  }) {
    _user = AppUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    if (photo != null) _userPhoto = photo;
    _method = method;
    _activeRole = role;
    _stage = role == AppRole.barber ? AuthStage.identified : AuthStage.ready;
    notifyListeners();
  }

  /// Google proves an email but never a phone, and a barber has to be callable.
  /// Lets the OTP step top up an existing session without re-authenticating.
  void attachVerifiedPhone(String phone) {
    if (phone.isEmpty) return;
    _user = AppUser(
      id: _user.id,
      fullName: _user.fullName,
      email: _user.email,
      phone: phone,
      avatarUrl: _user.avatarUrl,
    );
    notifyListeners();
  }

  /// Full sign-out — forget the profile so a fresh person can register.
  /// Also wipes bookings/chats and re-seeds, so the next person starts clean
  /// and doesn't inherit the previous user's appointments.
  void signOut() {
    _stage = AuthStage.anonymous;
    _method = null;
    _barberOnboarded = false;
    _registeredBarber = null;
    // Empty, NOT MockData.currentUser — falling back to the demo user is how
    // "Alex Johnson" and a fake US phone number kept reappearing on fresh
    // accounts. Nobody is signed in, so the profile is nobody.
    _user = AppUser.empty;
    _userPhoto = null;
    _activeRole = AppRole.client;
    _bookings.clear();
    _chats.clear();
    _barberChats.clear();
    _replyIx = 0;
    _clientReplyIx = 0;
    // Reset every durable per-user field to its default so the next person to
    // register on this device does NOT inherit the previous user's wallet, VIP,
    // ledger, menu, reviews, favourites, etc. (the auto-save then persists the
    // clean slate).
    _walletSom = 42000;
    _boosts = 2;
    _vipUntil = null;
    _vipSince = null;
    _vipCommissionSavedSom = 0;
    _boostActiveUntil = null;
    _ledger.clear();
    _ledgerSeeded = false;
    _myServices
      ..clear()
      ..addAll(MockData.barbershops.first.services);
    _breaks
      ..clear()
      ..add(const BarberBreak(
        id: 'brk_lunch',
        label: 'Lunch',
        startMinutes: 13 * 60,
        durationMinutes: 60,
        daily: true,
      ));
    _perks.clear();
    _awardedPerkBookings.clear();
    _verifiedScanStreak.clear();
    _shopReviews.clear();
    _barberReviews.clear();
    _favouriteShopIds
      ..clear()
      ..addAll({'shop2', 'shop5'});
    _shopPhotos.clear();
    _myBarberId = null;
    _myBarberShopId = null;
    _offDays.clear();
    _workStart = 9;
    _workEnd = 21;
    _weeklyGoalSom = 2800000;
    _shopDescription = '';
    _shopLat = null;
    _shopLng = null;
    _shopAddr = null;
    _hasCardOnFile = false;
    _desiredStyleId = null;
    _locationPromptShown = false;
    _address = null;
    _seedBookings();
    _seedChats();
    notifyListeners();
  }

  void updateUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  /// Focused profile setters used by Settings. Email/phone changes go through
  /// the verify-the-new-value screen first, so these run only once the new
  /// value is confirmed.
  void setUserName(String name) {
    final v = name.trim();
    if (v.isEmpty) return;
    _user = AppUser(
      id: _user.id,
      fullName: v,
      email: _user.email,
      phone: _user.phone,
      avatarUrl: _user.avatarUrl,
    );
    notifyListeners();
  }

  void setUserEmail(String email) {
    final v = email.trim();
    if (v.isEmpty) return;
    _user = AppUser(
      id: _user.id,
      fullName: _user.fullName,
      email: v,
      phone: _user.phone,
      avatarUrl: _user.avatarUrl,
    );
    notifyListeners();
  }

  void setUserPhone(String phone) {
    final v = phone.trim();
    if (v.isEmpty) return;
    _user = AppUser(
      id: _user.id,
      fullName: _user.fullName,
      email: _user.email,
      phone: v,
      avatarUrl: _user.avatarUrl,
    );
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// Add a client booking. Re-checks availability at commit time (the slot may
  /// have been taken — e.g. by a walk-in — while the review screen was open) and
  /// returns false without booking if the slot is no longer free, so no entry
  /// path can silently double-book. Mirrors [addWalkIn]'s guard.
  bool addBooking(Booking booking) {
    final at = booking.dateTime;
    final slot = DateTime(
        at.year, at.month, at.day, at.hour, at.minute >= 30 ? 30 : 0);
    final blocked = blockedSlotsFor(
      shopId: booking.barbershop.id,
      barberId: booking.barber.id,
      day: at,
    );
    if (blocked.contains(slot)) return false; // slot just taken → reject
    _bookings.add(booking);
    // Booking unlocks messaging with this barber — drop in a welcome note so
    // the conversation is ready the moment they want to text.
    _chats.putIfAbsent(
      booking.barber.id,
      () => [
        ChatMessage(
          text: "Got your request ✂️ I'll confirm it shortly — message me "
              'here if you need anything.',
          mine: false,
          at: DateTime.now(),
        ),
      ],
    );
    // Demo: the booked barber "replies" a few seconds later, so a client's
    // request doesn't sit at "Waiting for reply" forever (in production the
    // barber accepts/declines from their own device). Only the user's own
    // bookings auto-confirm.
    if (booking.status == BookingStatus.requested && booking.clientName == null) {
      _scheduleClientBookingAutoConfirm(booking.id);
    }
    notifyListeners();
    return true;
  }

  /// Simulate the booked barber accepting a client's request after a short
  /// delay, so the home card advances requested → upcoming on its own.
  void _scheduleClientBookingAutoConfirm(String id) {
    Timer(const Duration(seconds: 4), () {
      final b = _bookingById(id);
      // Only if it's still pending — the user may have cancelled meanwhile.
      if (b == null || b.status != BookingStatus.requested) return;
      confirmBooking(id); // → upcoming + a "confirmed" notification
    });
  }

  void cancelBooking(String id) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i == -1) return;
    _bookings[i] = _bookings[i].copyWith(status: BookingStatus.cancelled);
    notifyListeners();
  }
}
