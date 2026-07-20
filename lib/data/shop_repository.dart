import 'package:flutter/material.dart';

import '../core/supabase/supabase_service.dart';
import 'models/barber.dart';
import 'models/barbershop.dart';
import 'models/service.dart';

/// Reads the REAL barbershop catalogue from Supabase and maps it onto the app's
/// models. This is the Phase-2 foundation that replaces MockData once real
/// shops exist — the schema (barbershops + barbers + services) is public-read
/// (see supabase/schema.sql `shops_read using (true)`), so the shipped anon
/// key can fetch it with no session.
///
/// The lean table only stores the essentials (name, address, location); the
/// richer presentation fields (tagline, cover, hours, tags) default sensibly
/// here until a shop-profile enrichment step fills them in. Nothing calls this
/// yet — the UI is flipped over behind [SupabaseConfig.useRealCatalogue] in a
/// later step so the mock demo keeps working until real supply lands.
class ShopRepository {
  ShopRepository._();

  /// Every shop, premium first (mirrors how the mock list ranks).
  static Future<List<Barbershop>> fetchShops() async {
    final rows = await SupabaseService.client.from('barbershops').select(
          'id, name, address, lat, lng, is_premium, '
          'barbers(id, display_name, bio, photo_url, rating, is_active), '
          'services(id, name, price, duration_min)',
        );
    final shops = (rows as List)
        .map((r) => _mapShop(r as Map<String, dynamic>))
        .toList()
      // Premium/sponsored shops lead, like the mock catalogue.
      ..sort((a, b) => (b.isPremium ? 1 : 0) - (a.isPremium ? 1 : 0));
    return shops;
  }

  static Barbershop _mapShop(Map<String, dynamic> row) {
    final barbers = ((row['barbers'] as List?) ?? const [])
        .map((b) => _mapBarber(b as Map<String, dynamic>))
        .where((b) => b != null)
        .cast<Barber>()
        .toList();
    final services = ((row['services'] as List?) ?? const [])
        .map((s) => _mapService(s as Map<String, dynamic>))
        .toList();

    // Shop rating = the average of its barbers' ratings (no reviews table read
    // yet; reviewCount stays 0 until that's wired).
    final rated = barbers.where((b) => b.rating > 0).toList();
    final avg = rated.isEmpty
        ? 0.0
        : rated.map((b) => b.rating).reduce((a, b) => a + b) / rated.length;

    final id = row['id'] as String;
    return Barbershop(
      id: id,
      name: (row['name'] as String?) ?? 'Barbershop',
      tagline: 'On Fade',
      description: '',
      address: (row['address'] as String?) ?? '',
      distanceKm: 0, // set from device location when that's wired
      rating: double.parse(avg.toStringAsFixed(1)),
      reviewCount: 0,
      coverImageUrl: 'https://picsum.photos/seed/$id/800/600',
      galleryUrls: const [],
      services: services,
      barbers: barbers,
      reviews: const [],
      openingHours: 'Set your hours',
      isFeatured: false,
      priceLevel: 2,
      tags: const [],
      isPremium: (row['is_premium'] as bool?) ?? false,
      lat: (row['lat'] as num?)?.toDouble() ?? 41.3111,
      lng: (row['lng'] as num?)?.toDouble() ?? 69.2797,
    );
  }

  static Barber? _mapBarber(Map<String, dynamic> row) {
    if ((row['is_active'] as bool?) == false) return null;
    final id = row['id'] as String;
    return Barber(
      id: id,
      name: (row['display_name'] as String?) ?? 'Barber',
      specialty: 'Barber',
      rating: (row['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: 0,
      yearsExperience: 1,
      imageUrl: (row['photo_url'] as String?) ??
          'https://i.pravatar.cc/300?u=$id',
      bio: (row['bio'] as String?) ?? '',
    );
  }

  static BarberService _mapService(Map<String, dynamic> row) {
    return BarberService(
      id: row['id'] as String,
      name: (row['name'] as String?) ?? 'Service',
      description: '',
      price: (row['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: (row['duration_min'] as int?) ?? 30,
      icon: Icons.content_cut_rounded,
    );
  }
}
