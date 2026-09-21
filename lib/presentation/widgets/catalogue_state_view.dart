import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/app_state.dart';
import 'primary_button.dart';

/// What a browse surface shows when there are no real shops to show.
///
/// Before this existed the app answered "loading", "none nearby" and "the
/// network died" identically: with the five bundled demo shops. On the live
/// path that is the most damaging possible answer, because a demo shop's ids
/// are demo strings rather than database UUIDs — `BookingRepository` drops the
/// insert, the booking survives only on the client's phone, and they arrive for
/// an appointment no barber ever received.
///
/// Being honest costs one screen and removes that entire failure mode.
class CatalogueStateView extends StatelessWidget {
  const CatalogueStateView({super.key, this.compact = false});

  /// Tighter padding for use inside a scrolling home feed, rather than as a
  /// whole-page state.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final status = AppState.instance.catalogueStatus;

    if (status == CatalogueStatus.loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 28 : 64),
        child: Column(
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation(p.textTertiary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              L.catalogueLoading,
              style: AppTypography.body(context).copyWith(
                color: p.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final failed = status == CatalogueStatus.failed;
    final title = failed ? L.catalogueFailedTitle : L.catalogueEmptyTitle;
    final body = failed ? L.catalogueFailedBody : L.catalogueEmptyBody;
    final icon = failed
        ? Icons.wifi_off_rounded
        : Icons.storefront_outlined;

    return Padding(
      padding: EdgeInsets.fromLTRB(4, compact ? 24 : 56, 4, compact ? 8 : 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: p.cardAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: p.textTertiary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.h3(context),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.body(context).copyWith(
                color: p.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          // Retry only makes sense for a failure. "No shops here yet" is a true
          // answer, and offering a button that re-fetches the same empty list
          // would just invite the user to poke at it.
          if (failed) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: L.tryAgain,
                height: 50,
                icon: Icons.refresh_rounded,
                onPressed: () => AppState.instance.retryCatalogue(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
