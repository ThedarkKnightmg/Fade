import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/barber.dart';
import '../../../data/models/barbershop.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/review.dart';
import '../../../data/models/service.dart';
import '../../widgets/booking_kit.dart';
import '../../widgets/dual_rating_row.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/shop_art.dart';
import '../booking/booking_review_screen.dart';
import '../chat/chat_screen.dart';

/// One shop, one page: the standard back-arrow header with the shop name,
/// a blue hero card carrying the trust band (rating · reviews · distance ·
/// price), the "inside the shop" gallery, the service checklist, reviews,
/// the booking cockpit, and a sticky Book bar pinned to the bottom.
class BarbershopDetailScreen extends StatefulWidget {
  const BarbershopDetailScreen({
    super.key,
    required this.shop,
    this.initialBarberId,
  });

  final Barbershop shop;

  /// Pre-select this stylist (e.g. arriving from the barber-centric feed).
  final String? initialBarberId;

  @override
  State<BarbershopDetailScreen> createState() =>
      _BarbershopDetailScreenState();
}

class _BarbershopDetailScreenState extends State<BarbershopDetailScreen> {
  late final Set<String> _selectedServices = {
    widget.shop.services.first.id,
  };
  String? _barberId;
  int _dateIndex = 0;
  DateTime? _time;

  /// The shop's stylists grouped by spotlight tier — boosted first (their
  /// paid spotlight), then VIP, then standard; rating breaks ties. The
  /// hierarchy belongs to individuals: a colleague's boost moves only THEM.
  late final List<Barber> _roster = () {
    final st = AppState.instance;
    final xs = [...widget.shop.barbers];
    xs.sort((a, b) {
      final t =
          st.barberSpotlightTier(a.id).compareTo(st.barberSpotlightTier(b.id));
      if (t != 0) return t;
      return b.rating.compareTo(a.rating);
    });
    return xs;
  }();

