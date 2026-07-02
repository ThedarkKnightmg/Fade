import 'geo_stub.dart' if (dart.library.js_interop) 'geo_web.dart' as impl;

/// A plugin-free geolocator. Web uses the browser's `navigator.geolocation`;
/// other platforms return null (the caller falls back to manual entry).
abstract class GeoLocator {
  /// Current device position, or null if denied / unsupported.
  Future<({double lat, double lng})?> position();
}

GeoLocator createLocator() => impl.createLocator();

/// True when a coordinate sits within the greater-Tashkent area. The app only
/// serves Tashkent, so the maps ignore any GPS fix outside this box (a stale,
/// mocked, or out-of-region location must not drag the map off the city).
bool isInTashkent(double lat, double lng) =>
    lat > 40.9 && lat < 41.7 && lng > 68.7 && lng < 69.9;
