import '../../core/format/money.dart';

/// Why a fee is owed.
enum ChargeReason { lateCancel, noShow }

/// Lifecycle of a fee/authorization. Everything past [pending] is a payment
/// provider's job — these transitions are stubs in the demo.
enum ChargeIntentStatus { pending, authorized, captured, waived, failed }

/// A record of an intent to charge the cancellation/no-show fee (or hold a
/// card). A STUB liability record for the demo — it never moves real money and
/// never touches card data; real capture hands off to a provider (Stripe/
/// Payme/Click).
class ChargeIntent {
  const ChargeIntent({
    required this.id,
    required this.reason,
    required this.amountUsd,
    required this.createdAt,
    this.status = ChargeIntentStatus.pending,
    this.providerRef,
  });

  final String id;
  final ChargeReason reason;

  /// Amount in the same USD-ish units service prices are stored in.
  final double amountUsd;
  final DateTime createdAt;
  final ChargeIntentStatus status;
  final String? providerRef;

  /// Always shown in so'm — never raw USD.
  String get formattedAmount => Money.som(amountUsd);

  factory ChargeIntent.forFee({
    required ChargeReason reason,
    required double amountUsd,
  }) =>
      ChargeIntent(
        id: 'ci_${DateTime.now().microsecondsSinceEpoch}',
        reason: reason,
        amountUsd: amountUsd,
        createdAt: DateTime.now(),
      );

  ChargeIntent copyWith({ChargeIntentStatus? status, String? providerRef}) =>
      ChargeIntent(
        id: id,
        reason: reason,
        amountUsd: amountUsd,
        createdAt: createdAt,
        status: status ?? this.status,
        providerRef: providerRef ?? this.providerRef,
      );
}
