import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../data/models/barbershop.dart';
import 'paper_kit.dart';
import 'shop_art.dart';

/// A barbershop as a full-width card with a painted storefront cover (awning,
/// lit window, barber pole), the name over the image, and details below.
/// Each shop gets its own colour; paid (premium) shops get a gold treatment.
class BarbershopCard extends StatelessWidget {
  const BarbershopCard({
    super.key,
    required this.shop,
    required this.index,
    required this.isFavourite,
    required this.onTap,
    required this.onFavourite,
  });

  final Barbershop shop;
  final int index;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final premium = shop.isPremium;
    final base = shopCoverColor(index, premium: premium);
    final today = DateTime.now();
    final rawFree = MockData.timeSlotsFor(today).length -
        MockData.bookedSlotsFor(today, shopId: shop.id).length;
    final freeToday = rawFree < 0 ? 0 : rawFree;
    final bookedWk = 9 + (shop.id.hashCode.abs() % 38);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: premium
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: PaperCard(
        onTap: onTap,
        radius: 26,
        padding: EdgeInsets.zero,
        borderColor: premium ? AppColors.gold.withValues(alpha: 0.6) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Storefront cover ---
              SizedBox(
                height: 138,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: ShopCoverPainter(base: base, premium: premium),
                    ),
                    // Bottom scrim so the white name stays readable.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Color(0x8C000000),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    if (premium)
                      Positioned(top: 10, left: 12, child: _PremiumBadge()),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _HeartButton(
                        isFavourite: isFavourite,
                        onTap: onFavourite,
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 10,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.1,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0x99000000),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  shop.tagline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RatingChip(rating: shop.rating),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // --- Details ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 14, color: p.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shop.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: Color(0xFFE0683C)),
                        const SizedBox(width: 4),
                        Text(
                          '$bookedWk booked this week',
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFE0683C),
                          ),
                        ),
                        if (freeToday > 0 && freeToday <= 5) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.bolt_rounded,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 2),
                          Text(
                            '$freeToday left today',
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        MiniPill(shop.priceLevelLabel,
                            style: MiniPillStyle.ghost),
                        const SizedBox(width: 6),
                        MiniPill(shop.distanceLabel,
                            style: MiniPillStyle.ghost),
                        const Spacer(),
                        Text(
                          '${shop.reviewCount} reviews',
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: p.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A glassy white rating chip that sits over the cover image.
class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFE0A12E)),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Favourite heart — white circle that fills with the accent + a springy pop.
class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isFavourite, required this.onTap});

  final bool isFavourite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isFavourite ? AppColors.accent : Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isFavourite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            key: ValueKey(isFavourite),
            size: 18,
            color: isFavourite ? Colors.white : const Color(0xFF8A93A3),
          ),
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF2C75A), Color(0xFFD99A2E)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              size: 13, color: Color(0xFF3A2E10)),
          const SizedBox(width: 4),
          Text(
            'PREMIUM',
            style: GoogleFonts.nunito(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: const Color(0xFF3A2E10),
            ),
          ),
        ],
      ),
    );
  }
}
