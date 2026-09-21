import '../../../core/map/map_attribution.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/format/thousands_formatter.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/map/fast_tiles.dart';
import '../../../core/photo/photo_source.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/service.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'barber_avatar.dart';
import 'barber_analytics_screen.dart';
import 'barber_history_screen.dart';
import 'shop_location_picker_screen.dart';
import 'wallet_screen.dart';
import 'boost_screen.dart';
import 'vip_explainer_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/support_sheet.dart';

/// The barber's own profile — Yandex-clean: a plain header (avatar · name ·
/// gear), white stat cards, the wallet bank-card as the ONE hero, then Boost
/// and share-QR as clean rows. All config (services, hours, shop, app
/// settings, role switch) lives one tap away in [BarberSettingsScreen].
class BarberProfileScreen extends StatelessWidget {
  const BarberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final me = s.meBarber;
          final done = s.barberHistory
              .where((b) => b.status == BookingStatus.completed)
              .length;
          final upcoming = s.barberAgenda.length;

          return SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
              children: [
                // ── Plain header: avatar · name + shop · gear (Yandex-clean,
                // no gradient hero — the wallet below is the ONE hero). ──
                FadeSlideIn(
                  child: Row(
                    children: [
                      const BarberAvatar(size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(me.barber.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.h2(context)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.store_mall_directory_rounded,
                                    size: 13, color: p.textTertiary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(me.shop.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTypography.bodySmall(context)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleBtn(
                        icon: Icons.settings_rounded,
                        size: 44,
                        onTap: () => Navigator.of(context).push(
                          FadeThroughPageRoute(
                              child: const BarberSettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Live stats: clean white cards, tinted icon chips. ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Row(
                    children: [
                      _ColorStat(
                          label: L.completedWord,
                          value: '$done',
                          icon: Icons.check_circle_rounded,
                          tint: AppColors.green),
                      const SizedBox(width: 10),
                      _ColorStat(
                          label: L.upcomingWord,
                          value: '$upcoming',
                          icon: Icons.calendar_month_rounded,
                          tint: AppColors.accent),
                      const SizedBox(width: 10),
                      _ColorStat(
                          label: L.today,
                          value: Money.compact(s.barberEarningsToday),
                          icon: Icons.payments_rounded,
                          tint: AppColors.gold),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Wallet bank-card — the single gradient hero. ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: const _WalletTile(),
                ),
                const SizedBox(height: 12),

                // ── Grow: two separate products — Boost (pay-per-hour) and
                //    VIP (subscription) — each its own sell card. ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 130),
                  child: const _BoostSellCard(),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 155),
                  child: const _VipSellCard(),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 170),
                  child: const _GrowBookingsCard(),
                ),
                const SizedBox(height: 12),

                // ── The client book: every person who's used your service. ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _NavTile(
                    icon: Icons.group_rounded,
                    title: L.clientsWord,
                    subtitle: L.cutHistory,
                    onTap: () => Navigator.of(context).push(
                      FadeThroughPageRoute(
                          child: const BarberHistoryScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Analytics: which services earn the most (a VIP perk). ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: _NavTile(
                    icon: Icons.insights_rounded,
                    title: L.navAnalytics,
                    subtitle: L.analyticsSub,
                    onTap: () => Navigator.of(context).push(
                      FadeThroughPageRoute(
                          child: const BarberAnalyticsScreen()),
                    ),
                  ),
                ),

                // ── Leader: roster join requests (owner only) ──
                if (s.isShopOwner) ...[
                  const SizedBox(height: 20),
                  _RosterRequestsCard(requests: s.rosterRequestsForMyShop()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Barber Settings — the config that used to clutter the profile now lives
//  here: services, working hours, the shop, app & account, and role switch.
// ═════════════════════════════════════════════════════════════════════════

/// Everything the barber configures, one tap behind the profile's gear. Reuses
/// the same service / hours / shop editors the profile used to inline.
class BarberSettingsScreen extends StatelessWidget {
  const BarberSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final services = s.barberServices;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 48),
              children: [
                // Header.
                Row(
                  children: [
                    CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      size: 44,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 14),
                    Text(L.settingsTitle, style: AppTypography.h2(context)),
                  ],
                ),
                const SizedBox(height: 22),

                // ── Services (re-price, switch off, add, remove) ──
                Text(L.yourServices, style: AppTypography.h3(context)),
                const SizedBox(height: 2),
                Text(L.servicesHint, style: AppTypography.bodySmall(context)),
                const SizedBox(height: 12),
                for (final svc in services) ...[
                  _ServiceRow(service: svc),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 4),
                _AddServiceButton(onTap: () => _openEditor(context, null)),
                const SizedBox(height: 26),

                // ── Working hours ──
                FadeSlideIn(
                  child: _WorkingHoursCard(
                      start: s.workStartHour, end: s.workEndHour),
                ),
                const SizedBox(height: 22),

                // ── My shop: map, photos, description ──
                _MyShopCard(
                  lat: s.shopLat,
                  lng: s.shopLng,
                  address: s.shopAddress,
                  photos: s.shopPhotos,
                  description: s.shopDescription,
                  editable: s.isShopOwner,
                ),
                const SizedBox(height: 26),

                // ── App & account (shared client settings screen) ──
                _NavTile(
                  icon: Icons.manage_accounts_rounded,
                  title: L.appAndAccount,
                  subtitle: L.appAndAccountSub,
                  onTap: () => Navigator.of(context).push(
                    FadeThroughPageRoute(child: const SettingsScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Help & feedback: bug reports, ideas, anything wrong ──
                _NavTile(
                  icon: Icons.support_agent_rounded,
                  title: L.helpFeedback,
                  subtitle: L.helpFeedbackSub,
                  onTap: () => showSupportSheet(context),
                ),
                const SizedBox(height: 12),

                // ── Switch to client mode ──
                _NavTile(
                  icon: Icons.swap_horiz_rounded,
                  tint: AppColors.green,
                  title: L.switchToClient,
                  subtitle: L.switchClientBody,
                  onTap: () {
                    Navigator.of(context).maybePop();
                    AppState.instance.setRole(AppRole.client);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A tappable settings/nav row: tinted icon tile, title + subtitle, chevron.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.tint = AppColors.accent,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: PaperCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h4(context)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!, style: AppTypography.bodySmall(context)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// BOOST — the pay-per-hour product, on its own blue sell card. Shows live Ups
/// balance and a Live pill when a boost is running; taps into the Boost screen.
class _BoostSellCard extends StatelessWidget {
  const _BoostSellCard();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final s = AppState.instance;
    final boosted = s.barberBoosted;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context)
            .push(FadeThroughPageRoute(child: const BoostScreen()));
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: clayDecoration(p, radius: 20),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.bolt_rounded,
                  size: 24, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(L.tabBoost,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h4(context)),
                      ),
                      if (boosted) ...[
                        const SizedBox(width: 6),
                        _AccentPill(label: L.boostedNowChip),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(L.boostTabSub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(context)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Live Ups balance chip.
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 3),
                  Text('${s.boosts}',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// VIP — the subscription product, on its own gold sell card. Shows the monthly
/// price (or Active status) and taps into the VIP screen.
class _VipSellCard extends StatelessWidget {
  const _VipSellCard();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final s = AppState.instance;
    final vip = s.barberVip;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context)
            .push(FadeThroughPageRoute(child: const VipExplainerScreen()));
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: clayDecoration(p, radius: 20),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  size: 24, color: AppColors.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(L.tierVipTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h4(context)),
                      ),
                      if (vip) ...[
                        const SizedBox(width: 6),
                        const _GoldPill(label: 'VIP'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(L.vipTabSub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(context)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Monthly price chip (or Active).
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                vip
                    ? L.vipActiveChip
                    : "${Money.group(AppState.vipMonthlySom)} so'm",
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF8A6100),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// A small accent (blue) status pill on the boost row (Live).
class _AccentPill extends StatelessWidget {
  const _AccentPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: AppColors.accent,
          )),
    );
  }
}

/// A small gold status pill on the boost row (VIP / Live).
class _GoldPill extends StatelessWidget {
  const _GoldPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: const Color(0xFF8A6100),
          )),
    );
  }
}

/// "Grow your bookings" — surfaces the white-label link/QR (the anti-leakage
/// hook). Taps into the wallet, where the full scannable QR lives.
class _GrowBookingsCard extends StatelessWidget {
  const _GrowBookingsCard();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final s = AppState.instance;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context)
            .push(FadeThroughPageRoute(child: const WalletScreen()));
      },
      behavior: HitTestBehavior.opaque,
      child: PaperCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.qr_code_2_rounded,
                  size: 24, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.growBookingsTitle, style: AppTypography.h4(context)),
                  const SizedBox(height: 2),
                  Text(L.growBookingsSub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(context)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.link_rounded,
                          size: 13, color: p.textTertiary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(s.barberLink,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// One menu row: icon + name + price/time, with an on/off switch. Tapping the
/// body opens the editor; the switch toggles availability in place.
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});
  final BarberService service;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final svc = service;
    final off = !svc.enabled;
    final nameColor = off ? p.textTertiary : p.text;
    return Opacity(
      opacity: off ? 0.7 : 1,
      child: PaperCard(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openEditor(context, svc),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(svc.icon,
                          size: 20,
                          color: off ? p.textTertiary : AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              L.tr(svc.name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.h4(context).copyWith(
                                color: nameColor,
                                decoration:
                                    off ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              off
                                  ? L.offWord
                                  : '${svc.formattedDuration} · ${svc.formattedPrice}',
                              style: AppTypography.bodySmall(context),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_rounded,
                          size: 15, color: p.textTertiary),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ),
            Switch.adaptive(
              value: svc.enabled,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.accent,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                AppState.instance.toggleService(svc.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddServiceButton extends StatelessWidget {
  const _AddServiceButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 19, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(L.addServiceWord,
                style: GoogleFonts.nunito(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

void _openEditor(BuildContext context, BarberService? service) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ServiceEditorSheet(service: service),
  );
}

/// Add / edit a service — name, price, duration, plus delete on existing ones.
class _ServiceEditorSheet extends StatefulWidget {
  const _ServiceEditorSheet({this.service});
  final BarberService? service;

  @override
  State<_ServiceEditorSheet> createState() => _ServiceEditorSheetState();
}

class _ServiceEditorSheetState extends State<_ServiceEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _duration;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _name = TextEditingController(text: s?.name ?? '');
    // Show & edit the price directly in so'm (the model stores it internally).
    _price = TextEditingController(
        text: s == null ? '' : ThousandsInputFormatter.groupInt(Money.toSom(s.price)));
    _duration = TextEditingController(
        text: s == null ? '' : s.durationMinutes.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    // The field is in so'm — convert to the model's internal unit on save.
    final som = double.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final price = som / Money.usdToUzs;
    final duration = int.tryParse(_duration.text.trim()) ?? 0;
    if (name.isEmpty || duration <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(L.serviceNameLabel)));
      return;
    }
    final s = AppState.instance;
    if (_isEditing) {
      s.updateService(widget.service!.id,
          name: name, price: price, durationMinutes: duration);
    } else {
      s.addService(name: name, price: price, durationMinutes: duration);
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).maybePop();
  }

  void _remove() {
    final s = widget.service;
    if (s == null) return;
    AppState.instance.removeService(s.id);
    HapticFeedback.mediumImpact();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
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
            Text(_isEditing ? L.editServiceWord : L.addServiceWord,
                style: AppTypography.h2(context)),
            const SizedBox(height: 16),
            _SheetField(
              controller: _name,
              label: L.serviceNameLabel,
              icon: Icons.content_cut_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SheetField(
                    controller: _price,
                    label: L.priceSomLabel,
                    icon: Icons.payments_outlined,
                    keyboard: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetField(
                    controller: _duration,
                    label: L.durationMinLabel,
                    icon: Icons.schedule_rounded,
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: L.save,
              icon: Icons.check_rounded,
              height: 54,
              onPressed: _save,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _remove,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.red),
                      const SizedBox(width: 6),
                      Text(L.removeWord,
                          style: GoogleFonts.nunito(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.red)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: p.text),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19, color: p.textTertiary),
        filled: true,
        fillColor: p.card,
        labelStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w600, color: p.textSecondary),
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(AppColors.accent, 1.5),
      ),
    );
  }
}

/// A stat tile — clean white card with a tinted icon chip (green/blue/gold).
class _ColorStat extends StatelessWidget {
  const _ColorStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: clayDecoration(p, radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: tint),
            ),
            const SizedBox(height: 9),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  maxLines: 1,
                  style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: p.text)),
            ),
            const SizedBox(height: 1),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(context)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Working hours
// ─────────────────────────────────────────────────────────────────────────

String _hh(int h) => '${h.toString().padLeft(2, '0')}:00';

class _WorkingHoursCard extends StatelessWidget {
  const _WorkingHoursCard({required this.start, required this.end});
  final int start;
  final int end;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _HoursSheet(start: start, end: end),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: PaperCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.schedule_rounded,
                  size: 22, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.workingHoursTitle, style: AppTypography.h4(context)),
                  const SizedBox(height: 1),
                  Text('${_hh(start)} – ${_hh(end)}',
                      style: AppTypography.bodySmall(context)),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, size: 17, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _HoursSheet extends StatefulWidget {
  const _HoursSheet({required this.start, required this.end});
  final int start;
  final int end;

  @override
  State<_HoursSheet> createState() => _HoursSheetState();
}

class _HoursSheetState extends State<_HoursSheet> {
  late int _start = widget.start;
  late int _end = widget.end;

  void _save() {
    AppState.instance.setWorkingHours(_start, _end);
    HapticFeedback.mediumImpact();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
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
          Text(L.workingHoursTitle, style: AppTypography.h2(context)),
          const SizedBox(height: 16),
          _StepRow(
            label: L.opensLabel,
            value: _hh(_start),
            onMinus: _start > 5
                ? () => setState(() => _start--)
                : null,
            onPlus: _start < _end - 1
                ? () => setState(() => _start++)
                : null,
          ),
          const SizedBox(height: 10),
          _StepRow(
            label: L.closesLabel,
            value: _hh(_end),
            onMinus: _end > _start + 1
                ? () => setState(() => _end--)
                : null,
            onPlus: _end < 24 ? () => setState(() => _end++) : null,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
              label: L.save,
              icon: Icons.check_rounded,
              height: 54,
              onPressed: _save),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });
  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    Widget btn(IconData icon, VoidCallback? on) => GestureDetector(
          onTap: on == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  on();
                },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: on == null ? p.cardAlt : AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                size: 20,
                color: on == null ? p.textTertiary : AppColors.accent),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Text(label, style: AppTypography.body(context)),
          const Spacer(),
          btn(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 70,
            child: Text(value,
                textAlign: TextAlign.center,
                style: AppTypography.h3(context)),
          ),
          btn(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }
}

/// A compact wallet balance tile on the barber profile → taps into the full
/// wallet screen. Shows the "vending machine" balance at a glance.
/// A premium "bank-card" style wallet surface: a blue gradient card with a
/// drifting sheen, a skeuomorphic chip, the balance, and live boosts/VIP.
class _WalletTile extends StatelessWidget {
  const _WalletTile();

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(FadeThroughPageRoute(child: const WalletScreen())),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF3D9BFF), Color(0xFF1E5FCC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.32),
                blurRadius: 22,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Breathe(
                  builder: (context, t) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.9 + 1.8 * t, -0.8),
                        radius: 1.0,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(L.walletWord,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Colors.white.withValues(alpha: 0.85),
                            )),
                        const Spacer(),
                        // Skeuomorphic card chip.
                        Container(
                          width: 34,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3D98A), Color(0xFFD9A94A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "${Money.group(s.walletSom)} so'm",
                      style: GoogleFonts.nunito(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                              color: Color(0x55001B4D),
                              offset: Offset(0, 1.5),
                              blurRadius: 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _CardChip(
                          icon: Icons.bolt_rounded,
                          label: L.upsUnit(s.boosts),
                        ),
                        if (s.barberVip) ...[
                          const SizedBox(width: 8),
                          _CardChip(
                            icon: Icons.workspace_premium_rounded,
                            label: 'VIP',
                            gold: true,
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              s.walletLow ? L.walletLowWarn : L.walletTitle,
                              style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              s.walletLow
                                  ? Icons.warning_amber_rounded
                                  : Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ],
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

/// A frosted chip inside the wallet card (boosts / VIP).
class _CardChip extends StatelessWidget {
  const _CardChip({required this.icon, required this.label, this.gold = false});
  final IconData icon;
  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final c = gold ? AppColors.gold : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: c,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Leader: roster join requests (Flow B, screen 4)
// ─────────────────────────────────────────────────────────────────────────

/// The Leader's approve/deny panel: barbers asking to join the shop's roster,
/// most urgent (closest to the 72h auto-pass) first. Renders nothing when the
/// queue is empty.
class _RosterRequestsCard extends StatelessWidget {
  const _RosterRequestsCard({required this.requests});
  final List<JoinRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const SizedBox.shrink();
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FadeSlideIn(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: clayDecoration(p, radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.group_add_rounded,
                      size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(L.rosterRequests, style: AppTypography.h3(context)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('${requests.length}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(L.rosterRequestsSub,
                  style: AppTypography.bodySmall(context)),
              const SizedBox(height: 14),
              for (var i = 0; i < requests.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: p.border),
                  const SizedBox(height: 12),
                ],
                _RosterRequestRow(request: requests[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RosterRequestRow extends StatelessWidget {
  const _RosterRequestRow({required this.request});
  final JoinRequest request;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final r = request;
    final hoursLeft = r.timeLeft.inHours.clamp(0, 72);
    final urgent = hoursLeft <= 24;

    void act(bool accept) {
      HapticFeedback.mediumImpact();
      final s = AppState.instance;
      if (accept) {
        s.approveJoinRequest(r.id);
      } else {
        s.denyJoinRequest(r.id);
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
              accept ? L.barberAdded(r.barberName) : L.barberDenied(r.barberName)),
          behavior: SnackBarBehavior.floating,
        ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InitialAvatar(name: r.barberName, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.barberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h4(context)),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: AppColors.gold),
                      const SizedBox(width: 2),
                      Text(r.rating.toStringAsFixed(1),
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: p.textSecondary,
                          )),
                      const SizedBox(width: 8),
                      Icon(Icons.photo_library_rounded,
                          size: 12, color: p.textTertiary),
                      const SizedBox(width: 2),
                      Text('${r.portfolioCount}',
                          style: AppTypography.caption(context)),
                    ],
                  ),
                ],
              ),
            ),
            // Auto-pass countdown — the Dead-Leader fail-safe, made visible.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: (urgent ? AppColors.gold : p.textTertiary)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timelapse_rounded,
                      size: 12,
                      color: urgent ? AppColors.gold : p.textTertiary),
                  const SizedBox(width: 3),
                  Text(L.autoPassesIn(hoursLeft),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: urgent
                            ? const Color(0xFF8A6100)
                            : p.textSecondary,
                      )),
                ],
              ),
            ),
          ],
        ),
        if (r.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(r.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(context)),
        ],
        if (r.priceNote.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.sell_rounded, size: 12, color: p.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(r.priceNote,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(context)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniAction(
                label: L.denyWord,
                icon: Icons.close_rounded,
                filled: false,
                onTap: () => act(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _MiniAction(
                label: L.acceptWord,
                icon: Icons.check_rounded,
                filled: true,
                onTap: () => act(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A compact pill action (accept/deny) used in the roster row.
class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: filled ? null : Border.all(color: p.border, width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 17, color: filled ? Colors.white : p.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: filled ? Colors.white : p.text,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  My shop: location map + photos + description
// ─────────────────────────────────────────────────────────────────────────

class _MyShopCard extends StatelessWidget {
  const _MyShopCard({
    required this.lat,
    required this.lng,
    required this.address,
    required this.photos,
    required this.description,
    required this.editable,
  });
  final double lat;
  final double lng;
  final String address;
  final List<Uint8List> photos;
  final String description;

  /// Owners can edit the shop's location/photos/description; staff see it
  /// read-only.
  final bool editable;

  Future<void> _addPhoto() async {
    final bytes = await capturePhoto();
    if (bytes != null) AppState.instance.addShopPhoto(bytes);
  }

  void _editDescription(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DescSheet(current: description),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L.myShopTitle, style: AppTypography.h3(context)),
        if (!editable) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 14, color: Paper.of(context).textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(L.managedByOwner,
                    style: AppTypography.caption(context)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        // Location map preview.
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 140,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 14.5,
                    interactionOptions:
                        const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: cartoTileUrl(dark: p.isDark, plain: true),
                      subdomains: const ['a', 'b', 'c', 'd'],
                      tileProvider: CachedTileProvider(),
                      userAgentPackageName: 'com.barber.app',
                    ),
                    const MapAttribution(),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_on_rounded,
                              color: AppColors.accent, size: 34),
                        ),
                      ],
                    ),
                  ],
                ),
                // Address chip.
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.card.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place_rounded,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption(context)),
                        ),
                      ],
                    ),
                  ),
                ),
                // "Change" pill (owner only).
                if (editable)
                  Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_location_alt_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(L.changeWord,
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                // Tap anywhere on the preview to re-pin the shop (owner only).
                if (editable)
                  Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        FadeThroughPageRoute(
                          child: ShopLocationPickerScreen(
                              initial: LatLng(lat, lng)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Photos.
        Row(
          children: [
            Text(L.shopPhotosTitle, style: AppTypography.h4(context)),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 10),
        if (editable || photos.isNotEmpty)
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < photos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _PhotoThumb(
                      bytes: photos[i],
                      onRemove: editable
                          ? () => AppState.instance.removeShopPhotoAt(i)
                          : null,
                    ),
                  ),
                if (editable) _AddPhotoTile(onTap: _addPhoto),
              ],
            ),
          )
        else
          Text(L.noPhotosYet, style: AppTypography.bodySmall(context)),
        const SizedBox(height: 16),
        // Description.
        Text(L.descriptionLabel, style: AppTypography.h4(context)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: editable ? () => _editDescription(context) : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    description.isEmpty
                        ? (editable ? L.addDescriptionHint : L.noDescriptionYet)
                        : description,
                    style: AppTypography.bodySmall(context).copyWith(
                        color: description.isEmpty ? p.textTertiary : p.text),
                  ),
                ),
                if (editable) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.edit_rounded, size: 16, color: p.textTertiary),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.bytes, this.onRemove});
  final Uint8List bytes;

  /// Null for staff (read-only) — the remove button is hidden.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(bytes, width: 88, height: 88, fit: BoxFit.cover),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onRemove!();
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_rounded,
                size: 22, color: AppColors.accent),
            const SizedBox(height: 4),
            Text(L.addPhotosWord,
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

class _DescSheet extends StatefulWidget {
  const _DescSheet({required this.current});
  final String current;

  @override
  State<_DescSheet> createState() => _DescSheetState();
}

class _DescSheetState extends State<_DescSheet> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.current);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    AppState.instance.setShopDescription(_ctrl.text);
    HapticFeedback.mediumImpact();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
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
            Text(L.descriptionLabel, style: AppTypography.h2(context)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              maxLength: 240,
              style:
                  GoogleFonts.nunito(fontWeight: FontWeight.w600, color: p.text),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: L.addDescriptionHint,
                filled: true,
                fillColor: p.card,
                hintStyle: GoogleFonts.nunito(color: p.textTertiary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: p.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: p.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
                label: L.save,
                icon: Icons.check_rounded,
                height: 54,
                onPressed: _save),
          ],
        ),
      ),
    );
  }
}
