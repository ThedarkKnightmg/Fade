import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(PaperPalette.light);
  static ThemeData get dark => _build(PaperPalette.dark);

  static ThemeData _build(PaperPalette p) {
    final base = p.isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: p.bg,
      primaryColor: p.text,
      colorScheme: (p.isDark ? const ColorScheme.dark() : const ColorScheme.light())
          .copyWith(
        primary: p.action,
        onPrimary: p.onAction,
        secondary: AppColors.accent,
        onSecondary: AppColors.ink,
        surface: p.card,
        onSurface: p.text,
        error: AppColors.red,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: p.text,
        displayColor: p.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: p.text),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: p.text,
        ),
        systemOverlayStyle:
            (p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(statusBarColor: Colors.transparent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.action,
          foregroundColor: p.onAction,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: p.text, width: 1.6),
        ),
        hintStyle: GoogleFonts.nunito(
          color: p.textTertiary,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: GoogleFonts.nunito(
          color: p.textSecondary,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.panel,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        contentTextStyle: GoogleFonts.nunito(
          color: p.panelText,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashColor: p.text.withValues(alpha: 0.05),
      highlightColor: p.text.withValues(alpha: 0.03),
    );
  }
}
