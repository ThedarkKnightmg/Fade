import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'models/barber.dart';
import 'models/barbershop.dart';
import 'models/category.dart';
import 'models/review.dart';
import 'models/service.dart';
import 'models/user.dart';

/// Mock repository — sample data backing the UI.
/// Replace with real API calls when wiring to a backend.
class MockData {
  MockData._();

  static const AppUser currentUser = AppUser(
    id: 'u1',
    fullName: 'Alex Johnson',
    email: 'alex.johnson@example.com',
    phone: '+1 (555) 234-1908',
  );

  static const List<ServiceCategory> categories = [
    ServiceCategory(
      id: 'c1',
      name: 'Haircut',
      icon: Icons.content_cut_rounded,
      color: Color(0xFFF7C04A),
    ),
    ServiceCategory(
      id: 'c2',
      name: 'Beard',
      icon: Icons.face_retouching_natural_rounded,
      color: Color(0xFFE57C5A),
    ),
    ServiceCategory(
      id: 'c3',
      name: 'Shave',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF6FAFE0),
    ),
    ServiceCategory(
      id: 'c4',
      name: 'Color',
      icon: Icons.palette_rounded,
      color: Color(0xFFB084DC),
    ),
    ServiceCategory(
      id: 'c5',
      name: 'Kids',
      icon: Icons.child_care_rounded,
      color: Color(0xFF8BC892),
    ),
  ];

  static const List<BarberService> _commonServices = [
    BarberService(
      id: 's1',
      name: 'Classic Haircut',
      description: 'Precision cut tailored to your style and face shape.',
      price: 28,
      durationMinutes: 30,
      icon: Icons.content_cut_rounded,
    ),
    BarberService(
      id: 's2',
      name: 'Beard Trim',
      description: 'Shaping, lining, and conditioning for a defined look.',
      price: 18,
      durationMinutes: 20,
      icon: Icons.face_retouching_natural_rounded,
    ),
    BarberService(
      id: 's3',
      name: 'Hot Towel Shave',
      description: 'Traditional straight-razor shave with hot towel finish.',
      price: 32,
      durationMinutes: 40,
      icon: Icons.water_drop_rounded,
    ),
    BarberService(
      id: 's4',
      name: 'Hair & Beard Combo',
      description: 'Full service: haircut plus beard shaping and styling.',
      price: 42,
      durationMinutes: 55,
      icon: Icons.auto_awesome_rounded,
    ),
    BarberService(
      id: 's5',
      name: 'Kids Cut',
      description: 'Patient, careful cuts for kids under 12.',
      price: 20,
      durationMinutes: 25,
      icon: Icons.child_care_rounded,
    ),
    BarberService(
      id: 's6',
      name: 'Hair Color',
      description: 'Single-process color, gloss, or grey blending.',
      price: 55,
      durationMinutes: 60,
      icon: Icons.palette_rounded,
    ),
  ];

  static List<Barber> _barbersFor(String shopId) {
    return [
      Barber(
        id: '${shopId}_b1',
        name: 'Marco Reyes',
        specialty: 'Fades & textures',
        rating: 4.9,
        reviewCount: 312,
        yearsExperience: 8,
        imageUrl: 'https://i.pravatar.cc/300?img=12',
        bio:
            'Award-winning stylist specializing in modern fades and textured cuts.',
      ),
      Barber(
        id: '${shopId}_b2',
        name: 'Daniel Cole',
        specialty: 'Classic & beard',
        rating: 4.8,
        reviewCount: 248,
        yearsExperience: 12,
        imageUrl: 'https://i.pravatar.cc/300?img=33',
        bio:
            'Old-school barber with twelve years of straight-razor experience.',
      ),
      Barber(
        id: '${shopId}_b3',
        name: 'Liam Patel',
        specialty: 'Modern styles',
        rating: 4.7,
        reviewCount: 189,
        yearsExperience: 5,
        imageUrl: 'https://i.pravatar.cc/300?img=52',
        bio:
            'Trend-driven stylist with a sharp eye for current looks and color.',
      ),
      Barber(
        id: '${shopId}_b4',
        name: 'Noah Bennett',
        specialty: 'Kids & families',
        rating: 4.9,
        reviewCount: 156,
        yearsExperience: 6,
        imageUrl: 'https://i.pravatar.cc/300?img=68',
        bio: 'Patient, friendly barber loved by kids and parents alike.',
      ),
    ];
  }

  static List<Review> _reviewsFor(String shopId) {
    return [
      Review(
        id: '${shopId}_r1',
        author: 'James W.',
        rating: 5,
        comment:
            'Best fade I\'ve had in years. Marco took the time to understand exactly what I wanted.',
        date: DateTime.now().subtract(const Duration(days: 3)),
        avatarUrl: 'https://i.pravatar.cc/100?img=15',
      ),
      Review(
        id: '${shopId}_r2',
        author: 'Ethan R.',
        rating: 5,
        comment:
            'Clean shop, great vibes, and the hot towel shave was unreal. Booking again next week.',
        date: DateTime.now().subtract(const Duration(days: 7)),
        avatarUrl: 'https://i.pravatar.cc/100?img=22',
      ),
      Review(
        id: '${shopId}_r3',
        author: 'Carlos M.',
        rating: 4,
        comment:
            'Solid haircut and friendly staff. The booking app made it super easy to find a slot.',
        date: DateTime.now().subtract(const Duration(days: 14)),
        avatarUrl: 'https://i.pravatar.cc/100?img=51',
      ),
    ];
  }

  static List<String> _galleryFor(int seed) {
    return List.generate(
      6,
      (i) => 'https://picsum.photos/seed/barber$seed$i/600/600',
    );
  }

  static final List<Barbershop> barbershops = [
    Barbershop(
      id: 'shop1',
      name: 'The Sharp Edge',
      tagline: 'Premium cuts, classic vibes',
      description:
          'A modern barbershop blending old-school craft with contemporary styles. Walk in for a quick clean-up or settle in for the full grooming experience.',
      address: 'Amir Temur Avenue, Tashkent',
      lat: 41.3111,
      lng: 69.2797,
      distanceKm: 0.8,
      rating: 4.9,
      reviewCount: 482,
      coverImageUrl: 'https://picsum.photos/seed/sharpedge/800/600',
      galleryUrls: _galleryFor(1),
      services: _commonServices,
      barbers: _barbersFor('shop1'),
      reviews: _reviewsFor('shop1'),
      openingHours: 'Mon - Sat · 9:00 AM - 8:00 PM',
      isFeatured: true,
      isPremium: true,
      priceLevel: 3,
      tags: ['Premium', 'Beard expert', 'Fades'],
    ),
    Barbershop(
      id: 'shop2',
      name: 'Northside Barbers',
      tagline: 'Neighborhood cuts since 2008',
      description:
          'Family-owned shop with a loyal following. Honest prices, no-frills service, and barbers who remember your name.',
      address: 'Yunusobod district, Tashkent',
      lat: 41.3650,
      lng: 69.2890,
      distanceKm: 1.4,
      rating: 4.7,
      reviewCount: 318,
      coverImageUrl: 'https://picsum.photos/seed/northside/800/600',
      galleryUrls: _galleryFor(2),
      services: _commonServices,
      barbers: _barbersFor('shop2'),
      reviews: _reviewsFor('shop2'),
      openingHours: 'Mon - Sun · 8:00 AM - 7:00 PM',
      isFeatured: true,
      priceLevel: 2,
      tags: ['Family-friendly', 'Classic', 'Walk-ins'],
    ),
    Barbershop(
      id: 'shop3',
      name: 'Atlas Grooming Co.',
      tagline: 'Modern men\'s grooming',
      description:
          'Full-service grooming lounge offering haircuts, beard work, color, and skincare in a relaxed, design-forward space.',
      address: 'Chorsu, Old City, Tashkent',
      lat: 41.3260,
      lng: 69.2280,
      distanceKm: 2.1,
      rating: 4.8,
      reviewCount: 256,
      coverImageUrl: 'https://picsum.photos/seed/atlas/800/600',
      galleryUrls: _galleryFor(3),
      services: _commonServices,
      barbers: _barbersFor('shop3'),
      reviews: _reviewsFor('shop3'),
      openingHours: 'Tue - Sun · 10:00 AM - 9:00 PM',
      isFeatured: false,
      isPremium: true,
      priceLevel: 3,
      tags: ['Color', 'Skincare', 'Modern'],
    ),
    Barbershop(
      id: 'shop4',
      name: 'Iron & Steel Barbers',
      tagline: 'Sharp cuts, sharper attitude',
      description:
          'Industrial-style barbershop with a focus on precision fades, sharp lineups, and bold modern styles.',
      address: 'Mirzo Ulugbek district, Tashkent',
      lat: 41.3220,
      lng: 69.3340,
      distanceKm: 3.0,
      rating: 4.6,
      reviewCount: 174,
      coverImageUrl: 'https://picsum.photos/seed/ironsteel/800/600',
      galleryUrls: _galleryFor(4),
      services: _commonServices,
      barbers: _barbersFor('shop4'),
      reviews: _reviewsFor('shop4'),
      openingHours: 'Mon - Sat · 11:00 AM - 9:00 PM',
      isFeatured: false,
      priceLevel: 2,
      tags: ['Fades', 'Lineups', 'Trendy'],
    ),
    Barbershop(
      id: 'shop5',
      name: 'Heritage Cuts',
      tagline: 'Traditional barbering reimagined',
      description:
          'Heritage Cuts honors time-tested barbering techniques with a contemporary, comfortable atmosphere.',
      address: 'Sebzor, Old Quarter, Tashkent',
      lat: 41.3400,
      lng: 69.2400,
      distanceKm: 4.2,
      rating: 4.9,
      reviewCount: 421,
      coverImageUrl: 'https://picsum.photos/seed/heritage/800/600',
      galleryUrls: _galleryFor(5),
      services: _commonServices,
      barbers: _barbersFor('shop5'),
      reviews: _reviewsFor('shop5'),
      openingHours: 'Mon - Sat · 9:00 AM - 7:00 PM',
      isFeatured: true,
      priceLevel: 3,
      tags: ['Traditional', 'Hot towel', 'Premium'],
    ),
  ];

  /// Generate available time slots for a given date, every 30 min between
  /// [startHour] and [endHour] (the barber's working hours).
  static List<DateTime> timeSlotsFor(
    DateTime date, {
    int startHour = 9,
    int endHour = 21,
  }) {
    final base = DateTime(date.year, date.month, date.day, startHour);
    final count = ((endHour - startHour) * 2).clamp(0, 48);
    return List.generate(count, (i) => base.add(Duration(minutes: 30 * i)));
  }

  /// Which slots are already booked for a day — deterministic, so the same
  /// day + shop + barber always shows the same availability (~40% taken).
  /// Lets the booking grid show greyed-out, unavailable times.
  static Set<DateTime> bookedSlotsFor(
    DateTime date, {
    String? shopId,
    String? barberId,
    int startHour = 9,
    int endHour = 21,
  }) {
    final seed =
        Object.hash(date.year, date.month, date.day, shopId, barberId) &
            0x7fffffff;
    final rnd = math.Random(seed);
    final booked = <DateTime>{};
    for (final slot
        in timeSlotsFor(date, startHour: startHour, endHour: endHour)) {
      if (rnd.nextInt(10) < 4) booked.add(slot);
    }
    return booked;
  }
}
