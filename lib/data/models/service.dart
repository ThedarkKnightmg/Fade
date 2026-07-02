import 'package:flutter/material.dart';

import '../../core/format/money.dart';

class BarberService {
  const BarberService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.icon,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final IconData icon;

  /// Whether the barber currently offers this service. Disabled services stay
  /// on the menu (so the barber can flip them back on) but are hidden from
  /// clients and can't be booked.
  final bool enabled;

  String get formattedPrice => Money.som(price);
  String get formattedDuration => '$durationMinutes min';

  BarberService copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    IconData? icon,
    bool? enabled,
  }) =>
      BarberService(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        icon: icon ?? this.icon,
        enabled: enabled ?? this.enabled,
      );
}

/// Combine several picked services into one bookable service, so a multi-select
/// booking carries the summed price + duration (a [Booking] holds one service).
BarberService comboService(List<BarberService> picked) {
  if (picked.length == 1) return picked.first;
  return BarberService(
    id: 'combo_${picked.map((s) => s.id).join('_')}',
    name: picked.map((s) => s.name).join(' + '),
    description: '',
    price: picked.fold(0.0, (sum, s) => sum + s.price),
    durationMinutes: picked.fold(0, (sum, s) => sum + s.durationMinutes),
    icon: picked.first.icon,
  );
}
