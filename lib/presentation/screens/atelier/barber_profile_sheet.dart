import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/barber.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../booking/booking_flow_screen.dart';

/// Bottom sheet with one barber's card — book them or make them yours.
Future<void> showBarberProfileSheet(
  BuildContext context, {
  required Barber barber,
  required Barbershop shop,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.5),
    builder: (_) => _BarberProfileSheet(barber: barber, shop: shop),
  );
}

class _BarberProfileSheet extends StatelessWidget {
  const _BarberProfileSheet({required this.barber, required this.shop});

  final Barber barber;
  final Barbershop shop;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final isMine = AppState.instance.isMyBarber(barber.id);
        return DraggableScrollableSheet(
          initialChildSize: 0.74,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: p.bg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                      children: [
                        Row(
                          children: [
                            InitialAvatar(
                              name: barber.name,
                              size: 68,
                              index: barber.id.hashCode,
                            ),
                            const SizedBox(width: 14),
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
                                          style: AppTypography.h2(context),
                                        ),
                                      ),
                                      if (isMine) ...[
                                        const SizedBox(width: 8),
                                        MiniPill(L.stMyBarberPill),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    L.tr(barber.specialty),
                                    style: AppTypography.bodySmall(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _StatBubble(
                              value: barber.rating.toStringAsFixed(1),
                              label: L.ratingWord,
                              accent: true,
                            ),
                            const SizedBox(width: 10),
                            _StatBubble(
                              value: '${barber.yearsExperience}y',
                              label: L.behindChair,
                            ),
                            const SizedBox(width: 10),
                            _StatBubble(
                              value: '${barber.reviewCount}',
                              label: L.reviewsLower,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        PaperCard(
                          radius: 24,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"${barber.bio}"',
                                style: AppTypography.scribble(context,
                                    size: 23),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '— ABOUT ${barber.name.split(' ').first.toUpperCase()}',
                                style: GoogleFonts.nunito(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                  color: p.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        PaperCard(
                          radius: 24,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              InitialAvatar(
                                name: shop.name,
                                size: 46,
                                square: true,
                                color: AppColors.accentDeep,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(shop.name,
                                        style: AppTypography.h4(context)),
                                    const SizedBox(height: 2),
                                    Text(
                                      shop.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTypography.bodySmall(context),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              MiniPill('★ ${shop.rating.toStringAsFixed(1)}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: L.bookWithName(barber.name.split(' ').first),
                          height: 60,
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              FadeThroughPageRoute(
                                child: BookingFlowScreen(
                                  shop: shop,
                                  preselectedBarberId: barber.id,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        PrimaryButton(
                          label: isMine
                              ? L.forgetMyBarber
                              : L.makeMyBarber,
                          height: 56,
                          style: isMine
                              ? PrimaryButtonStyle.ghost
                              : PrimaryButtonStyle.lime,
                          icon: isMine ? null : Icons.push_pin_rounded,
                          onPressed: () {
                            if (isMine) {
                              AppState.instance.clearMyBarber();
                            } else {
                              AppState.instance.setMyBarber(
                                shopId: shop.id,
                                barberId: barber.id,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({
    required this.value,
    required this.label,
    this.accent = false,
  });

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: accent ? AppColors.accent : p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent ? Colors.transparent : p.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: accent ? AppColors.ink : p.text,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: accent
                    ? AppColors.ink.withValues(alpha: 0.6)
                    : p.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
