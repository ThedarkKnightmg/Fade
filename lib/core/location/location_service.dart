import 'dart:convert';

import 'package:http/http.dart' as http;

import 'geo_position.dart';

/// Detect the device location and turn it into a human label.
/// Returns null if location is denied/unsupported. Reverse-geocoding is
/// best-effort (free OpenStreetMap Nominatim); if it fails we fall back to
/// the raw coordinates so the user still gets a result.
Future<String?> detectLocationLabel() async {
  final pos = await createLocator().position();
  if (pos == null) return null;

  return await reverseGeocode(pos.lat, pos.lng) ??
      'Near you · '
          '${pos.lat.toStringAsFixed(3)}, ${pos.lng.toStringAsFixed(3)}';
}

/// Turn a coordinate into a "City, area" label via free OSM Nominatim.
/// Returns null on any failure so callers can fall back to raw coordinates.
/// Used by both GPS detection and the map address picker.
Future<String?> reverseGeocode(double lat, double lng) async {
  try {
    final res = await http
        .get(
          Uri.parse(
            'https://nominatim.openstreetmap.org/reverse'
            '?format=jsonv2&lat=$lat&lon=$lng',
          ),
          headers: const {
            'Accept': 'application/json',
            // Nominatim asks every client to identify itself.
            'User-Agent': 'FadeApp/1.0 (barbershop booking)',
          },
        )
        .timeout(const Duration(seconds: 6));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is Map && body['address'] is Map) {
        final a = body['address'] as Map;
        // City first ("Tashkent, …"), then the closest area/road.
        final city = a['city'] ??
            a['town'] ??
            a['village'] ??
            a['state'] ??
            a['county'];
        final area = a['suburb'] ??
            a['neighbourhood'] ??
            a['city_district'] ??
            a['road'];
        final parts = [city, area]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) return parts.join(', ');
      }
    }
  } catch (_) {
    // ignore — caller falls back to coordinates
  }
  return null;
}
