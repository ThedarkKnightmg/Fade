import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/map/fast_tiles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/cancellation_policy_card.dart';
import '../../widgets/card_on_file_sheet.dart';
import '../../widgets/paper_kit.dart';
import 'booking_confirmation_screen.dart';

/// Review-and-confirm page shown BEFORE a booking is finalised. The user sees
/// every detail — shop, location (with a map), barber, service, time, price —
/// and only the "Book now" button here actually creates the booking.
class BookingReviewScreen extends StatelessWidget {
  const BookingReviewScreen({super.key, required this.booking});

  final Booking booking;

  void _confirm(BuildContext context) {
    // Flag the booking as protected if it wanted a card-on-file hold, so the
    // barber sees it's covered by the no-show shield.
    final needsAuth =
        AppState.instance.slotNeedsAuthorization(booking.service.price);
    final toBook = needsAuth ? booking.copyWith(authRequired: true) : booking;
    // Re-check availability at commit time — the slot may have been taken (e.g.
    // a walk-in) while this screen was open. Never silently double-book.
    final ok = AppState.instance.addBooking(toBook);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.slotTakenWarn)),
      );
      Navigator.of(context).maybePop();
      return;
    }
    Navigator.of(context).pushReplacement(
      FadeThroughPageRoute(child: BookingConfirmationScreen(booking: toBook)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final b = booking;
    final shop = b.barbershop;
    final when = DateFormat('EEEE, d MMM').format(b.dateTime);
    final time = DateFormat('HH:mm').format(b.dateTime);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
              child: Row(
                children: [
                  CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                  Text(L.reviewBookingTitle, style: AppTypography.h3(context)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // Where — a map preview of the shop location.
                  FadeSlideIn(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 150,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(shop.lat, shop.lng),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: cartoTileUrl(
                                  dark: Paper.of(context).isDark),
                              subdomains: cartoSubdomains,
                              tileProvider: CachedTileProvider(),
                              userAgentPackageName: 'com.barber.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(shop.lat, shop.lng),
                                  width: 46,
                                  height: 46,
                                  alignment: Alignment.topCenter,
                                  child: const Icon(Icons.location_on,
                                      color: AppColors.accent, size: 42),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Shop name + rating + address.
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 50),
                    child: PaperCard(
                      radius: 22,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(shop.name,
                                    style: AppTypography.h3(context)),
                              ),
                              MiniPill('★ ${shop.rating.toStringAsFixed(1)}'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: L.locationLabel,
                            value: shop.address,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Barber, service, time.
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: PaperCard(
                      radius: 22,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.person_outline_rounded,
                            label: L.barberLabel,
                            value: b.barber.name,
                          ),
                          _divider(p),
                          _DetailRow(
                            icon: Icons.content_cut_rounded,
                            label: L.serviceLabel,
                            value:
                                '${L.tr(b.service.name)} · ${b.service.formattedDuration}',
                          ),
                          _divider(p),
                          _DetailRow(
                            icon: Icons.event_rounded,
                            label: L.whenLabel,
                            value: '$when · $time',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Total price.
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: PaperCard(
                      radius: 22,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(L.totalLabel, style: AppTypography.h4(context)),
                          const Spacer(),
                          Text(
                            b.service.formattedPrice,
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Cancellation policy — honest terms up front (no-show shield).
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: CancellationPolicyCard(
                        servicePriceUsd: b.service.price),
                  ),
                  if (AppState.instance
                      .slotNeedsAuthorization(b.service.price)) ...[
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: _AuthTile(
                        onTap: () => showCardOnFileSheet(context,
                            amountUsd: b.service.price),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // The only place a booking is actually created.
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, 12 + MediaQuery.of(context).padding.bottom),
              child: GestureDetector(
                onTap: () => _confirm(context),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${L.bookNow} · ${b.service.formattedPrice}',
                      style: GoogleFonts.nunito(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(PaperPalette p) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: p.border),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption(context)),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.h4(context)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tappable "secure this slot" tile — opens the card-on-file (hold) sheet for
/// high-value or repeat-canceller bookings. Optional; the booking proceeds
/// regardless.
class _AuthTile extends StatelessWidget {
  const _AuthTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, size: 20, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.cardOnFileTitle,
                      style: GoogleFonts.nunito(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: p.text,
                      )),
                  Text(L.itsAHoldNotCharge,
                      style: AppTypography.caption(context)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}
