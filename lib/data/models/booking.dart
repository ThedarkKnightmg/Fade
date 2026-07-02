import 'barber.dart';
import 'barbershop.dart';
import 'charge_intent.dart';
import 'service.dart';

/// Booking lifecycle. A client's booking starts as [requested]; the barber
/// [confirm]s it (→ [upcoming]) or [declined]s it. After the slot, the barber
/// marks it [completed] or [noShow]. Either side can [cancelled] it.
enum BookingStatus { requested, upcoming, completed, cancelled, declined, noShow }

class Booking {
  const Booking({
    required this.id,
    required this.barbershop,
    required this.barber,
    required this.service,
    required this.dateTime,
    required this.status,
    this.clientName,
    this.note,
    this.chargeIntent,
    this.authRequired = false,
    this.isWalkIn = false,
    this.verifiedAt,
  });

  final String id;
  final Barbershop barbershop;
  final Barber barber;
  final BarberService service;
  final DateTime dateTime;
  final BookingStatus status;

  /// Who booked it (shown on the barber side). Null = the current user ("You").
  final String? clientName;

  /// Optional note the client left for the barber.
  final String? note;

  /// A recorded fee/no-show intent (late-cancel or no-show). Null = clean.
  final ChargeIntent? chargeIntent;

  /// True when the slot asked for a card-on-file authorization hold.
  final bool authRequired;

  /// True for an offline walk-in the barber logged themselves — free forever
  /// (Tier 1): no commission, no ledger. It still blocks the slot for clients.
  final bool isWalkIn;

  /// When the client's QR was scanned at the chair (the verified handshake).
  /// Null = not yet checked in. Only ever set forward, never cleared.
  final DateTime? verifiedAt;

  bool get isVerified => verifiedAt != null;

  /// Overdue: an upcoming, unverified real booking whose slot passed 15+ min ago
  /// — the no-show fail-safe surfaces these to the barber.
  bool overdueAt(DateTime now) =>
      status == BookingStatus.upcoming &&
      verifiedAt == null &&
      !isWalkIn &&
      now.isAfter(dateTime.add(const Duration(minutes: 15)));

  Booking copyWith({
    BookingStatus? status,
    ChargeIntent? chargeIntent,
    bool? authRequired,
    bool? isWalkIn,
    DateTime? verifiedAt,
  }) =>
      Booking(
        id: id,
        barbershop: barbershop,
        barber: barber,
        service: service,
        dateTime: dateTime,
        status: status ?? this.status,
        clientName: clientName,
        note: note,
        chargeIntent: chargeIntent ?? this.chargeIntent,
        authRequired: authRequired ?? this.authRequired,
        isWalkIn: isWalkIn ?? this.isWalkIn,
        verifiedAt: verifiedAt ?? this.verifiedAt,
      );
}
