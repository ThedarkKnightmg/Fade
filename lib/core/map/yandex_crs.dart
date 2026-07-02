import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

/// Yandex Maps raster tiles are published in **EPSG:3395** (ellipsoidal World
/// Mercator), not the EPSG:3857 (spherical) that flutter_map assumes by
/// default. Rendering Yandex tiles on a 3857 grid shifts every tile by ~20 km
/// of latitude, so our Tashkent pins drift off the real streets.
///
/// This CRS makes flutter_map place markers **and** fetch tiles in 3395, so the
/// Yandex basemap and the shop markers line up exactly over Tashkent.
final Crs yandexCrs = Proj4Crs.fromFactory(
  code: 'EPSG:3395',
  proj4Projection: proj4.Projection.add(
    'EPSG:3395',
    '+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs',
  ),
  resolutions: <double>[
    for (var z = 0; z <= 20; z++) 156543.03392804097 / math.pow(2, z),
  ],
);
