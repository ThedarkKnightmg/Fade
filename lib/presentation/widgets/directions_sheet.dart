import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'map_app_logos.dart';

/// Try each URL in turn (app deep link first, then web fallback) until one opens.
Future<void> _launchFirst(List<String> urls) async {
  for (final u in urls) {
    try {
      final ok = await launchUrl(
        Uri.parse(u),
        mode: LaunchMode.externalApplication,
      );
      if (ok) return;
    } catch (_) {
      // Try the next candidate.
    }
  }
}

/// A "get there" sheet — open the shop's location in the user's maps / taxi app
/// of choice. Each option tries the native app deep link, then a web fallback.
void showDirectionsSheet(
  BuildContext context, {
  required double lat,
  required double lng,
  required String name,
}) {
  final p = Paper.of(context);
  final q = '$lat,$lng';
  final options = <_DirOption>[
    _DirOption(
      'Google Maps',
      MapApp.googleMaps,
      [
        // Turn-by-turn straight away. `google.navigation:` starts guidance in
        // the Google Maps app; the https link below only opens a route PREVIEW
        // you then have to tap "Start" on, which is why it was a poor primary.
        'google.navigation:q=$lat,$lng&mode=d',
        // Generic geo: — whatever the user's default map app is.
        'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(name)})',
        // Web fallback: works with no maps app installed at all.
        'https://www.google.com/maps/dir/?api=1&destination=$q&travelmode=driving',
      ],
    ),
    _DirOption(
      'Yandex Maps',
      MapApp.yandexMaps,
      [
        'yandexmaps://maps.yandex.ru/?rtext=~$lat,$lng&rtt=auto',
        'https://yandex.uz/maps/?rtext=~$lat,$lng&rtt=auto',
      ],
    ),
    _DirOption(
      'Yandex Go',
      MapApp.yandexGo,
      [
        'yandextaxi://route?end-lat=$lat&end-lon=$lng&level=50',
        'https://yandex.uz/maps/?rtext=~$lat,$lng&rtt=taxi',
      ],
    ),
    _DirOption(
      'Uklon',
      MapApp.uklon,
      [
        'uklon://m/orders/create?route[1][lat]=$lat&route[1][lng]=$lng',
        'https://www.uklon.com.ua/',
      ],
    ),
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 16 + MediaQuery.of(ctx).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(L.wdGetThere, style: AppTypography.h2(ctx)),
          const SizedBox(height: 2),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(ctx)),
          const SizedBox(height: 16),
          for (final o in options) ...[
            _DirRow(
              option: o,
              onTap: () {
                Navigator.pop(ctx);
                _launchFirst(o.urls);
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    ),
  );
}

class _DirOption {
  const _DirOption(this.label, this.app, this.urls);
  final String label;
  final MapApp app;
  final List<String> urls;
}

class _DirRow extends StatelessWidget {
  const _DirRow({required this.option, required this.onTap});

  final _DirOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            // The app's own mark, so the row is picked out by brand rather
            // than by reading four near-identical grey labels.
            MapAppLogo(app: option.app, size: 40),
            const SizedBox(width: 12),
            Expanded(
                child: Text(option.label, style: AppTypography.h4(context))),
            Icon(Icons.arrow_outward_rounded, size: 18, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}
