import 'package:flutter/material.dart';

import '../core/format/money.dart';
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
          'id, name, address, lat, lng, is_premium, tagline, description, '
          'cover_image_url, gallery_urls, opening_hours, tags, price_level, '
          'is_featured, '
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

  /// Persist a brand-new shop the signed-in barber just created: the shop
  /// (owned by them), their barber row, and the service menu. Returns the new
  /// shop's real UUID, or null if there's no auth session or the write fails
  /// (in which case the caller keeps the local-only copy).
  static Future<String?> createShop({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required bool isPremium,
    required String barberName,
    required String bio,
    required List<({String name, double price, int durationMin})> services,
  }) async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return null; // no real session → local-only
    try {
      final shop = await SupabaseService.client
          .from('barbershops')
          .insert({
            'owner_id': uid,
            'name': name,
            'address': address,
            'lat': lat,
            'lng': lng,
            'is_premium': isPremium,
          })
          .select('id')
          .single();
      final shopId = shop['id'] as String;

      await SupabaseService.client.from('barbers').insert({
        'profile_id': uid,
        'shop_id': shopId,
        'display_name': barberName,
        'bio': bio,
        'rating': 5.0,
        'is_active': true,
      });
      if (services.isNotEmpty) {
        await SupabaseService.client.from('services').insert([
          for (final s in services)
            {
              'shop_id': shopId,
              'name': s.name,
              // Store real so'm (see the units note in _mapService).
              'price': Money.toSom(s.price),
              'duration_min': s.durationMin,
            },
        ]);
      }
      return shopId;
    } catch (e) {
      // ignore: avoid_print
      return null;
    }
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
    String orEmpty(String key, String fallback) {
      final v = (row[key] as String?)?.trim();
      return (v == null || v.isEmpty) ? fallback : v;
    }

    final gallery =
        ((row['gallery_urls'] as List?) ?? const []).cast<String>();
    final tags = ((row['tags'] as List?) ?? const []).cast<String>();

    return Barbershop(
      id: id,
      name: (row['name'] as String?) ?? 'Barbershop',
      tagline: orEmpty('tagline', 'On Fade'),
      description: (row['description'] as String?) ?? '',
      address: (row['address'] as String?) ?? '',
      distanceKm: 0, // set from device location when that's wired
      rating: double.parse(avg.toStringAsFixed(1)),
      reviewCount: 0,
      coverImageUrl: orEmpty(
          'cover_image_url', 'https://picsum.photos/seed/$id/800/600'),
      galleryUrls: gallery,
      services: services,
      barbers: barbers,
      reviews: const [],
      openingHours: orEmpty('opening_hours', 'Set your hours'),
      isFeatured: (row['is_featured'] as bool?) ?? false,
      priceLevel: (row['price_level'] as int?) ?? 2,
      tags: tags,
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
      // UNITS: the database stores real so'm (90 000), while every model in the
      // app carries the USD-ish base unit that Money.som() multiplies up for
      // display. Converting here — the one boundary where the two systems meet
      // — keeps prices, commission and earnings correct everywhere downstream.
      // Without it a 55 000 so'm shave rendered as "704 000 000 so'm".
      price: ((row['price'] as num?)?.toDouble() ?? 0) / Money.usdToUzs,
      durationMinutes: (row['duration_min'] as int?) ?? 30,
      icon: Icons.content_cut_rounded,
    );
  }
}
