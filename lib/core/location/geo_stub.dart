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

      // A cached fix is only trusted when it is fresh and tight. An old one
      // (hours ago, another district, or the coarse ~2 km cell) is exactly
      // what put people in the wrong place on the map.
      final last = await Geolocator.getLastKnownPosition();
      final fresh = last != null &&
          DateTime.now().difference(last.timestamp).inMinutes < 2 &&
          last.accuracy <= 100;
      if (fresh) return (lat: last.latitude, lng: last.longitude);

      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 15));
        return (lat: p.latitude, lng: p.longitude);
      } catch (_) {
        // No fresh fix in time (deep indoors): an older one beats nothing.
        if (last != null) return (lat: last.latitude, lng: last.longitude);
        rethrow;
      }
    } catch (_) {
      return null;
    }
  }
}
