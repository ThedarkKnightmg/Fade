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

/// One shop, one page: a storefront hero with the name + trust band over it,
/// an "inside the shop" gallery, the service list, reviews, a booking panel,
/// and a sticky Book bar pinned to the bottom.
class BarbershopDetailScreen extends StatefulWidget {
  const BarbershopDetailScreen({super.key, required this.shop});

  final Barbershop shop;

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

  late final List<DateTime> _days = List.generate(7, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: i));
  });

  @override
  void initState() {
    super.initState();
    final my = AppState.instance.myBarber;
    if (my != null && my.shop.id == widget.shop.id) {
      _barberId = my.barber.id;
    } else {
      _barberId = widget.shop.barbers.first.id;
    }
    final now = DateTime.now();
    final hours = AppState.instance;
    final todayLeft = MockData.timeSlotsFor(now,
            startHour: hours.workStartHour, endHour: hours.workEndHour)
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
    final now = DateTime.now();
    final s = AppState.instance;
    return MockData.timeSlotsFor(day,
            startHour: s.workStartHour, endHour: s.workEndHour)
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
    final mock = MockData.bookedSlotsFor(day,
        shopId: widget.shop.id,
        barberId: _barberId,
        startHour: s.workStartHour,
        endHour: s.workEndHour);
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
          color: p.panel,
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
                  color: p.panelField,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            PanelLabel(
              'free chairs · ${DateFormat('EEE d MMM').format(_days[_dateIndex])}',
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
      ? 'Today'
      : i == 1
          ? 'Tomorrow'
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
        ? 'Choose a time'
        : '${_dayWord(_dateIndex)} · ${DateFormat('HH:mm').format(_time!)}';

    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final fav = AppState.instance.isFavourite(shop.id);
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
                  _ShopHero(
                    shop: shop,
                    base: base,
                    favourite: fav,
                    onBack: () => Navigator.of(context).maybePop(),
                    onFavourite: () =>
                        AppState.instance.toggleFavourite(shop.id),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(L.insideTheShop,
                            style: AppTypography.h4(context)),
                        const SizedBox(height: 10),
                        _GalleryRow(base: base, premium: shop.isPremium),
                        const SizedBox(height: 20),
                        Text.rich(
                          TextSpan(
                            children: [
                              markerSpan(
                                shop.tagline,
                                AppTypography.body(context)
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                              TextSpan(
                                text: ' — ${shop.description}',
                                style: AppTypography.body(context)
                                    .copyWith(color: p.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InfoLine(
                          icon: Icons.schedule_rounded,
                          text: shop.openingHours,
                        ),
                        const SizedBox(height: 6),
                        _InfoLine(
                          icon: Icons.place_outlined,
                          text: shop.address,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(L.services, style: AppTypography.h2(context)),
                            const Spacer(),
                            Text(
                              L.tickWhatYouNeed,
                              style: AppTypography.scribble(context, size: 19)
                                  .copyWith(color: p.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < shop.services.length; i++) ...[
                          ServiceCheckRow(
                            service: shop.services[i],
                            selected: _selectedServices
                                .contains(shop.services[i].id),
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
                        const SizedBox(height: 16),
                        _ReviewsBlock(shop: shop),
                        const SizedBox(height: 18),
                        _ScarcityChip(
                            count: freeCount, day: _dayWord(_dateIndex)),
                        const SizedBox(height: 12),
                        InkPanel(
                          title: 'Book your visit',
                          trailing: Text(
                            _minutes == 0 ? '—' : '$_minutes min',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: p.panelTextDim,
                            ),
                          ),
                          children: [
                            const PanelLabel('with'),
                            BarberSwatchRow(
                              barbers: shop.barbers,
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
                            const PanelLabel('day'),
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
                                        ? 'Pick a time'
                                        : DateFormat('HH:mm').format(_time!),
                                    onTap: _pickTime,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PanelField(
                                  value: _picked.length == 1
                                      ? _picked.first.name
                                      : '${_picked.length} services',
                                  expanded: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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

/// Full-bleed storefront hero with the back/heart controls, the shop name and
/// a trust band (rating · reviews · distance · price) over a scrim.
class _ShopHero extends StatelessWidget {
  const _ShopHero({
    required this.shop,
    required this.base,
    required this.favourite,
    required this.onBack,
    required this.onFavourite,
  });

  final Barbershop shop;
  final Color base;
  final bool favourite;
  final VoidCallback onBack;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 254 + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: ShopCoverPainter(base: base, premium: shop.isPremium),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x40000000), Colors.transparent, Color(0xC2000000)],
                stops: [0.0, 0.42, 1.0],
              ),
            ),
          ),
          Positioned(
            top: top + 10,
            left: 14,
            right: 14,
            child: Row(
              children: [
                _RoundIconBtn(
                    icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
                const Spacer(),
                _RoundIconBtn(
                  icon: favourite
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  iconColor:
                      favourite ? AppColors.red : const Color(0xFF1A1A1A),
                  onTap: onFavourite,
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (shop.isPremium) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF2C75A), Color(0xFFD99A2E)],
                      ),
                      borderRadius: BorderRadius.circular(999),
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
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  shop.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.05,
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TrustChip(
                      icon: Icons.star_rounded,
                      label: shop.rating.toStringAsFixed(1),
                      iconColor: const Color(0xFFFFC53D),
                    ),
                    _TrustChip(
                      icon: Icons.reviews_outlined,
                      label: '${shop.reviewCount} reviews',
                    ),
                    _TrustChip(
                      icon: Icons.near_me_outlined,
                      label: shop.distanceLabel,
                    ),
                    _TrustChip(
                      icon: Icons.payments_outlined,
                      label: shop.priceLevelLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF1A1A1A),
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 19, color: iconColor),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: p.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall(context),
          ),
        ),
      ],
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
                total == 0 ? 'Pick a service' : Money.som(total),
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
            child: GestureDetector(
              onTap: onBook,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        L.bookNow,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
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
    final p = Paper.of(context);
    final none = count <= 0;
    final low = count > 0 && count <= 4;
    final c = none
        ? const Color(0xFF8A93A3)
        : low
            ? const Color(0xFFE0683C)
            : const Color(0xFF2FA24E);
    final d = day.toLowerCase();
    final txt = none
        ? 'Fully booked $d — try another day'
        : low
            ? 'Only $count slots left $d'
            : '$count slots open $d';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: clayDecoration(
        p,
        color: Color.alphaBlend(c.withValues(alpha: 0.12), p.card),
        radius: 12,
        borderColor: c.withValues(alpha: 0.40),
      ),
      child: Row(
        children: [
          Icon(low ? Icons.bolt_rounded : Icons.event_available_rounded,
              size: 16, color: c),
          const SizedBox(width: 8),
          Text(
            txt,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
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
            color: mine ? AppColors.gold : p.panelTextDim,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mine
                  ? '$name is your barber — tap to unpin'
                  : 'Make $name my barber',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: p.panelText,
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
                  size: 16, color: p.panelTextDim),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Message $name after you book',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.panelTextDim,
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
                  'Message $name',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.panelText,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: p.panelTextDim),
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
            fontSize: 14, fontWeight: FontWeight.w600, color: p.panelText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(color: p.panelTextDim),
          filled: true,
          fillColor: p.panelField,
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
          color: p.panel,
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
                  color: p.panelField,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${L.rateYourBarber} · ${barber.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.panelText,
              ),
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
            Text(
              L.rateTheShop,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.panelText,
              ),
            ),
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
            Text(L.reviewsWord, style: AppTypography.h2(context)),
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
                      'Write',
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
        const SizedBox(height: 14),
        for (final r in reviews) ...[
          PaperCard(
            radius: 24,
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
                    '+ ${total - reviews.length} more reviews',
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: p.border, borderRadius: BorderRadius.circular(2)),
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
                      radius: 24,
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
                color: color.withValues(alpha: 0.14),
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
          Text('"$comment"', style: AppTypography.scribble(context, size: 22)),
        ],
        const SizedBox(height: 8),
        Text(review.author,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: p.textSecondary,
            )),
      ],
    );
  }
}
