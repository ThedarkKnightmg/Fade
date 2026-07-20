import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/app_state.dart';
import '../../data/models/booking.dart';
import 'dual_rating_row.dart';
import 'primary_button.dart';

/// "How was your visit?" — the review prompt shown after a completed booking.
/// Unlike the shop-page review sheet, this is keyed on the actual [booking], so
/// it rates the exact barber the client saw AND marks that visit reviewed (via
/// AppState.reviewVisit) so the nudge stops.
Future<void> showReviewVisitSheet(BuildContext context, Booking booking) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReviewVisitSheet(booking: booking),
  );
}

class _ReviewVisitSheet extends StatefulWidget {
  const _ReviewVisitSheet({required this.booking});
  final Booking booking;

  @override
  State<_ReviewVisitSheet> createState() => _ReviewVisitSheetState();
}

class _ReviewVisitSheetState extends State<_ReviewVisitSheet> {
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
    AppState.instance.reviewVisit(
      widget.booking,
      barberStars: _barberStars.toDouble(),
      barberText: _barberText.text,
      shopStars: _shopStars.toDouble(),
      shopText: _shopText.text,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(L.reviewThanks)));
  }

  Widget _field(PaperPalette p, TextEditingController c, String hint) =>
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
    final b = widget.booking;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        // Scrollable so the keyboard can't overflow it.
        child: SingleChildScrollView(
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
              Text(L.howWasVisit, style: AppTypography.h2(context)),
              const SizedBox(height: 2),
              Text('${b.barber.name} · ${b.barbershop.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(context)),
              const SizedBox(height: 16),
              Text('${L.rateYourBarber} · ${b.barber.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h4(context)),
              const SizedBox(height: 8),
              StarInput(
                value: _barberStars,
                color: AppColors.gold,
                onChanged: (v) => setState(() => _barberStars = v),
              ),
              const SizedBox(height: 10),
              _field(p, _barberText, L.barberReviewHint),
              const SizedBox(height: 18),
              Text(L.rateTheShop, style: AppTypography.h4(context)),
              const SizedBox(height: 8),
              StarInput(
                value: _shopStars,
                color: AppColors.accent,
                onChanged: (v) => setState(() => _shopStars = v),
              ),
              const SizedBox(height: 10),
              _field(p, _shopText, L.shopReviewHint),
              const SizedBox(height: 16),
              PrimaryButton(label: L.postReview, height: 56, onPressed: _post),
            ],
          ),
        ),
      ),
    );
  }
}