  late final List<DateTime> _days = List.generate(7, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: i));
  });

  @override
  void initState() {
    super.initState();
    final my = AppState.instance.myBarber;
    if (widget.initialBarberId != null &&
        widget.shop.barbers.any((b) => b.id == widget.initialBarberId)) {
      // Arrived from the barber feed — keep that exact stylist selected.
      _barberId = widget.initialBarberId;
    } else if (my != null && my.shop.id == widget.shop.id) {
      _barberId = my.barber.id;
    } else {
      _barberId = _roster.first.id; // the top-tier stylist leads
    }
    final now = DateTime.now();
    final (startHour, endHour) =
        AppState.instance.shopHours(widget.shop.id);
    final todayLeft = MockData.timeSlotsFor(now,
            startHour: startHour, endHour: endHour)
        .any((t) => t.isAfter(now.add(const Duration(minutes: 30))));
    if (!todayLeft) _dateIndex = 1;
    // Open booking-ready: pre-select the first free slot so the Book CTA is
    // immediately actionable — the single biggest conversion lever.
    final booked = _bookedSlots;
    for (final t in _slots) {
      if (!booked.contains(t)) {
        _time = t;
        break;
      }
    }
  }

  List<BarberService> get _picked => widget.shop.services
      .where((s) => _selectedServices.contains(s.id))
      .toList();

  double get _total => _picked.fold(0, (sum, s) => sum + s.price);

  int get _minutes => _picked.fold(0, (sum, s) => sum + s.durationMinutes);

  List<DateTime> get _slots {
    final day = _days[_dateIndex];
    final s = AppState.instance;
    if (s.shopOffDays(widget.shop.id).contains(day.weekday)) return const [];
    final now = DateTime.now();
    final (startHour, endHour) = s.shopHours(widget.shop.id);
    return MockData.timeSlotsFor(day, startHour: startHour, endHour: endHour)
        .where((t) =>
            _dateIndex > 0 ||
            t.isAfter(now.add(const Duration(minutes: 30))))
        .toList();
  }

  /// Unavailable slots: mock bookings + the user's own pending/confirmed
  /// bookings at this shop on the selected day (kept in sync with the flow).
  Set<DateTime> get _bookedSlots {
    final day = _days[_dateIndex];
    final s = AppState.instance;
    final (startHour, endHour) = s.shopHours(widget.shop.id);
    final mock = MockData.bookedSlotsFor(day,
        shopId: widget.shop.id,
        barberId: _barberId,
        startHour: startHour,
        endHour: endHour);
    final mine = [
      ...AppState.instance.bookingsByStatus(BookingStatus.requested),
      ...AppState.instance.bookingsByStatus(BookingStatus.upcoming),
    ]
        .where((b) => b.barbershop.id == widget.shop.id)
        .map((b) => b.dateTime)
        .where((d) =>
            d.year == day.year && d.month == day.month && d.day == day.day);
    // Anti-double-booking: the barber's own walk-ins + bookings block the slot.
    final blocked = s.blockedSlotsFor(
        shopId: widget.shop.id, barberId: _barberId, day: day);
    return {...mock, ...mine, ...blocked};
  }

  void _pickTime() {
    final p = Paper.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.5),
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            PanelLabel(
              '${L.bkFreeChairs} · ${DateFormat('EEE d MMM').format(_days[_dateIndex])}',
            ),
            const SizedBox(height: 4),
            TimeGrid(
              slots: _slots,
              booked: _bookedSlots,
              selected: _time,
              onSelect: (t) {
                setState(() => _time = t);
                Navigator.pop(sheetCtx);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Sticky-bar tap: nudge the user through the missing step, else book.
  void _bookFromBar() {
    if (_picked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.pickServiceFirst)),
      );
      return;
    }
    if (_time == null) {
      _pickTime();
      return;
    }
    _book();
  }

  String _dayWord(int i) => i == 0
      ? L.today
      : i == 1
          ? L.tomorrow
          : DateFormat('EEE d').format(_days[i]);

  void _book() {
    if (_picked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.pickServiceFirst)),
      );
      return;
    }
    if (_time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.pickTimeFirst)),
      );
      return;
    }
    final barber = widget.shop.barbers.firstWhere(
      (b) => b.id == _barberId,
      orElse: () => widget.shop.barbers.first,
    );
    final booking = Booking(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      barbershop: widget.shop,
      barber: barber,
      service: comboService(_picked),
      dateTime: _time!,
      status: BookingStatus.requested,
    );
    // Don't book yet — show the review/confirm page, which finalises it.
    Navigator.of(context).push(
      FadeThroughPageRoute(child: BookingReviewScreen(booking: booking)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final shop = widget.shop;
    final idx = MockData.barbershops.indexWhere((s) => s.id == shop.id);
    final base = shopCoverColor(idx < 0 ? 0 : idx, premium: shop.isPremium);
    final booked = _bookedSlots;
    final freeCount = _slots.where((t) => !booked.contains(t)).length;
    final whenLabel = _time == null
        ? L.bkChooseATime
        : '${_dayWord(_dateIndex)} · ${DateFormat('HH:mm').format(_time!)}';

    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final fav = AppState.instance.isFavourite(shop.id);
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Row(
                  children: [
                    CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        shop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h2(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleBtn(
                      icon: fav
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      size: 42,
                      iconColor: fav ? AppColors.red : p.text,
                      onTap: () =>
                          AppState.instance.toggleFavourite(shop.id),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FadeSlideIn(child: _ShopHero(shop: shop)),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Text(L.insideTheShop,
                      style: AppTypography.h3(context)),
                ),
                const SizedBox(height: 10),
                _GalleryRow(base: base, premium: shop.isPremium),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 110),
                  child: _AboutCard(shop: shop),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: Row(
                    children: [
                      Text(L.services, style: AppTypography.h3(context)),
                      const Spacer(),
                      Text(
                        L.tickWhatYouNeed,
                        style: AppTypography.caption(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < shop.services.length; i++) ...[
                  ServiceCheckRow(
                    service: shop.services[i],
                    selected:
                        _selectedServices.contains(shop.services[i].id),
                    onTap: () => setState(() {
                      final id = shop.services[i].id;
                      if (_selectedServices.contains(id)) {
                        _selectedServices.remove(id);
                      } else {
                        _selectedServices.add(id);
                      }
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 14),
                _ReviewsBlock(shop: shop),
                const SizedBox(height: 22),
                _ScarcityChip(count: freeCount, day: _dayWord(_dateIndex)),
                const SizedBox(height: 12),
                InkPanel(
                  title: L.bkBookYourVisit,
                  trailing: Text(
                    _minutes == 0 ? '—' : '$_minutes min',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: p.textTertiary,
                    ),
                  ),
                  children: [
                    PanelLabel(L.withLabel),
                    if (widget.initialBarberId != null)
                      // The user came from the barber feed FOR this stylist —
                      // the booking stays locked to them; colleagues aren't
                      // offered (that's the whole point of the barber-centric
                      // flow and the stylist's paid spotlight).
                      _LockedStylistRow(
                        barber: widget.shop.barbers.firstWhere(
                          (b) => b.id == widget.initialBarberId,
                          orElse: () => _roster.first,
                        ),
                        index: widget.shop.barbers.indexWhere(
                          (b) => b.id == widget.initialBarberId,
                        ),
                      )
                    else
                      BarberSwatchRow(
                        barbers: _roster,
                        tierOf: (b) =>
                            AppState.instance.barberSpotlightTier(b.id),
                        selectedId: _barberId,
                        onSelect: (id) => setState(() {
                          _barberId = id;
                          // Availability is per-barber — drop a time that
                          // is now taken for the newly chosen barber.
                          if (_time != null &&
                              _bookedSlots.contains(_time)) {
                            _time = null;
                          }
                        }),
                        dark: true,
                      ),
                    const SizedBox(height: 12),
                    _MyBarberToggle(
                      shopId: shop.id,
                      barber: shop.barbers.firstWhere(
                        (x) => x.id == _barberId,
                        orElse: () => shop.barbers.first,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MessageBarberButton(
                      shop: shop,
                      barber: shop.barbers.firstWhere(
                        (x) => x.id == _barberId,
                        orElse: () => shop.barbers.first,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PanelLabel(L.dayLabel),
                    DatePillRow(
                      dates: _days,
                      selectedIndex: _dateIndex,
                      onSelect: (i) => setState(() {
                        _dateIndex = i;
                        _time = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: PanelField(
                            value: _time == null
                                ? L.bkPickATime
                                : DateFormat('HH:mm').format(_time!),
                            onTap: _pickTime,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PanelField(
                          value: _picked.length == 1
                              ? _picked.first.name
                              : L.bkServicesCount(_picked.length),
                          expanded: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _StickyBookBar(
        total: _total,
        when: whenLabel,
        onBook: _bookFromBar,
      ),
    );
  }
}

/// The one blue hero on this page — the shop's tagline over the trust band
/// (rating · reviews · distance · price) as frosted-glass chips.
class _ShopHero extends StatelessWidget {
  const _ShopHero({required this.shop});

  final Barbershop shop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4AA3FF), Color(0xFF1E6FE0)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shop.isPremium) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      size: 13, color: AppColors.ink),
                  const SizedBox(width: 4),
                  Text(
                    L.bkPremiumBadge,
                    style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            shop.tagline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                icon: Icons.star_rounded,
                label: shop.rating.toStringAsFixed(1),
              ),
              _HeroChip(
                icon: Icons.reviews_outlined,
                label: L.reviewsCount(shop.reviewCount),
              ),
              _HeroChip(
                icon: Icons.near_me_outlined,
                label: shop.distanceLabel,
              ),
              _HeroChip(
                icon: Icons.payments_outlined,
                label: shop.priceLevelLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Frosted-glass chip that sits on the blue hero.
class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal strip of painted "interior photos" of the shop.
class _GalleryRow extends StatelessWidget {
  const _GalleryRow({required this.base, required this.premium});

  final Color base;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => ScaleIn(
          delay: Duration(milliseconds: i * 80),
          from: 0.88,
          duration: const Duration(milliseconds: 440),
          curve: AppCurves.easeOutQuart,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 132,
              child: CustomPaint(
                size: Size.infinite,
                painter: ShopInteriorPainter(
                    base: base, variant: i, premium: premium),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Flat card with the shop's blurb and the practical rows (hours, address)
/// as tinted icon-chip lines.
class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.shop});

  final Barbershop shop;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return PaperCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shop.description,
            style:
                AppTypography.body(context).copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.schedule_rounded, text: shop.openingHours),
          Divider(color: p.divider, height: 1),
          _InfoRow(icon: Icons.place_outlined, text: shop.address),
        ],
      ),
    );
  }
}

/// One practical line inside the about card: tinted icon chip + value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h4(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Always-visible booking bar pinned to the bottom of the detail screen.
class _StickyBookBar extends StatelessWidget {
  const _StickyBookBar({
    required this.total,
    required this.when,
    required this.onBook,
  });

  final double total;
  final String when;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 12 + bottom),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.border)),
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 12, color: AppColors.accent),
                  const SizedBox(width: 3),
                  Text(
                    when,
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                total == 0 ? L.bkPickAService : Money.som(total),
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: p.text,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: PrimaryButton(
              label: L.bookNow,
              height: 54,
              onPressed: onBook,
            ),
          ),
        ],
      ),
    );
  }
}

/// Availability nudge near the CTA — scarcity drives the tap.
class _ScarcityChip extends StatelessWidget {
  const _ScarcityChip({required this.count, required this.day});

  final int count;
  final String day;

  @override
  Widget build(BuildContext context) {
    final none = count <= 0;
    final low = count > 0 && count <= 4;
    final c = none
        ? const Color(0xFF8A93A3)
        : low
            ? const Color(0xFFE0683C)
            : const Color(0xFF2FA24E);
    final d = day.toLowerCase();
    final txt = none
        ? L.bkFullyBooked(d)
        : low
            ? L.bkOnlySlotsLeft(count, d)
            : L.bkSlotsOpen(count, d);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(low ? Icons.bolt_rounded : Icons.event_available_rounded,
              size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              txt,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: c,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The stylist the booking is locked to (arriving from the barber feed): a
/// fixed chip — avatar in the tier ring, name + status pill, specialty, and a
/// small lock. No colleague switching.
class _LockedStylistRow extends StatelessWidget {
  const _LockedStylistRow({required this.barber, required this.index});

  final Barber barber;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final tier = AppState.instance.barberSpotlightTier(barber.id);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tier == 0
              ? AppColors.gold
              : tier == 1
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : p.border,
          width: tier <= 1 ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          InitialAvatar(
              name: barber.name, size: 44, index: index < 0 ? 0 : index),
          const SizedBox(width: 10),
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
                    if (tier == 0) ...[
                      const SizedBox(width: 6),
                      MiniPill('⚡ ${L.boostedPill}',
                          style: MiniPillStyle.gold),
                    ] else if (tier == 1) ...[
                      const SizedBox(width: 6),
                      const MiniPill('VIP', style: MiniPillStyle.gold),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  barber.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.lock_rounded, size: 16, color: p.textTertiary),
        ],
      ),
    );
  }
}

/// A small star + label toggle to pin/unpin the selected barber as "my barber"
/// right inside the booking panel — the most natural place to choose one.
class _MyBarberToggle extends StatelessWidget {
  const _MyBarberToggle({required this.shopId, required this.barber});

  final String shopId;
  final Barber barber;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final mine = AppState.instance.isMyBarber(barber.id);
    final name = barber.name.split(' ').first;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (mine) {
          AppState.instance.clearMyBarber();
        } else {
          AppState.instance.setMyBarber(shopId: shopId, barberId: barber.id);
        }
      },
      child: Row(
        children: [
          Icon(
            mine ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 18,
            color: mine ? AppColors.gold : p.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mine
                  ? L.bkIsYourBarber(name)
                  : L.bkMakeMyBarber(name),
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A "message this barber" row inside the booking panel. Texting is a
/// post-booking feature, so this stays locked until the user has a booking
/// with the selected barber — then it opens a 1:1 chat thread.
class _MessageBarberButton extends StatelessWidget {
  const _MessageBarberButton({required this.shop, required this.barber});

  final Barbershop shop;
  final Barber barber;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final p = Paper.of(context);
        final name = barber.name.split(' ').first;
        final booked = AppState.instance.hasBookingWith(barber.id);

        if (!booked) {
          // Locked — teaches the funnel: book first, then you can message.
          return Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 16, color: p.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  L.bkMessageAfterBook(name),
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.textTertiary,
                  ),
                ),
              ),
            ],
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).push(
            FadeThroughPageRoute(
                child: ChatScreen(shop: shop, barber: barber)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  L.bkMessageName(name),
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: p.textTertiary),
            ],
          ),
        );
      },
    );
  }
}

