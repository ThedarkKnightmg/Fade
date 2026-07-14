import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/barber.dart';
import '../../data/models/service.dart';
import 'paper_kit.dart';

// ============================================================
// Booking kit — the checklist rows, swatch pickers and the light
// booking cockpit shared by the detail screen and the booking flow.
// One clean card language (Yandex-style), same as the rest of the app.
// ============================================================

/// A service as a checklist row — circle check in ballpoint blue.
class ServiceCheckRow extends StatelessWidget {
  const ServiceCheckRow({
    super.key,
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final BarberService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return PaperCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      borderColor: selected ? Color.lerp(p.border, AppColors.blue, 0.35) : null,
      child: Row(
        children: [
          RoundCheck(value: selected, onChanged: (_) => onTap()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.tr(service.name), style: AppTypography.h4(context)),
                const SizedBox(height: 1),
                Text(
                  service.formattedDuration,
                  style: AppTypography.bodySmall(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(service.formattedPrice, style: AppTypography.price(context)),
        ],
      ),
    );
  }
}

/// Barbers as a swatch row — crayon circles with a check on the
/// selected one, plus a rainbow "any barber" swatch at the end.
class BarberSwatchRow extends StatelessWidget {
  const BarberSwatchRow({
    super.key,
    required this.barbers,
    required this.selectedId,
    required this.onSelect,
    this.tierOf,
    this.dark = false,
  });

  final List<Barber> barbers;

  /// Spotlight tier per barber (0 boosted · 1 VIP · 2 standard) — boosted
  /// stylists get a gold ring + bolt, VIP a gold border. Null = no tiers.
  final int Function(Barber)? tierOf;

  /// null means "any barber".
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // One light language everywhere now — the [dark] flag is kept for API
    // compatibility but no longer switches palettes.
    final labelColor = p.textSecondary;
    final activeLabel = p.text;

    Widget swatch({
      required Widget circle,
      required String label,
      required bool active,
      required VoidCallback onTap,
      int tier = 2,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Spotlight ring: boosted = solid gold, VIP = soft gold.
                      border: Border.all(
                        color: active
                            ? AppColors.accent
                            : tier == 0
                                ? AppColors.gold
                                : tier == 1
                                    ? AppColors.gold.withValues(alpha: 0.55)
                                    : p.border,
                        width: active ? 2.4 : (tier <= 1 ? 2 : 1),
                      ),
                    ),
                    child: circle,
                  ),
                  if (tier == 0 && !active)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.card, width: 2),
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            size: 11, color: Colors.white),
                      ),
                    ),
                  if (active)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.card, width: 2),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active ? activeLabel : labelColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < barbers.length; i++)
            swatch(
              circle: InitialAvatar(
                name: barbers[i].name,
                size: 50,
                index: i,
              ),
              label: barbers[i].name.split(' ').first,
              active: selectedId == barbers[i].id,
              tier: tierOf?.call(barbers[i]) ?? 2,
              onTap: () => onSelect(barbers[i].id),
            ),
          // The "whoever's free" swatch — plain blue.
          swatch(
            circle: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentDeep,
              ),
              child: const Icon(
                Icons.shuffle_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            label: L.wdAnyone,
            active: selectedId == null,
            onTap: () => onSelect(null),
          ),
        ],
      ),
    );
  }
}

/// Horizontal strip of day pills — Yandex-style segmented chips.
class DatePillRow extends StatelessWidget {
  const DatePillRow({
    super.key,
    required this.dates,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<DateTime> dates;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(dates.length, (i) {
          final d = dates[i];
          final active = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : p.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('EEE').format(d).toUpperCase(),
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: active
                          ? Colors.white.withValues(alpha: 0.8)
                          : p.textTertiary,
                    ),
                  ),
                  Text(
                    '${d.day}',
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: active ? Colors.white : p.text,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Wrap-grid of time chips. Booked slots are shown
/// (greyed + struck through + a lock) so the user can see what's taken.
class TimeGrid extends StatelessWidget {
  const TimeGrid({
    super.key,
    required this.slots,
    required this.selected,
    required this.onSelect,
    this.booked = const {},
  });

  final List<DateTime> slots;
  final Set<DateTime> booked;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          L.allChairsTaken,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: p.textTertiary,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((t) {
            final isBooked = booked.contains(t);
            final active = selected == t && !isBooked;
            return GestureDetector(
              onTap: isBooked ? null : () => onSelect(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isBooked
                      ? p.cardAlt.withValues(alpha: 0.6)
                      : (active ? AppColors.accent : p.cardAlt),
                  borderRadius: BorderRadius.circular(12),
                  border: isBooked
                      ? Border.all(
                          color: p.textTertiary.withValues(alpha: 0.30))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(t),
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isBooked
                            ? p.textTertiary
                            : (active ? Colors.white : p.text),
                        decoration:
                            isBooked ? TextDecoration.lineThrough : null,
                        decorationColor: p.textTertiary,
                      ),
                    ),
                    if (isBooked) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.lock_rounded,
                          size: 11, color: p.textTertiary),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (booked.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.lock_rounded, size: 12, color: p.textTertiary),
              const SizedBox(width: 5),
              Text(
                L.bookedLegend,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: p.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The booking cockpit — now a clean light section card like every other
/// surface in the app (title row + content on white).
class InkPanel extends StatelessWidget {
  const InkPanel({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: clayDecoration(p, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// Dropdown-look field inside the cockpit ("Nunito ▾" style).
class PanelField extends StatelessWidget {
  const PanelField({
    super.key,
    required this.value,
    this.onTap,
    this.expanded = true,
  });

  final String value;
  final VoidCallback? onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final field = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.cardAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expanded)
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
              )
            else
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: p.textTertiary,
            ),
          ],
        ),
      ),
    );
    return field;
  }
}

/// Label above a cockpit section, dim and tiny.
class PanelLabel extends StatelessWidget {
  const PanelLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: p.textTertiary,
        ),
      ),
    );
  }
}
