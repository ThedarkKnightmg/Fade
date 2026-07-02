import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/directions_sheet.dart';
import '../../widgets/late_cancel_sheet.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../booking/booking_flow_screen.dart';
import 'booking_ticket_screen.dart';

/// Bookings as a stack of dated notes, filtered by count chips.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  BookingStatus _tab = BookingStatus.upcoming;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        // Each of the 3 tabs folds in a secondary status so no booking can
        // ever disappear: Upcoming = pending + confirmed, Past = done +
        // no-show, Cancelled = cancelled + declined.
        List<Booking> tabItems(BookingStatus tab) {
          final extra = switch (tab) {
            BookingStatus.upcoming => BookingStatus.requested,
            BookingStatus.completed => BookingStatus.noShow,
            BookingStatus.cancelled => BookingStatus.declined,
            _ => tab,
          };
          final list = [
            ...state.bookingsByStatus(tab),
            if (extra != tab) ...state.bookingsByStatus(extra),
          ];
          list.sort((a, b) => tab == BookingStatus.upcoming
              ? a.dateTime.compareTo(b.dateTime)
              : b.dateTime.compareTo(a.dateTime));
          return list;
        }

        final items = tabItems(_tab);
        final counts = {
          for (final t in const [
            BookingStatus.upcoming,
            BookingStatus.completed,
            BookingStatus.cancelled,
          ])
            t: tabItems(t).length,
        };

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 150),
            children: [
              FadeSlideIn(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'My ',
                        style: AppTypography.display(context),
                      ),
                      markerBoxSpan(
                          'appointments', AppTypography.display(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeSlideIn(
                delay: const Duration(milliseconds: 50),
                child: Text(
                  'every cut, written down',
                  style: AppTypography.scribble(context, size: 21)
                      .copyWith(color: p.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      for (final (s, label) in [
                        (BookingStatus.upcoming, L.upcomingWord),
                        (BookingStatus.completed, L.tabPast),
                        (BookingStatus.cancelled, L.tabCancelled),
                      ]) ...[
                        CountChip(
                          label: label,
                          count: counts[s],
                          selected: _tab == s,
                          onTap: () => setState(() => _tab = s),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        ScribbleNote(L.nothingHere),
                        const SizedBox(height: 20),
                        if (_tab == BookingStatus.upcoming)
                          PrimaryButton(
                            label: L.findAShop,
                            expanded: false,
                            height: 52,
                            onPressed: widget.onExplore,
                          ),
                      ],
                    ),
                  ),
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  FadeSlideIn(
                    delay: Duration(milliseconds: 140 + i * 60),
                    child: _BookingNote(booking: items[i]),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _BookingNote extends StatelessWidget {
  const _BookingNote({required this.booking});

  final Booking booking;

  void _rebook(BuildContext context) {
    Navigator.of(context).push(
      FadeThroughPageRoute(
        child: BookingFlowScreen(
          shop: booking.barbershop,
          preselectedBarberId: booking.barber.id,
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    // Inside the 4-hour window → the fee sheet (it cancels via the policy).
    if (AppState.instance.cancellationPolicy.isInsideWindow(booking.dateTime)) {
      await showLateCancelSheet(context, booking);
      return;
    }
    final p = Paper.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: p.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L.cancelThisOne, style: AppTypography.h2(ctx)),
              const SizedBox(height: 6),
              Text(
                L.cancelBody,
                style: AppTypography.bodySmall(ctx),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: L.keepIt,
                      height: 50,
                      style: PrimaryButtonStyle.ghost,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: L.cancelIt,
                      height: 50,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (yes == true) {
      AppState.instance.cancelBookingWithPolicy(booking.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final b = booking;
    final isActive = b.status == BookingStatus.requested ||
        b.status == BookingStatus.upcoming;

    final (statusLabel, statusStyle) = switch (b.status) {
      BookingStatus.requested => ('PENDING', MiniPillStyle.gold),
      BookingStatus.upcoming => ('CONFIRMED', MiniPillStyle.accent),
      BookingStatus.completed => ('DONE', MiniPillStyle.ink),
      BookingStatus.cancelled => ('CANCELLED', MiniPillStyle.ghost),
      BookingStatus.declined => ('DECLINED', MiniPillStyle.ghost),
      BookingStatus.noShow => ('NO-SHOW', MiniPillStyle.ghost),
    };

    return PaperCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      onTap: isActive ? null : () => _rebook(context),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lime date block — the day, torn off a calendar.
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isActive ? AppColors.accent : p.cardAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: isActive ? null : Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    Text(
                      '${b.dateTime.day}',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: isActive ? AppColors.ink : p.textSecondary,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(b.dateTime).toUpperCase(),
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isActive
                            ? AppColors.accentDeep
                            : p.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.service.name, style: AppTypography.h3(context)),
                    const SizedBox(height: 2),
                    Text(
                      '${b.barber.name} · ${b.barbershop.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(context),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        MiniPill(
                          DateFormat('HH:mm').format(b.dateTime),
                          style: MiniPillStyle.ghost,
                          icon: Icons.schedule_rounded,
                        ),
                        const SizedBox(width: 6),
                        MiniPill(statusLabel, style: statusStyle),
                      ],
                    ),
                  ],
                ),
              ),
              if (isActive)
                GestureDetector(
                  onTap: () => _cancel(context),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: p.textTertiary,
                  ),
                ),
            ],
          ),
          // Fuller detail set — location, duration and price.
          const SizedBox(height: 12),
          Divider(height: 1, color: p.border),
          const SizedBox(height: 10),
          // Tap the location to open it in Google Maps / Yandex / Uklon.
          GestureDetector(
            onTap: () => showDirectionsSheet(
              context,
              lat: b.barbershop.lat,
              lng: b.barbershop.lng,
              name: b.barbershop.name,
            ),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: p.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    b.barbershop.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(context),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.directions_rounded,
                    size: 18, color: AppColors.accent),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              MiniPill(
                b.service.formattedDuration,
                style: MiniPillStyle.ghost,
                icon: Icons.timelapse_rounded,
              ),
              const SizedBox(width: 6),
              MiniPill(
                b.service.formattedPrice,
                style: MiniPillStyle.ghost,
                icon: Icons.payments_outlined,
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: L.showTicket,
              icon: Icons.qr_code_2_rounded,
              height: 48,
              style: PrimaryButtonStyle.lime,
              onPressed: () => Navigator.of(context).push(
                FadeThroughPageRoute(child: BookingTicketScreen(booking: b)),
              ),
            ),
          ],
          if (!isActive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  b.status == BookingStatus.completed
                      ? '${L.likedIt}  '
                      : '${L.changedMind}  ',
                  style: AppTypography.scribble(context, size: 19)
                      .copyWith(color: p.textTertiary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _rebook(context),
                  child: Text(
                    '${L.bookAgain} →',
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.accent,
                      decorationThickness: 2.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
