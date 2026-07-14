import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/service.dart';
import 'paper_kit.dart';

/// Read-only service row (for listings outside the booking checklist).
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
  });

  final BarberService service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return PaperCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(service.icon, size: 20, color: AppColors.accentDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.tr(service.name), style: AppTypography.h4(context)),
                const SizedBox(height: 2),
                Text(
                  '${service.formattedDuration} · ${L.tr(service.description)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(service.formattedPrice, style: AppTypography.price(context)),
          Icon(Icons.chevron_right_rounded, color: p.textTertiary, size: 20),
        ],
      ),
    );
  }
}
