import 'package:flutter/cupertino.dart'
    show CupertinoSliverRefreshControl, RefreshIndicatorMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/motion.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/barbershop.dart';
import '../../../data/models/booking.dart';
import '../../widgets/barbershop_card.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../barbershop_detail/barbershop_detail_screen.dart';
import '../location/address_picker_screen.dart';
import '../map/shops_map_screen.dart';

/// Home — "Homies" dark layout: location banner, address/share, a big
/// bookings card, and the list of nearby barbershops.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.onOpenBookings,
    this.onOpenProfile,
    this.onOpenAi,
  });

  final VoidCallback? onSearchTap;
  final VoidCallback? onOpenBookings;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenAi;

  void _openMap(BuildContext context) {
    Navigator.of(context).push(
      FadeThroughPageRoute(child: const ShopsMapScreen()),
    );
  }

  /// Ask the device for its location and save a readable label.
  Future<void> _detectLocation(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(L.findingLocation),
      duration: const Duration(seconds: 2),
    ));
    final label = await detectLocationLabel();
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    if (label == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(L.locationFailed),
      ));
      return;
    }
    AppState.instance.setAddress(label);
    messenger.showSnackBar(
      SnackBar(content: Text(L.locationDetected)),
    );
  }

  /// A Yandex-style pre-permission explainer. On "Allow" we trigger the real
  /// device prompt (via [_detectLocation]); the detected city then fills the
  /// top bar.
  Future<void> _askLocation(BuildContext context) async {
    final p = Paper.of(context);
    final allow = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: p.card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.near_me_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text(L.findShopsNearYou, style: AppTypography.h2(context)),
              const SizedBox(height: 8),
              Text(
                L.locationExplainer,
                style: AppTypography.bodySmall(context),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: p.border),
                        ),
                        child: Text(
                          L.notNow,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          L.allow,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (allow == true && context.mounted) {
      await _detectLocation(context);
    }
  }

  void _openMenu(BuildContext context) {
    final p = Paper.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        Widget item(IconData icon, String label, VoidCallback onTap) {
          return ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            title: Text(label, style: AppTypography.h4(context)),
            trailing: Icon(Icons.chevron_right_rounded, color: p.textTertiary),
            onTap: () {
              Navigator.pop(sheetCtx);
              onTap();
            },
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: p.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 10),
                item(Icons.search_rounded, L.searchShops,
                    () => onSearchTap?.call()),
                item(Icons.map_rounded, L.shopsOnMap,
                    () => _openMap(context)),
                item(Icons.event_note_rounded, L.myBookings,
                    () => onOpenBookings?.call()),
                item(Icons.person_rounded, L.myProfile,
                    () => onOpenProfile?.call()),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _enterAddress(BuildContext context) async {
    final controller =
        TextEditingController(text: AppState.instance.address ?? '');
    final p = Paper.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: p.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L.yourAddress, style: AppTypography.h3(context)),
              const SizedBox(height: 4),
              Text(L.addressHelp, style: AppTypography.bodySmall(context)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: p.text),
                decoration: InputDecoration(
                  hintText: L.addressExample,
                  counterText: '',
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: L.cancel,
                      height: 48,
                      style: PrimaryButtonStyle.ghost,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: L.save,
                      height: 48,
                      onPressed: () => Navigator.pop(ctx, controller.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      AppState.instance.setAddress(result);
      if (context.mounted && result.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L.addressSaved)),
        );
      }
    }
  }

  /// Open the full location picker: type an address by hand, or drop a pin on
  /// a real map of Uzbekistan (it also has a locate-me button for GPS).
  void _openAddressPicker(BuildContext context) {
    Navigator.of(context).push(
      FadeThroughPageRoute(child: const AddressPickerScreen()),
    );
  }

  /// Tapping the points pill opens the bonus / VIP-progress sheet.
  void _showBonus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BonusSheet(
        onProfile: () {
          Navigator.pop(ctx);
          onOpenProfile?.call();
        },
      ),
    );
  }

  Widget _shopCard(BuildContext context, Barbershop shop) {
    return BarbershopCard(
      shop: shop,
      index: MockData.barbershops.indexOf(shop),
      isFavourite: AppState.instance.favouriteShopIds.contains(shop.id),
      onTap: () => Navigator.of(context).push(
        FadeThroughPageRoute(child: BarbershopDetailScreen(shop: shop)),
      ),
      onFavourite: () => AppState.instance.toggleFavourite(shop.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        // First open with no address yet → ask for location (once).
        if (state.address == null && !state.locationPromptShown) {
          state.markLocationPromptShown();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) _askLocation(context);
          });
        }
        // A booking lives in three home states, and each shows a different
        // card:
        //   • requested  → "Waiting for reply" (barber hasn't accepted yet)
        //   • upcoming   → the "My bookings" hero (barber confirmed)
        //   • completed  → unlocks the "Book your usual" rebook trigger
        final pendingBookings = state.bookingsByStatus(BookingStatus.requested)
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        final confirmedBookings = state.bookingsByStatus(BookingStatus.upcoming)
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        // "Book your usual" is earned — it only appears once the user has
        // actually sat in the chair at least once (a completed visit).
        final hasVisited =
            state.bookingsByStatus(BookingStatus.completed).isNotEmpty;
        final shops = MockData.barbershops;

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Soft blue airy canvas from the palette in both modes —
                    // cards float bright-white on top of it.
                    colors: [p.bgGradientTop, p.bg],
                    stops: const [0, 0.5],
                  ),
                ),
              ),
            ),
            // Soft electric-blue glow behind the header for depth.
            Positioned(
              top: -140,
              left: -60,
              right: -60,
              child: IgnorePointer(
                child: Container(
                  height: 360,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        // Subtle in light mode for a clean Yandex-white header.
                        AppColors.accent
                            .withValues(alpha: p.isDark ? 0.22 : 0.07),
                        AppColors.accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: _RevealScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
              children: [
                // Header: menu · logo + "Home ›" · points pill (Yandex-style).
                Row(
                  children: [
                    _RoundIcon(
                      icon: Icons.menu_rounded,
                      onTap: () => _openMenu(context),
                    ),
                    Expanded(
                      child: Center(
                        child: _BrandMark(
                          subtitle: state.address ?? L.setLocation,
                          onTap: () {
                            if (state.address == null) {
                              _askLocation(context);
                            } else {
                              _enterAddress(context);
                            }
                          },
                        ),
                      ),
                    ),
                    _PointsPill(onTap: () => _showBonus(context)),
                  ],
                ),
                const SizedBox(height: 22),
                // Find shops near you — placed ABOVE the quick tiles so it sits
                // at the top until the user sets a location.
                if (state.address == null) ...[
                  FadeSlideIn(
                    child: PressableScale(
                      onTap: () => _detectLocation(context),
                      child: Row(
                        children: [
                          RadarPulse(
                            maxRadius: 26,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.near_me_rounded,
                                  color: Colors.white, size: 26),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(L.findShopsNearYou,
                                    style: AppTypography.h3(context)),
                                const SizedBox(height: 2),
                                Text(
                                  L.tapToDetect,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall(context),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: p.textTertiary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PillButton(
                            icon: Icons.edit_location_alt_outlined,
                            label: L.enterAddress,
                            filled: false,
                            onTap: () => _openAddressPicker(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PillButton(
                            icon: Icons.my_location_rounded,
                            label: L.locateMe,
                            filled: true,
                            onTap: () => _detectLocation(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Yandex-style quick actions — the big, appealing tiles.
                _QuickActions(
                  onBook: () => onSearchTap?.call(),
                  onAi: () => onOpenAi?.call(),
                  onMap: () => _openMap(context),
                  onCuts: () => onOpenBookings?.call(),
                ),
                const SizedBox(height: 18),
                // Book your usual — the rebook trigger. Earned AND exclusive:
                // it only shows once a visit is COMPLETED *and* there is no live
                // booking in flight (a pending request → "Waiting for reply";
                // a confirmed one → the "My bookings" hero take priority). So
                // right after booking it stays hidden, and re-appears — with a
                // celebratory entrance — only after that cut is done.
                if (hasVisited &&
                    state.hasMyBarber &&
                    pendingBookings.isEmpty &&
                    confirmedBookings.isEmpty) ...[
                  const SizedBox(height: 16),
                  _CelebrateIn(
                    child: _BookAgainCard(
                      ref: state.myBarber!,
                      onTap: () => Navigator.of(context).push(
                        FadeThroughPageRoute(
                          child: BarbershopDetailScreen(
                              shop: state.myBarber!.shop),
                        ),
                      ),
                    ),
                  ),
                ],
                // Waiting for reply — the moment after booking, before the
                // barber accepts. Deliberately NOT the "My bookings" hero yet.
                if (pendingBookings.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: _PendingRequestCard(
                      requests: pendingBookings,
                      onTap: onOpenBookings,
                    ),
                  ),
                ],
                // My bookings hero — only once a barber has CONFIRMED.
                if (confirmedBookings.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: _BookingsCard(
                      upcoming: confirmedBookings,
                      onTap: onOpenBookings,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                // Filterable shops list — chips (All / Premium / Top / Budget)
                // sit above the list so you narrow it to what you want.
                _ShopsSection(
                  shops: shops,
                  card: (s) => _shopCard(context, s),
                  onSeeAll: onSearchTap,
                ),
              ],
            ),
          ),
          ],
        );
      },
    );
  }
}

/// Home shop-list filters.
enum _HomeFilter { all, premium, top, budget }

String _homeFilterLabel(_HomeFilter f) => switch (f) {
      _HomeFilter.all => L.mapFilterAll,
      _HomeFilter.premium => L.mapFilterPremium,
      _HomeFilter.top => L.filterTopRated,
      _HomeFilter.budget => L.mapFilterBudget,
    };

/// Filterable shops list: chips (All / Premium / Top rated / Budget) above the
/// cards so you narrow the list to what you want. Premium shops lead on "All".
class _ShopsSection extends StatefulWidget {
  const _ShopsSection({
    required this.shops,
    required this.card,
    required this.onSeeAll,
  });

  final List<Barbershop> shops;
  final Widget Function(Barbershop) card;
  final VoidCallback? onSeeAll;

  @override
  State<_ShopsSection> createState() => _ShopsSectionState();
}

class _ShopsSectionState extends State<_ShopsSection> {
  _HomeFilter _f = _HomeFilter.all;

  List<Barbershop> _list() {
    final s = widget.shops;
    switch (_f) {
      case _HomeFilter.all:
        return [
          ...s.where((x) => x.isPremium),
          ...s.where((x) => !x.isPremium),
        ];
      case _HomeFilter.premium:
        return s.where((x) => x.isPremium).toList();
      case _HomeFilter.top:
        return [...s]..sort((a, b) => b.rating.compareTo(a.rating));
      case _HomeFilter.budget:
        return [...s]..sort((a, b) => a.priceLevel.compareTo(b.priceLevel));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter chips.
        ScrollReveal(
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                for (final f in _HomeFilter.values) ...[
                  _HomeFilterChip(
                    label: _homeFilterLabel(f),
                    selected: f == _f,
                    onTap: () => setState(() => _f = f),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ScrollReveal(
          child: Row(
            children: [
              Text(
                _f == _HomeFilter.all ? L.barbershops : _homeFilterLabel(_f),
                style: AppTypography.h2(context),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onSeeAll,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  L.seeAll,
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final shop in list) ...[
          ScrollReveal(child: widget.card(shop)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HomeFilterChip extends StatelessWidget {
  const _HomeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : p.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.accent : p.border),
          boxShadow: [
            BoxShadow(
                color: p.shadow, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : p.text,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Header bits.
// ============================================================

/// Yandex-style quick-action grid — four big, soft-tinted tiles for the app's
/// main jobs (book, AI try-on, map, bookings), each colour-coded.
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onBook,
    required this.onAi,
    required this.onMap,
    required this.onCuts,
  });

  final VoidCallback onBook;
  final VoidCallback onAi;
  final VoidCallback onMap;
  final VoidCallback onCuts;

  @override
  Widget build(BuildContext context) {
    // Inset + wider gaps make the four tiles read as smaller, more separated
    // cards (closer to Yandex's proportions).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickTile(
                  icon: Icons.content_cut_rounded,
                  color: AppColors.accent,
                  label: L.quickBook,
                  sub: L.quickBookSub,
                  asset: 'assets/tiles/book.png',
                  onTap: onBook,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickTile(
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF7A3CF0),
                  label: L.quickAi,
                  sub: L.quickAiSub,
                  asset: 'assets/tiles/ai_star.png',
                  onTap: onAi,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickTile(
                  icon: Icons.map_rounded,
                  color: const Color(0xFF1FA463),
                  label: L.quickNear,
                  sub: L.quickNearSub,
                  asset: 'assets/tiles/map.png',
                  onTap: onMap,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickTile(
                  icon: Icons.event_note_rounded,
                  color: const Color(0xFFD99A2E),
                  label: L.quickCuts,
                  sub: L.quickCutsSub,
                  asset: 'assets/tiles/cuts.png',
                  onTap: onCuts,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.sub,
    required this.onTap,
    this.asset,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  final VoidCallback onTap;

  /// Optional 3D sticker PNG (assets/tiles/…). Falls back to [icon] if missing.
  final String? asset;

  Widget _iconChip(PaperPalette p, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: p.isDark ? 0.28 : 0.18),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, size: size * 0.5, color: color),
      );

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // Yandex-style: a flat light-gray box with the big 3D sticker centred
    // inside it and the label centred at the bottom (inside the box).
    const double s = 110;
    final Widget sticker = asset == null
        ? _iconChip(p, 84)
        : asset!.endsWith('.svg')
            ? SvgPicture.asset(asset!, width: s, height: s)
            : Image.asset(
                asset!,
                width: s,
                height: s,
                fit: BoxFit.contain,
                // Decode the ~1MB PNG down to display size so it never janks.
                cacheWidth: 330,
                cacheHeight: 330,
                filterQuality: FilterQuality.medium,
                // Missing PNG → fall back to the vector sticker.
                errorBuilder: (_, __, ___) => SvgPicture.asset(
                  asset!.replaceFirst('.png', '.svg'),
                  width: s,
                  height: s,
                ),
              );

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.96,
      child: Container(
        height: 138,
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        // Puffy clay tile (shared clay surface) instead of the old flat box.
        decoration: clayDecoration(p, radius: 26),
        child: Column(
          children: [
            // Big sticker, centred in the upper area of the box.
            Expanded(
              child: Center(
                child: FittedBox(fit: BoxFit.contain, child: sticker),
              ),
            ),
            const SizedBox(height: 4),
            // Label centred at the bottom, INSIDE the box (Yandex layout).
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The home scroll view. Owns a controller and exposes it through
/// [PrimaryScrollController] so [ScrollReveal] children reveal in sync with
/// scrolling. Bouncing physics gives the scroll a smooth, premium feel.
class _RevealScrollView extends StatefulWidget {
  const _RevealScrollView({required this.padding, required this.children});

  final EdgeInsets padding;
  final List<Widget> children;

  @override
  State<_RevealScrollView> createState() => _RevealScrollViewState();
}

class _RevealScrollViewState extends State<_RevealScrollView> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 950));
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _controller,
      child: CustomScrollView(
        controller: _controller,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            refreshTriggerPullDistance: 120,
            refreshIndicatorExtent: 78,
            onRefresh: _onRefresh,
            builder: (context, mode, pulled, trigger, _) =>
                _PoleRefresh(mode: mode, pulled: pulled, trigger: trigger),
          ),
          SliverPadding(
            padding: widget.padding,
            sliver: SliverList(
              delegate: SliverChildListDelegate(widget.children),
            ),
          ),
        ],
      ),
    );
  }
}

/// A creative pull-to-refresh — a glossy barber pole that scales in as you
/// pull and spins while refreshing (instead of a plain rotating arrow).
class _PoleRefresh extends StatefulWidget {
  const _PoleRefresh({
    required this.mode,
    required this.pulled,
    required this.trigger,
  });

  final RefreshIndicatorMode mode;
  final double pulled;
  final double trigger;

  @override
  State<_PoleRefresh> createState() => _PoleRefreshState();
}

class _PoleRefreshState extends State<_PoleRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = (widget.pulled / widget.trigger).clamp(0.0, 1.0);
    final active = widget.mode == RefreshIndicatorMode.armed ||
        widget.mode == RefreshIndicatorMode.refresh;
    return Center(
      child: Opacity(
        opacity: (t * 1.4).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.7 + 0.3 * t,
          child: AnimatedBuilder(
            animation: _spin,
            builder: (_, __) => CustomPaint(
              size: const Size(26, 54),
              painter: _BarberPolePainter(phase: active ? _spin.value : t * 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glossy barber pole — white capsule with diagonal red/blue stripes that
/// scroll with [phase] to read as a spinning pole.
class _BarberPolePainter extends CustomPainter {
  _BarberPolePainter({required this.phase});
  final double phase;

  static const _red = Color(0xFFE5392F);
  static const _blue = Color(0xFF2E8BFF);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width / 2),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    const sp = 17.0;
    final off = (phase * sp * 2) % (sp * 2);
    void band(double y, Color c) {
      final p = Path()
        ..moveTo(0, y)
        ..lineTo(size.width, y - size.width)
        ..lineTo(size.width, y - size.width + sp * 0.72)
        ..lineTo(0, y + sp * 0.72)
        ..close();
      canvas.drawPath(p, Paint()..color = c);
    }

    for (var y = -size.width;
        y < size.height + size.width + sp * 2;
        y += sp * 2) {
      band(y + off, _red);
      band(y + off + sp, _blue);
    }
    // Soft vertical gloss.
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.16, 0, size.width * 0.22, size.height),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFD7DEEA),
    );
  }

  @override
  bool shouldRepaint(_BarberPolePainter old) => old.phase != phase;
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.subtitle, this.onTap});

  /// The current location/address shown under the logo (or "Set location").
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D9BFF), Color(0xFF1E6FE0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.content_cut_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Fade',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Current location chip — tap to set or change it.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_rounded, size: 14, color: p.textSecondary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    subtitle ?? L.setLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: p.text,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 14, color: p.bg),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Yandex-Plus-style loyalty pill in the header: cuts count + scissors badge,
/// on a pink→purple→blue gradient. Taps through to the VIP/profile screen.
class _PointsPill extends StatelessWidget {
  const _PointsPill({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cuts = AppState.instance.totalCuts;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 5, 5, 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFF2D7E), Color(0xFF7A3CF0), Color(0xFF2E8BFF)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7A3CF0).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: cuts.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                '${v.round()}',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.content_cut_rounded,
                  size: 16, color: Color(0xFF7A3CF0)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bonus / loyalty sheet that slides up when the points pill is tapped —
/// points balance, an animated VIP-progress bar, streak, and (zero-cost) perks.
class _BonusSheet extends StatelessWidget {
  const _BonusSheet({required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    const goal = 16;
    final cuts = AppState.instance.totalCuts;
    final pct = (cuts / goal).clamp(0.0, 1.0);
    final remaining = goal - cuts;
    final streak = 2 + (cuts % 7);

    Widget perk(IconData icon, String title, String sub) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.nunito(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: p.text)),
                    Text(sub, style: AppTypography.bodySmall(context)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF2D7E),
                          Color(0xFF7A3CF0),
                          Color(0xFF2E8BFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$cuts',
                            style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const SizedBox(width: 6),
                        const Icon(Icons.content_cut_rounded,
                            size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(L.fadePoints, style: AppTypography.h3(context)),
                        Text(L.rewardsVipProgress,
                            style: AppTypography.bodySmall(context)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0683C).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(L.streakWeeks(streak),
                        style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFD0682F))),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    backgroundColor: p.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                remaining <= 0 ? L.vipUnlocked : L.cutsToVip(remaining),
                style: AppTypography.bodySmall(context),
              ),
              const SizedBox(height: 8),
              perk(Icons.bolt_rounded, L.perkPriority, L.perkPrioritySub),
              perk(Icons.fast_forward_rounded, L.perkSkipQueue,
                  L.perkSkipQueueSub),
              perk(Icons.workspace_premium_rounded, L.perkRecognition,
                  L.perkRecognitionSub),
              const SizedBox(height: 20),
              PrimaryButton(
                label: L.openProfile,
                height: 52,
                style: PrimaryButtonStyle.ghost,
                onPressed: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: p.text),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Material(
      color: filled ? AppColors.accent : p.card,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: p.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20, color: filled ? Colors.white : p.textSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: filled ? Colors.white : p.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Bookings hero card.
// ============================================================

/// One-time celebratory entrance. The child springs up into place with an
/// elastic overshoot + fade so that coming back to rebook feels like a little
/// reward, not just another row appearing.
class _CelebrateIn extends StatefulWidget {
  const _CelebrateIn({required this.child});
  final Widget child;

  @override
  State<_CelebrateIn> createState() => _CelebrateInState();
}

class _CelebrateInState extends State<_CelebrateIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );
  late final Animation<double> _spring = CurvedAnimation(
    parent: _c,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _rise = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // elasticOut overshoots past 1.0 then settles — the tiny bounce reads
        // as "pop!" without ever shrinking the card below 0.86.
        final scale = 0.86 + 0.14 * _spring.value;
        return Opacity(
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - _rise.value)),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// "Waiting for reply" — shown the instant a request is sent, until the barber
/// accepts it. Amber (never the confirmed blue) so the state reads as *pending*
/// at a glance, with a slowly flipping hourglass + live dots to feel alive.
class _PendingRequestCard extends StatefulWidget {
  const _PendingRequestCard({required this.requests, required this.onTap});

  final List<Booking> requests;
  final VoidCallback? onTap;

  @override
  State<_PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends State<_PendingRequestCard>
    with SingleTickerProviderStateMixin {
  static const double _pi = 3.1415926536;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Sits upright, does a crisp 180° flip, holds, flips back — like turning a
  // real hourglass over when the sand runs out.
  double _hourglassAngle(double t) {
    if (t < 0.14) return _pi * Curves.easeInOut.transform(t / 0.14);
    if (t < 0.5) return _pi;
    if (t < 0.64) {
      return _pi + _pi * Curves.easeInOut.transform((t - 0.5) / 0.14);
    }
    return 2 * _pi;
  }

  @override
  Widget build(BuildContext context) {
    final reqs = widget.requests;
    final next = reqs.first;
    final many = reqs.length > 1;
    final sub =
        many ? L.waitingMany(reqs.length) : L.waitingSub(next.barber.name);

    return PressableScale(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEA8600).withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFB44C), Color(0xFFF08A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationZ(_hourglassAngle(_c.value)),
                      child: const Icon(Icons.hourglass_top_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
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
                              L.waitingTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PendingDots(controller: _c),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        L.waitingHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A little "· · ·" that breathes — a thinking indicator signalling the
/// request is live and being looked at. Triangle-wave fade, no math import.
class _PendingDots extends StatelessWidget {
  const _PendingDots({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (controller.value + i / 3) % 1.0;
            final tri = t < 0.5 ? t * 2 : (1 - t) * 2; // 0→1→0
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35 + 0.6 * tri),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Book-first re-engagement trigger — one tap back to the user's usual barber.
/// Rebooking is the highest-converting action, so it leads the home screen.
class _BookAgainCard extends StatelessWidget {
  const _BookAgainCard({required this.ref, required this.onTap});

  final BarberRef ref;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accent, AppColors.accentDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L.bookYourUsual,
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ref.barber.name} · ${ref.shop.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                L.rebook,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bookings hero: a blue gradient card centred on the user's *next*
/// visit and what it costs. The green money chip flips between the next
/// cut's price and the full upcoming total when tapped.
class _BookingsCard extends StatefulWidget {
  const _BookingsCard({required this.upcoming, required this.onTap});

  final List<Booking> upcoming;
  final VoidCallback? onTap;

  @override
  State<_BookingsCard> createState() => _BookingsCardState();
}

class _BookingsCardState extends State<_BookingsCard> {
  /// false → show the next visit's price; true → show all upcoming summed.
  bool _showTotal = false;

  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _mo = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final days = DateTime(dt.year, dt.month, dt.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days <= 0) return L.today;
    if (days == 1) return L.tomorrow;
    if (days < 7) return L.inDays(days);
    return '${_wd[dt.weekday - 1]} ${dt.day} ${_mo[dt.month - 1]}';
  }

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final upcoming = widget.upcoming;
    final count = upcoming.length;
    final next = count > 0 ? upcoming.first : null;
    final total = upcoming.fold<double>(0, (sum, b) => sum + b.service.price);
    final nextCost = next?.service.price ?? 0;
    final canToggle = count > 1;
    final shownCost = ((_showTotal && canToggle) ? total : nextCost).round();

    return PressableScale(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SheenSweep(
          radius: 28,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3D9BFF), Color(0xFF1E6FE0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: icon · title/subtitle · chevron.
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.event_available_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            L.myBookings,
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            next == null
                                ? L.noUpcomingCuts
                                : L.upcomingNext(count,
                                    _dayLabel(next.dateTime).toLowerCase()),
                            style: GoogleFonts.nunito(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (next != null)
                  _NextVisitPanel(
                    booking: next,
                    cost: shownCost,
                    showTotal: _showTotal && canToggle,
                    canToggle: canToggle,
                    dayLabel: _dayLabel(next.dateTime),
                    time: _time(next.dateTime),
                    onToggle: () => setState(() => _showTotal = !_showTotal),
                  )
                else
                  _emptyPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline_rounded,
              color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              L.bookNextCut,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inner panel: the next appointment on the left, an interactive green
/// money chip on the right (tap to flip this-visit ↔ all-upcoming).
class _NextVisitPanel extends StatelessWidget {
  const _NextVisitPanel({
    required this.booking,
    required this.cost,
    required this.showTotal,
    required this.canToggle,
    required this.dayLabel,
    required this.time,
    required this.onToggle,
  });

  final Booking booking;
  final int cost;
  final bool showTotal;
  final bool canToggle;
  final String dayLabel;
  final String time;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left — the next visit details.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      L.nextVisit,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  booking.service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.barber.name} · ${booking.barbershop.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        '$dayLabel · $time',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right — the green money chip.
          _MoneyChip(
            cost: cost,
            showTotal: showTotal,
            canToggle: canToggle,
            onTap: onToggle,
          ),
        ],
      ),
    );
  }
}

/// The "lighter green" cost chip. Animates the amount on change and, when
/// there's more than one upcoming visit, flips between this-visit and the
/// upcoming total on tap (a small swap hint nudges the user).
class _MoneyChip extends StatelessWidget {
  const _MoneyChip({
    required this.cost,
    required this.showTotal,
    required this.canToggle,
    required this.onTap,
  });

  final int cost;
  final bool showTotal;
  final bool canToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const mint = AppColors.greenLight;
    return PressableScale(
      onTap: canToggle ? onTap : null,
      pressedScale: 0.9,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: mint.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mint.withValues(alpha: 0.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: mint.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showTotal
                      ? Icons.account_balance_wallet_rounded
                      : Icons.sell_rounded,
                  size: 12,
                  color: mint,
                ),
                const SizedBox(width: 4),
                Text(
                  showTotal ? L.allUpcoming : L.thisVisit,
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: mint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            CountUp(
              Money.toSom(cost),
              formatter: Money.group,
              duration: const Duration(milliseconds: 650),
              style: GoogleFonts.nunito(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: mint,
                height: 1.0,
              ),
            ),
            Text(
              "so'm",
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: mint.withValues(alpha: 0.9),
                height: 1.15,
              ),
            ),
            if (canToggle) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      size: 11, color: mint.withValues(alpha: 0.85)),
                  const SizedBox(width: 3),
                  Text(
                    L.tapToSwitch,
                    style: GoogleFonts.nunito(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: mint.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
