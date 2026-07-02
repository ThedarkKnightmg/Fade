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
// Booking kit — the checklist rows, swatch pickers and the dark
// control panel shared by the detail screen and the booking flow.
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
                Text(service.name, style: AppTypography.h4(context)),
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
    this.dark = false,
  });

  final List<Barber> barbers;

  /// null means "any barber".
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final labelColor = dark ? p.panelTextDim : p.textSecondary;
    final activeLabel = dark ? p.panelText : p.text;

    Widget swatch({
      required Widget circle,
      required String label,
      required bool active,
      required VoidCallback onTap,
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
                      border: Border.all(
                        color: active
                            ? AppColors.accent
                            : (dark ? Colors.transparent : p.border),
                        width: active ? 2.4 : 1,
                      ),
                    ),
                    child: circle,
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
                          border: Border.all(
                            color: dark ? p.panel : p.card,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: AppColors.ink,
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
            label: 'Anyone',
            active: selectedId == null,
            onTap: () => onSelect(null),
          ),
        ],
      ),
    );
  }
}

/// Horizontal strip of day pills — lives inside the dark panel.
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
                color: active ? AppColors.accent : p.panelField,
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
                          ? AppColors.ink.withValues(alpha: 0.65)
                          : p.panelTextDim,
                    ),
                  ),
                  Text(
                    '${d.day}',
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: active ? AppColors.ink : p.panelText,
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

/// Wrap-grid of time chips for the dark panel. Booked slots are shown
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
            color: p.panelTextDim,
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
                      ? p.panelField.withValues(alpha: 0.4)
                      : (active ? AppColors.accent : p.panelField),
                  borderRadius: BorderRadius.circular(12),
                  border: isBooked
                      ? Border.all(
                          color: p.panelTextDim.withValues(alpha: 0.35))
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
                            ? p.panelTextDim
                            : (active ? AppColors.ink : p.panelText),
                        decoration:
                            isBooked ? TextDecoration.lineThrough : null,
                        decorationColor: p.panelTextDim,
                      ),
                    ),
                    if (isBooked) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.lock_rounded,
                          size: 11, color: p.panelTextDim),
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
              Icon(Icons.lock_rounded, size: 12, color: p.panelTextDim),
              const SizedBox(width: 5),
              Text(
                L.bookedLegend,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: p.panelTextDim,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The dark control panel — the booking cockpit.
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
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(28),
      ),
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
                    color: p.panelText,
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

/// Dropdown-look field inside the dark panel ("Nunito ▾" style).
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
          color: p.panelField,
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
                    color: p.panelText,
                  ),
                ),
              )
            else
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: p.panelText,
                ),
              ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: p.panelTextDim,
            ),
          ],
        ),
      ),
    );
    return field;
  }
}

/// Label above a panel section, dim and tiny.
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
          color: p.panelTextDim,
        ),
      ),
    );
  }
}