void _showWriteReview(BuildContext context, String shopId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.5),
    builder: (_) => _WriteReviewSheet(shopId: shopId),
  );
}

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet({required this.shopId});

  final String shopId;

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _barberStars = 5;
  int _shopStars = 5;
  final _barberText = TextEditingController();
  final _shopText = TextEditingController();

  @override
  void dispose() {
    _barberText.dispose();
    _shopText.dispose();
    super.dispose();
  }

  void _post() {
    final shop = MockData.barbershops.firstWhere(
      (s) => s.id == widget.shopId,
      orElse: () => MockData.barbershops.first,
    );
    final barber = shop.barbers.first;
    // Dual-key: talent (barber) travels with the barber, vibe (shop) stays put.
    AppState.instance.addDualReview(
      shopId: widget.shopId,
      barberId: barber.id,
      barberName: barber.name,
      barberStars: _barberStars.toDouble(),
      barberText: _barberText.text,
      shopStars: _shopStars.toDouble(),
      shopText: _shopText.text,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L.reviewThanks)),
    );
  }

  Widget _reviewField(PaperPalette p, TextEditingController c, String hint) =>
      TextField(
        controller: c,
        maxLines: 2,
        minLines: 1,
        maxLength: 200,
        style: GoogleFonts.nunito(
            fontSize: 14, fontWeight: FontWeight.w600, color: p.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(color: p.textTertiary),
          filled: true,
          fillColor: p.cardAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          counterText: '',
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final barber = MockData.barbershops
        .firstWhere((s) => s.id == widget.shopId,
            orElse: () => MockData.barbershops.first)
        .barbers
        .first;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${L.rateYourBarber} · ${barber.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h3(context),
            ),
            const SizedBox(height: 10),
            StarInput(
              value: _barberStars,
              color: AppColors.gold,
              onChanged: (v) => setState(() => _barberStars = v),
            ),
            const SizedBox(height: 10),
            _reviewField(p, _barberText, L.barberReviewHint),
            const SizedBox(height: 18),
            Text(L.rateTheShop, style: AppTypography.h3(context)),
            const SizedBox(height: 10),
            StarInput(
              value: _shopStars,
              color: AppColors.accent,
              onChanged: (v) => setState(() => _shopStars = v),
            ),
            const SizedBox(height: 10),
            _reviewField(p, _shopText, L.shopReviewHint),
            const SizedBox(height: 16),
            PrimaryButton(label: L.postReview, height: 56, onPressed: _post),
          ],
        ),
      ),
    );
  }
}

