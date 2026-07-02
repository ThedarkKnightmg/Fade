import '../../core/format/money.dart';
import 'barber.dart';
import 'review.dart';
import 'service.dart';

class Barbershop {
  const Barbershop({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.coverImageUrl,
    required this.galleryUrls,
    required this.services,
    required this.barbers,
    required this.reviews,
    required this.openingHours,
    required this.isFeatured,
    required this.priceLevel,
    required this.tags,
    this.isPremium = false,
    this.lat = 41.3111,
    this.lng = 69.2797,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String address;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final String coverImageUrl;
  final List<String> galleryUrls;
  final List<BarberService> services;
  final List<Barber> barbers;
  final List<Review> reviews;
  final String openingHours;
  final bool isFeatured;
  final int priceLevel; // 1-3, shown as a so'm price band
  final List<String> tags;

  /// True for shops on a paid subscription — shown as premium/sponsored cards.
  final bool isPremium;

  /// Real-world location (Tashkent, Uzbekistan) — used to plot the shop on
  /// the map.
  final double lat;
  final double lng;

  String get priceLevelLabel => Money.priceTier(priceLevel);
  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
}
