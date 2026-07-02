import 'package:geolocator/geolocator.dart';

import 'geo_position.dart';

/// Native (Android/iOS/desktop) locator backed by the `geolocator` plugin.
/// Requests permission on first use and returns the device's current fix.
GeoLocator createLocator() => _NativeLocator();

class _NativeLocator implements GeoLocator {
  @override
  Future<({double lat, double lng})?> position() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      // Fast path: a cached fix (we've located before, or another app has)
      // returns instantly — crucial indoors where a fresh GPS lock is slow.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return (lat: last.latitude, lng: last.longitude);

      // No cache yet — get a fresh fix. Medium accuracy uses network + GPS so
      // it resolves quickly; a generous timeout avoids bailing out too early.
      final p = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 20));
      return (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      return null;
    }
  }
}
