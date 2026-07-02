/// A review carries TWO independent axes (dual-key):
///   • the SHOP (cleanliness/vibe) → [rating] + [comment], owned by the location
///   • the BARBER (talent)         → [barberRating] + [barberComment], keyed by
///     [barberId] so a barber's talent reputation TRAVELS with them across shops
/// Either axis may be absent (rated one but not the other).
class Review {
  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.comment,
    required this.date,
    this.avatarUrl,
    this.barberId = '',
    this.barberName = '',
    this.barberRating,
    this.barberComment,
  });

  final String id;
  final String author;

  /// Shop-side rating (cleanliness & vibe). 0 when only the barber was rated.
  final double rating;

  /// Shop-side text.
  final String comment;
  final DateTime date;
  final String? avatarUrl;

  /// The barber this review's talent axis targets ('' for shop-only history).
  final String barberId;
  final String barberName;

  /// Barber-side talent rating (1–5), or null when only the shop was rated.
  final double? barberRating;
  final String? barberComment;

  double get shopRating => rating;
  String get shopComment => comment;
}
