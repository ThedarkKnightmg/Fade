import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// CARTO basemaps — a fast global CDN served in standard EPSG:3857, so tiles
/// load quickly and align natively (no projection transform like Yandex).
/// Voyager is a rich, colourful city map in light mode; dark mode uses the
/// matching dark basemap.
String cartoTileUrl({required bool dark}) => dark
    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

const List<String> cartoSubdomains = ['a', 'b', 'c', 'd'];

/// A tile provider that disk-caches tiles via `cached_network_image`. After the
/// first load, panning back or reopening the map paints instantly from cache
/// instead of re-downloading every tile.
class CachedTileProvider extends TileProvider {
  CachedTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      CachedNetworkImageProvider(getTileUrl(coordinates, options));
}
