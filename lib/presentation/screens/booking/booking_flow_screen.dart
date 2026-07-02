import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/hair_data.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/barbershop.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/service.dart';
import '../../widgets/booking_kit.dart';
import '../../widgets/paper_kit.dart';
import 'booking_review_screen.dart';

/// Compose a booking on one page: tick services, pick hands,
/// pick a day, tap a chair time — confirm in the dark panel.
class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({
    super.key,
    required this.shop,
    this.preselectedBarberId,
  });

  final Barbershop shop;
  final String? preselectedBarberId;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
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
    String? id = widget.preselectedBarberId;
    if (id == null) {
      final my = AppState.instance.myBarber;
      if (my != null && my.shop.id == widget.shop.id) id = my.barber.id;
    }
    _barberId = id; // null stays "anyone"
    // If today's chairs are all gone, start on tomorrow. Use the same working
    // hours the slot list uses, so the auto-advance matches what's shown.
    final now = DateTime.now();
    final s = AppState.instance;
    final todayLeft = MockData.timeSlotsFor(now,
            startHour: s.workStartHour, endHour: s.workEndHour)
        .any((t) => t.isAfter(now.add(const Duration(minutes: 30))));
    if (!todayLeft) _dateIndex = 1;
  }

  List<BarberService> get _picked => widget.shop.services
      .where((s) => _selectedServices.contains(s.id))
      .toList();

  double get _total => _picked.fold(0, (sum, s) => sum + s.price);

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

  /// Slots that are unavailable — the deterministic mock bookings plus the
  /// user's own upcoming bookings at this shop on the selected day.
  Set<DateTime> get _booked {
    final day = _days[_dateIndex];
    final s = AppState.instance;
    final mock = MockData.bookedSlotsFor(day,
        shopId: widget.shop.id,
        barberId: _barberId,
        startHour: s.workStartHour,
        endHour: s.workEndHour);
    // The user's own slots that hold time: pending requests + confirmed.
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

  void _confirm() {
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
    // Review/confirm first — that page finalises the booking.
    Navigator.of(context).push(
      FadeThroughPageRoute(child: BookingReviewScreen(booking: booking)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final shop = widget.shop;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
          children: [
            Row(
              children: [
                CircleBtn(
                  icon: Icons.arrow_back_rounded,
                  size: 42,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                const BarberLogo(size: 28),
              ],
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${L.newWord} ',
                      style: AppTypography.display(context),
                    ),
                    markerBoxSpan(
                        L.bookingWord, AppTypography.display(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: PaperCard(
                radius: 24,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    InitialAvatar(
                      name: shop.name,
                      size: 48,
                      index: MockData.barbershops.indexOf(shop),
                      square: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop.name, style: AppTypography.h3(context)),
                          const SizedBox(height: 2),
                          Text(
                            shop.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MiniPill('★ ${shop.rating.toStringAsFixed(1)}'),
                  ],
                ),
              ),
            ),
            if (AppState.instance.hasDesiredStyle) ...[
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: _DesiredStyleBanner(),
              ),
            ],
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: Row(
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
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < shop.services.length; i++) ...[
              FadeSlideIn(
                delay: Duration(milliseconds: 130 + i * 35),
                child: ServiceCheckRow(
                  service: shop.services[i],
                  selected: _selectedServices.contains(shop.services[i].id),
                  onTap: () => setState(() {
                    final id = shop.services[i].id;
                    if (_selectedServices.contains(id)) {
                      _selectedServices.remove(id);
                    } else {
                      _selectedServices.add(id);
                    }
                  }),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: InkPanel(
                title: L.whenAndWho,
                children: [
                  PanelLabel(L.withLabel),
                  BarberSwatchRow(
                    barbers: shop.barbers,
                    selectedId: _barberId,
                    onSelect: (id) => setState(() {
                      _barberId = id;
                      // Availability depends on the barber — drop a time that
                      // is now taken.
                      if (_time != null && _booked.contains(_time)) {
                        _time = null;
                      }
                    }),
                    dark: true,
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
                  PanelLabel(
                    L.timeFor(DateFormat('EEE d MMM').format(_days[_dateIndex])),
                  ),
                  TimeGrid(
                    slots: _slots,
                    booked: _booked,
                    selected: _time,
                    onSelect: (t) => setState(() => _time = t),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _confirm,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(
                          _total == 0
                              ? L.confirmBooking
                              : L.confirmPrice(Money.som(_total)),
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the look the user picked in Style Studio, with a way to drop it.
class _DesiredStyleBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final id = AppState.instance.desiredStyleId;
        if (id == null) return const SizedBox.shrink();
        final style = HairData.byId(id);
        return PaperCard(
          radius: 22,
          color: AppColors.accentSoft,
          borderColor: AppColors.accent,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentDeep,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(style.icon, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L.requestedLook,
                        style: AppTypography.caption(context)),
                    const SizedBox(height: 1),
                    Text(style.name, style: AppTypography.h4(context)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => AppState.instance.clearDesiredStyle(),
                child: Icon(Icons.close_rounded,
                    size: 20, color: Paper.of(context).textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}
