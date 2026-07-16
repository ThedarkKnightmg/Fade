import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar_link.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/directions_sheet.dart';
import '../../widgets/late_cancel_sheet.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../booking/booking_flow_screen.dart';
import 'booking_ticket_screen.dart';

/// Bookings — one clean card per visit, filtered by a segmented status row.
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
            children: [
              FadeSlideIn(
                child:
                    Text(L.pfMyAppointments, style: AppTypography.h1(context)),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: _StatusTabs(
                  tabs: [
                    (BookingStatus.upcoming, L.upcomingWord),
                    (BookingStatus.completed, L.tabPast),
                    (BookingStatus.cancelled, L.tabCancelled),
                  ],
                  counts: counts,
                  selected: _tab,
                  onSelect: (s) => setState(() => _tab = s),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _EmptyState(
                    showExplore: _tab == BookingStatus.upcoming,
                    onExplore: widget.onExplore,
                  ),
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  FadeSlideIn(
                    delay: Duration(milliseconds: 120 + i * 60),
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

/// Yandex-style segmented row — a quiet track with a white pill on the
/// selected tab and a small blue count beside its label.
class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.tabs,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  final List<(BookingStatus, String)> tabs;
  final Map<BookingStatus, int> counts;
  final BookingStatus selected;
  final ValueChanged<BookingStatus> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.cardAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final (status, label) in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(status),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: 40,
                  decoration: BoxDecoration(
                    color: status == selected ? p.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: status == selected
                        ? [
                            BoxShadow(
                              color: p.shadow,
                              blurRadius: 10,
                              spreadRadius: -2,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color:
                                status == selected ? p.text : p.textSecondary,
                          ),
                        ),
                      ),
                      if ((counts[status] ?? 0) > 0) ...[
                        const SizedBox(width: 5),
                        Text(
                          '${counts[status]}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: status == selected
                                ? AppColors.accent
                                : p.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Quiet empty state — a soft blue calendar chip, a line of copy, and the
/// explore CTA on the Upcoming tab.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showExplore, this.onExplore});

  final bool showExplore;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              size: 28,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            L.nothingHere,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(context),
          ),
          if (showExplore) ...[
            const SizedBox(height: 18),
            PrimaryButton(
              label: L.findAShop,
              expanded: false,
              height: 52,
              onPressed: onExplore,
            ),
          ],
        ],
      ),
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
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
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
      BookingStatus.requested => (L.tagPending, MiniPillStyle.gold),
      BookingStatus.upcoming => (L.tagConfirmed, MiniPillStyle.accent),
      BookingStatus.completed => (L.tagDone, MiniPillStyle.ink),
      BookingStatus.cancelled => (L.pfTagCancelled, MiniPillStyle.ghost),
      BookingStatus.declined => (L.pfTagDeclined, MiniPillStyle.ghost),
      BookingStatus.noShow => (L.tagNoShow, MiniPillStyle.ghost),
    };

    return PaperCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      onTap: isActive ? null : () => _rebook(context),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tinted date chip — blue while the visit is still ahead.
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : p.cardAlt,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${b.dateTime.day}',
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color:
                            isActive ? AppColors.accent : p.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      DateFormat('MMM').format(b.dateTime).toUpperCase(),
                      style: GoogleFonts.nunito(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color:
                            isActive ? AppColors.accent : p.textTertiary,
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
                    Text(L.tr(b.service.name),
                        style: AppTypography.h4(context)),
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
              if (isActive) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _cancel(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: p.cardAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: p.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Fuller detail set — location, duration and price.
          const SizedBox(height: 12),
          Divider(height: 1, color: p.divider),
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
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: L.showTicket,
                    icon: Icons.qr_code_2_rounded,
                    height: 48,
                    style: PrimaryButtonStyle.lime,
                    onPressed: () => Navigator.of(context).push(
                      FadeThroughPageRoute(
                          child: BookingTicketScreen(booking: b)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Straight into Google Calendar — the reminder is what gets
                // them to the chair on time, so it rides next to the ticket.
                GestureDetector(
                  onTap: () => addBookingToCalendar(context, b),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.card,
                      border: Border.all(color: p.border, width: 1.4),
                    ),
                    child: const Icon(Icons.calendar_month_rounded,
                        size: 20, color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ],
          if (!isActive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    b.status == BookingStatus.completed
                        ? L.likedIt
                        : L.changedMind,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(context),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _rebook(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          L.bookAgain,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: AppColors.accent,
                        ),
                      ],
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
