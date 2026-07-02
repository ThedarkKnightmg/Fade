import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'geo_position.dart';

GeoLocator createLocator() => _WebLocator();

class _WebLocator implements GeoLocator {
  @override
  Future<({double lat, double lng})?> position() {
    final completer = Completer<({double lat, double lng})?>();
    void done(({double lat, double lng})? v) {
      if (!completer.isCompleted) completer.complete(v);
    }

    try {
      web.window.navigator.geolocation.getCurrentPosition(
        (web.GeolocationPosition pos) {
          final c = pos.coords;
          done((lat: c.latitude.toDouble(), lng: c.longitude.toDouble()));
        }.toJS,
        (web.GeolocationPositionError _) {
          done(null);
        }.toJS,
      );
      // Safety timeout if the browser never answers.
      Future.delayed(const Duration(seconds: 12), () => done(null));
    } catch (_) {
      done(null);
    }
    return completer.future;
  }
}
