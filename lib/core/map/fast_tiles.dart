import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// CARTO basemaps API key. CARTO started requiring one in 2026 — without it
/// every tile comes back stamped "API KEY REQUIRED". It is free (5M tile
/// requests/month) and emailed instantly from carto.com/basemaps/apikey.
/// Like the Supabase publishable key it ships in the client; restrict it to
/// package uz.fade.app in the CARTO key settings so it can't be reused.
const String cartoApiKey = '';

/// CARTO basemaps — a fast global CDN served in standard EPSG:3857, so tiles
/// load quickly and align natively (no projection transform like Yandex).
/// Voyager is a rich, colourful city map in light mode; dark mode uses the
/// matching dark basemap. [plain] swaps Voyager for the quieter light_all
/// style, for small maps where the pin should be the only colour.
String cartoTileUrl({required bool dark, bool plain = false}) {
  final base = dark
      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
      : plain
          ? 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
          : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  return cartoApiKey.isEmpty ? base : '$base?key=$cartoApiKey';
}

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
