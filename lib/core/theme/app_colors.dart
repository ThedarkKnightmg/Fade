import 'package:flutter/material.dart';

/// "Homies" dark-navy palette.
/// Deep navy canvas, layered navy cards, one bright electric-blue accent.
class AppColors {
  AppColors._();

  // === Accents (same in light & dark) ===

  /// Electric blue — primary buttons, the AI button, highlights.
  static const Color accent = Color(0xFF2E8BFF);
  static const Color accentDeep = Color(0xFF1E6FE0);

  /// Deep blue fill for soft chips/icon tiles on the dark canvas.
  static const Color accentSoft = Color(0xFF16294B);

  /// Checkbox / focus blue (same family).
  static const Color blue = Color(0xFF2E8BFF);

  /// Red ink — destructive actions only.
  static const Color red = Color(0xFFFF5A5A);

  /// Premium gold — for paid/sponsored barbershop cards.
  static const Color gold = Color(0xFFE7B33C);
  static const Color goldSoft = Color(0xFF3A3018);

  /// Money / positive — fresh mint green. `greenLight` is tuned to pop on
  /// the electric-blue bookings card; `greenSoft` is a dim fill.
  static const Color green = Color(0xFF2BD888);
  static const Color greenLight = Color(0xFF8FF3C6);
  static const Color greenSoft = Color(0xFF123A2E);

  /// Kept for any legacy references — maps onto the dark ink.
  static const Color ink = Color(0xFF0B1422);

  // === Dark navy (the default look) ===
  static const Color navy = Color(0xFF0B1422); // page background
  static const Color navyDeep = Color(0xFF070D17); // gradient bottom
  static const Color card = Color(0xFF141E30); // primary card
  static const Color cardAlt = Color(0xFF1B2740); // raised / inner card
  static const Color border = Color(0xFF26334D);
  static const Color divider = Color(0xFF1E2A40);
  static const Color textPrimary = Color(0xFFEEF3FB);
  static const Color textSecondary = Color(0xFF9AA7BD);
  static const Color textTertiary = Color(0xFF61708A);

  // === A lighter navy variant (the "light" theme is still dark-ish) ===
  static const Color navyLite = Color(0xFF101B2C);
  static const Color cardLite = Color(0xFF172236);
}

/// Theme-resolved tokens. `final p = Paper.of(context);`
class PaperPalette {
  const PaperPalette({
    required this.bg,
    required this.bgGradientTop,
    required this.bgGradientBottom,
    required this.card,
    required this.cardAlt,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.action,
    required this.onAction,
    required this.panel,
    required this.panelField,
    required this.panelText,
    required this.panelTextDim,
    required this.shadow,
    required this.clayLight,
    required this.tint,
    required this.isDark,
  });

  final Color bg;
  final Color bgGradientTop;
  final Color bgGradientBottom;
  final Color card;
  final Color cardAlt;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color divider;

  /// Big pill buttons — electric blue with white text.
  final Color action;
  final Color onAction;

  /// The "panel" tokens used by the booking cockpit — a darker raised navy.
  final Color panel;
  final Color panelField;
  final Color panelText;
  final Color panelTextDim;

  /// The soft ambient clay shadow (cast below/around a puffy surface).
  final Color shadow;

  /// The top-left highlight that gives clay its inflated, lit-from-above look.
  final Color clayLight;

  /// Soft accent-tinted fill for icon tiles, badges and selected chips. Light
  /// blue on the light theme, deep blue on navy: the old shared deep-blue
  /// constant read as a heavy dark square on light screens.
  final Color tint;

  final bool isDark;

  static const PaperPalette dark = PaperPalette(
    bg: AppColors.navy,
    bgGradientTop: Color(0xFF0E1A2E),
    bgGradientBottom: Color(0xFF070D17),
    card: AppColors.card,
    cardAlt: AppColors.cardAlt,
    text: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    border: AppColors.border,
    divider: AppColors.divider,
    action: AppColors.accent,
    onAction: Colors.white,
    panel: Color(0xFF0F1828),
    panelField: Color(0xFF1B2740),
    panelText: Color(0xFFEEF3FB),
    panelTextDim: Color(0x8CB7C3D6),
    shadow: Color(0x73020610),
    clayLight: Color(0x14A9C6FF),
    tint: AppColors.accentSoft,
    isDark: true,
  );

  // The light theme, tuned the way Yandex's apps are: a NEUTRAL light-grey
  // canvas (no blue cast) so the one blue accent is the only colour on the
  // page, crisp white cards that sit on it without outlines, near-black ink,
  // neutral greys for secondary text, and a barely-there shadow. The "panel"
  // tokens stay dark for the booking cockpit / AI surfaces.
  static const PaperPalette light = PaperPalette(
    bg: Color(0xFFF2F3F5),
    bgGradientTop: Color(0xFFF7F8FA),
    bgGradientBottom: Color(0xFFECEEF1),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFF4F5F7),
    text: Color(0xFF121417),
    textSecondary: Color(0xFF6B7079),
    textTertiary: Color(0xFFA3A7AF),
    border: Color(0xFFE8E9EC),
    divider: Color(0xFFEFF0F2),
    action: AppColors.accent,
    onAction: Colors.white,
    panel: Color(0xFF161F3A),
    panelField: Color(0xFF24304E),
    panelText: Color(0xFFEEF3FB),
    panelTextDim: Color(0x8CB7C3D6),
    // Neutral and faint: separation comes from white-on-grey, not shadow.
    shadow: Color(0x120B1220),
    clayLight: Color(0x33FFFFFF),
    tint: Color(0xFFE8F1FF),
    isDark: false,
  );
}

class Paper {
  Paper._();

  /// Both brightnesses resolve to the navy look; default is dark.
  static PaperPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? PaperPalette.light
          : PaperPalette.dark;

  /// Avatar tints — a cool blue family on the dark canvas.
  static const List<Color> crayons = [
    Color(0xFF2E8BFF),
    Color(0xFF4F9CFF),
    Color(0xFF3A6FD8),
    Color(0xFF5C7CE0),
    Color(0xFF2FA7C8),
    Color(0xFF6A6FE0),
  ];

  static Color crayon(int index) => crayons[index % crayons.length];
}
