import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/animations/app_animations.dart';
import '../../core/animations/motion.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/app_state.dart';
import '../../data/models/barber.dart';
import '../../data/models/barbershop.dart';
import '../screens/barbershop_detail/barbershop_detail_screen.dart';
import 'paper_kit.dart';

/// The two-button feed switch: Shops ⇄ Barbers. Shared by Home and Explore so
/// the barber-centric view feels like one feature everywhere.
class FeedModeSwitch extends StatelessWidget {
  const FeedModeSwitch({
    super.key,
    required this.barbersMode,
    required this.onChanged,
  });

  final bool barbersMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    Widget seg(String label, IconData icon, bool selected, bool value) {
      return Expanded(
        child: GestureDetector(
          onTap: () {
            if (selected) return;
            HapticFeedback.selectionClick();
            onChanged(value);
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 17, color: selected ? Colors.white : p.textTertiary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: clayDecoration(p, radius: 20),
      child: Row(
        children: [
          seg(L.feedShops, Icons.storefront_rounded, !barbersMode, false),
          seg(L.feedBarbers, Icons.face_rounded, barbersMode, true),
        ],
      ),
    );
  }
}

/// A stylist in the barber-centric feed — a rich card: tier-ringed avatar,
/// name + status pill, specialty, their shop, the blended talent rating and a
/// direct Book CTA. Tier 0 (boosted) wears a gold border + breathing aura;
/// the spotlight belongs to THIS barber only — never their shop.
class SpotlightBarberCard extends StatelessWidget {
  const SpotlightBarberCard({
    super.key,
    required this.shop,
    required this.barber,
    required this.index,
  });

  final Barbershop shop;
  final Barber barber;
  final int index;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      FadeThroughPageRoute(
        child: BarbershopDetailScreen(
          shop: shop,
          initialBarberId: barber.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final st = AppState.instance;
    final tier = st.barberSpotlightTier(barber.id);
    final boosted = tier == 0;
    final rating = st.barberTalentRating(barber);
    final reviews = st.barberTalentCount(barber);
    final isMine = st.myBarber?.barber.id == barber.id;

    final card = PressableScale(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: clayDecoration(
          p,
          radius: 24,
          borderColor: boosted
              ? AppColors.gold.withValues(alpha: 0.55)
              : tier == 1
                  ? AppColors.gold.withValues(alpha: 0.28)
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar in the tier ring — gold marks the paid spotlight.
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: boosted
                          ? AppColors.gold
                          : tier == 1
                              ? AppColors.gold.withValues(alpha: 0.5)
                              : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child:
                      InitialAvatar(name: barber.name, size: 54, index: index),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              barber.name,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.h4(context),
                            ),
                          ),
                          if (boosted) ...[
                            const SizedBox(width: 6),
                            MiniPill('⚡ ${L.boostedPill}',
                                style: MiniPillStyle.gold),
                          ] else if (tier == 1) ...[
                            const SizedBox(width: 6),
                            const MiniPill('VIP', style: MiniPillStyle.gold),
                          ],
                          if (isMine) ...[
                            const SizedBox(width: 6),
                            MiniPill(L.wdMyBarber),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        barber.specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(context),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.storefront_rounded,
                              size: 13, color: p.textTertiary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: p.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                MiniPill('★ ${rating.toStringAsFixed(1)}',
                    style: MiniPillStyle.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    L.wdYearsReviews(barber.yearsExperience, reviews),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.textTertiary,
                    ),
                  ),
                ),
                // Direct Book CTA — what the whole card is for.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    L.bookHere,
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!boosted) return card;
    // The premium breathing aura around the boosted stylist.
    return Breathe(
      period: const Duration(milliseconds: 2600),
      builder: (context, t) {
        final pulse = 1 - (2 * t - 1).abs(); // smooth 0→1→0 loop
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.20 + 0.16 * pulse),
                blurRadius: 22 + 6 * pulse,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: card,
        );
      },
    );
  }
}
