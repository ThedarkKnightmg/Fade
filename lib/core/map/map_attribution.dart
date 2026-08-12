import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart'; // Paper / PaperPalette live here

/// The "© OSM · CARTO" credit that every map surface must carry.
///
/// OpenStreetMap's ODbL licence and CARTO's basemap terms both require visible
/// attribution wherever their tiles are shown — this app has NINE map surfaces,
/// and only the main one credited them. One shared widget so a new map can
/// never ship uncredited again.
///
/// Tapping opens OSM's copyright page, which is what "reasonably visible
/// credit with a link" means in practice.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key, this.alignment = Alignment.bottomRight});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: GestureDetector(
          onTap: () => launchUrl(
            Uri.parse('https://www.openstreetmap.org/copyright'),
            mode: LaunchMode.externalApplication,
          ),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              // Sits on top of map tiles, so it needs its own quiet plate to
              // stay legible over both light streets and dark parks.
              color: p.bg.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '© OSM · CARTO',
              style: GoogleFonts.nunito(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: p.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
