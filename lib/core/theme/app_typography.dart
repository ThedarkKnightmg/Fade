import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// One family, one voice: Nunito everywhere.
class AppTypography {
  AppTypography._();

  static Color _ink(BuildContext context) => Paper.of(context).text;
  static Color _dim(BuildContext context) => Paper.of(context).textSecondary;

  // ===== Brand =====

  /// The wordmark — plain, heavy, tracked.
  static TextStyle logo(BuildContext context, {double size = 30}) =>
      GoogleFonts.nunito(
        fontSize: size * 0.74,
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: 2.4,
        color: _ink(context),
      );

  /// Quiet side notes (was the hand-written layer — now plain text).
  static TextStyle scribble(BuildContext context, {double size = 22}) =>
      GoogleFonts.nunito(
        fontSize: size * 0.62,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: _dim(context),
      );

  // ===== Display (Nunito, heavy) =====

  static TextStyle display(BuildContext context) => GoogleFonts.nunito(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        height: 1.12,
        letterSpacing: -0.5,
        color: _ink(context),
      );

  static TextStyle h1(BuildContext context) => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.15,
        letterSpacing: -0.4,
        color: _ink(context),
      );

  static TextStyle h2(BuildContext context) => GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.2,
        color: _ink(context),
      );

  static TextStyle h3(BuildContext context) => GoogleFonts.nunito(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: _ink(context),
      );

  static TextStyle h4(BuildContext context) => GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        height: 1.3,
        color: _ink(context),
      );

  // ===== Body (Nunito) =====

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: _ink(context),
      );

  static TextStyle body(BuildContext context) => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: _ink(context),
      );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.nunito(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: _dim(context),
      );

  /// Tiny tracked caps — "12 JUN FRIDAY".
  static TextStyle eyebrow(BuildContext context, {Color? color}) =>
      GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: 1.6,
        color: color ?? _dim(context),
      );

  static TextStyle caption(BuildContext context) => GoogleFonts.nunito(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: Paper.of(context).textTertiary,
      );

  static TextStyle button(BuildContext context, {Color? color}) =>
      GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: 0.1,
        color: color ?? Paper.of(context).onAction,
      );

  /// Prices — heavy, unmissable.
  static TextStyle price(BuildContext context) => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        height: 1.2,
        color: _ink(context),
      );
}
