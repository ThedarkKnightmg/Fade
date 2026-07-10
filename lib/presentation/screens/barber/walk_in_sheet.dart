import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/service.dart';
import '../../widgets/primary_button.dart';

/// Log an offline walk-in on the barber's calendar — free forever (0
/// commission). It locks the slot so online clients can't double-book it.
Future<void> showWalkInSheet(BuildContext context, {DateTime? day}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WalkInSheet(day: day ?? DateTime.now()),
  );
}

class _WalkInSheet extends StatefulWidget {
  const _WalkInSheet({required this.day});
  final DateTime day;

  @override
  State<_WalkInSheet> createState() => _WalkInSheetState();
}

class _WalkInSheetState extends State<_WalkInSheet> {
  final _name = TextEditingController();
  late TimeOfDay _time;
  BarberService? _service;

  @override
  void initState() {
    super.initState();
    // Default to the next half-hour so it snaps to the booking grid.
    final now = DateTime.now();
    final roundUp = now.minute >= 30;
    var h = roundUp ? now.hour + 1 : now.hour;
    // Rounding up late in the evening must not wrap past midnight — that would
    // land the walk-in at 00:00 of *today* (~24h in the past, off the grid).
    // Clamp to the last valid slot on the same day instead.
    if (h >= 24) {
      _time = const TimeOfDay(hour: 23, minute: 30);
    } else {
      _time = TimeOfDay(hour: h, minute: roundUp ? 0 : 30);
    }
    final svcs = AppState.instance.barberServices;
    if (svcs.isNotEmpty) _service = svcs.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) {
      // Snap to :00/:30 so it aligns with the client booking grid.
      setState(() =>
          _time = TimeOfDay(hour: t.hour, minute: t.minute >= 30 ? 30 : 0));
    }
  }

  void _save() {
    final svc = _service;
    if (svc == null) return;
    final d = widget.day;
    final when = DateTime(d.year, d.month, d.day, _time.hour, _time.minute);
    final ok = AppState.instance
        .addWalkIn(dateTime: when, name: _name.text, service: svc);
    final messenger = ScaffoldMessenger.of(context);
    if (!ok) {
      HapticFeedback.heavyImpact();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(L.slotTakenWarn),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(L.walkInAdded),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final svcs = AppState.instance.barberServices;
    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(22, 12, 22,
          16 + MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                  child:
                      Text(L.logWalkInTitle, style: AppTypography.h2(context))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(L.walkInFreeTag,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.green,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(L.logWalkInSub, style: AppTypography.bodySmall(context)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            style:
                GoogleFonts.nunito(fontWeight: FontWeight.w700, color: p.text),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              labelText: L.walkInNameLabel,
              prefixIcon:
                  Icon(Icons.person_outline_rounded, color: p.textTertiary),
              filled: true,
              fillColor: p.card,
              labelStyle: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600, color: p.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: p.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: p.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Time row.
          GestureDetector(
            onTap: _pickTime,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 20, color: p.textTertiary),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(L.startWord,
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: p.textSecondary))),
                  Text(_time.format(context),
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(L.serviceWord, style: AppTypography.h4(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final svc in svcs)
                _ServiceChip(
                  label: svc.name,
                  selected: _service?.id == svc.id,
                  onTap: () => setState(() => _service = svc),
                ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: L.logWalkInTitle,
            icon: Icons.person_add_alt_1_rounded,
            style: PrimaryButtonStyle.lime,
            onPressed: _service == null ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.12) : p.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : p.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.accent : p.textSecondary,
            )),
      ),
    );
  }
}