class _ReviewsBlock extends StatelessWidget {
  const _ReviewsBlock({required this.shop});

  final Barbershop shop;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final barber = shop.barbers.first;
    final barberRevs = s.barberReviewsFor(barber.id);
    final shopRevs = s.userReviewsFor(shop.id);
    // Barber (talent) reviews travel with the barber; shop reviews stay put.
    final reviews =
        [...barberRevs, ...shopRevs, ...shop.reviews].take(4).toList();
    final total = shop.reviewCount + shopRevs.length + barberRevs.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(L.reviewsWord, style: AppTypography.h3(context)),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Review gating: only after you've actually booked/visited here,
              // so a barber can't harvest reviews from people who never came.
              onTap: () {
                if (AppState.instance.canReviewShop(shop.id)) {
                  _showWriteReview(context, shop.id);
                } else {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(L.reviewLockedHint),
                      behavior: SnackBarBehavior.floating,
                    ));
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rate_review_rounded,
                        size: 15, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      L.writeWord,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Two-axis at a glance: barber talent (gold) vs shop vibe (blue).
        DualRatingRow(
          barberStars: s.barberTalentRating(barber),
          barberCount: s.barberTalentCount(barber),
          shopStars: s.shopRating(shop),
          shopCount: s.shopReviewCount(shop),
        ),
        const SizedBox(height: 12),
        for (final r in reviews) ...[
          PaperCard(
            radius: 20,
            padding: const EdgeInsets.all(16),
            child: _ReviewCardBody(review: r),
          ),
          const SizedBox(height: 8),
        ],
        if (total > reviews.length)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showAllReviews(
                context, [...barberRevs, ...shopRevs, ...shop.reviews]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    L.bkMoreReviews(total - reviews.length),
                    style: AppTypography.caption(context).copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.accent),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Every review we actually have, in a scrollable sheet — the "+ N more"
  /// line opens this instead of being dead text.
  void _showAllReviews(BuildContext context, List<Review> all) {
    final p = Paper.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                    color: p.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),
            Text(L.reviewsWord, style: AppTypography.h2(context)),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final r in all) ...[
                    PaperCard(
                      radius: 20,
                      padding: const EdgeInsets.all(16),
                      child: _ReviewCardBody(review: r),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One review card, rendered for whichever axis it rates — gold "BARBER"
/// (talent) or blue "SHOP" (vibe) — so readers see which reputation it feeds.
class _ReviewCardBody extends StatelessWidget {
  const _ReviewCardBody({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final isBarber = review.barberRating != null;
    final stars = (isBarber ? review.barberRating! : review.rating).round();
    final comment = isBarber ? (review.barberComment ?? '') : review.comment;
    final color = isBarber ? AppColors.gold : AppColors.accentDeep;
    final tag = isBarber ? L.barberTag2 : L.shopTag;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(tag,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.3,
                  )),
            ),
            const Spacer(),
            for (var i = 0; i < 5; i++)
              Icon(Icons.star_rounded,
                  size: 13, color: i < stars ? color : p.border),
          ],
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(comment, style: AppTypography.body(context)),
        ],
        const SizedBox(height: 8),
        Text(review.author, style: AppTypography.caption(context)),
      ],
    );
  }
}
