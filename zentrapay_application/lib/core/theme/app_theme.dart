import 'package:flutter/material.dart';

/// Centralized theme configuration for Zentrapay application.
/// All feature screens should use these styles for consistency.
class AppTheme {
  // ============================================================
  // COLOR PALETTE - Zentrapay Design System
  // ============================================================
  static const Color primaryPink = Color(0xFFF21773);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color secondaryNavy = Color(0xFF210163);

  // ------------------------------------------------------------
  // Light / dark mode
  //
  // `isDark` is flipped only by ThemeController. Every token below that is a
  // getter resolves to its light or dark value at the moment a widget builds,
  // so a toggle followed by a full rebuild (ThemeController.apply) re-colours
  // the whole app without any screen having to know which mode it is in.
  // Brand colours that are the same in both modes stay `const`.
  // ------------------------------------------------------------
  static bool isDark = false;

  static Color _pick(Color light, Color dark) => isDark ? dark : light;

  // Dark palette: darkened pinks, white text, pink actions.
  static const Color darkBackground = Color(0xFF1C0B14);
  static const Color darkSurface = Color(0xFF2A1220);
  static const Color darkSurfaceHigh = Color(0xFF3A1A2D);
  static const Color darkHeaderPink = Color(0xFF5C1038);
  static const Color darkBorder = Color(0xFF54304A);

  // Near-black rather than pure black — softer, more modern text color.
  // Kept under the existing name so every AppTheme.textBlack /
  // AppColors.textBlack reference across the app benefits automatically.
  // In dark mode it becomes white.
  static Color get textBlack => _pick(const Color(0xFF111827), Colors.white);
  static const Color accentPurple = Color(0xFF661E98);
  static const Color accentBlue = Color(0xFF396FD4);
  static const Color successGreen = Color(0xFF06881C);
  static const Color warningOrange = Color(0xFFF79E1B);
  static const Color lightGrey = Color(0x80808080);
  static Color get cardBackground =>
      _pick(const Color(0xFFF8F9FA), darkSurface);
  static Color get dividerColor => _pick(const Color(0xFFE0E0E0), darkBorder);
  static Color get focusFieldColor =>
      _pick(AppTheme.secondaryNavy, AppTheme.primaryWhite);
  static Color get fieldColor => _pick(AppTheme.gray300, AppTheme.primaryWhite);

  // Semantic colors
  static const Color errorRed = Color(0xFFD92D20);
  static const Color infoBlue = accentBlue;

  // Neutral gray scale — text hierarchy, borders, surfaces
  static Color get gray900 => _pick(const Color(0xFF111827), Colors.white);
  static Color get gray700 =>
      _pick(const Color(0xFF374151), const Color(0xFFE3CFD9));
  static Color get gray500 =>
      _pick(const Color(0xFF6B7280), const Color(0xFFC4A5B5));
  static Color get gray300 => _pick(const Color(0xFFD1D5DB), darkBorder);
  static Color get gray100 => _pick(const Color(0xFFF3F4F6), darkSurfaceHigh);
  static Color get gray50 => _pick(const Color(0xFFF9FAFB), darkBackground);

  // Role tokens. These exist because the same literal colour (white, pink,
  // navy) plays different roles in the light design and needs different dark
  // equivalents:
  //  - surface:    card / sheet / field fill (white -> dark rose)
  //  - headerPink: the coloured screen header (pink -> darkened pink)
  //  - brand:      buttons and accent icons/text. Primary pink in BOTH modes, so
  //                every card, button, icon and link reads as one family.
  static Color get surface => _pick(primaryWhite, darkSurface);
  static Color get headerPink => _pick(primaryPink, darkHeaderPink);
  static const Color brand = primaryPink;

  /// Fill of every button: secondary navy in light mode, primary pink in dark
  /// mode (white label on both).
  static Color get buttonColor => _pick(secondaryNavy, primaryPink);

  // Feature-specific accent colors. Every section now shares the brand pink;
  // blue only ever appears as a hint emerging from pink inside a gradient
  // (see [brandGradient]).
  static const Color zpayColor = primaryPink;
  static const Color zbankColor = primaryPink;
  static const Color zremitColor = primaryPink;
  static const Color zvoiceColor = primaryPink;
  static const Color zinvestColor = Color(0xFFF79E1B);
  static const Color zgrowColor = Color(0xFF06881C);
  static const Color payAnywhereColor = Color(0xFFF21773);
  static const Color secureColor = primaryPink;
  static const Color merchantColor = Color(0xFF0D9488);

  // ============================================================
  // TYPOGRAPHY
  // ============================================================
  static TextStyle get displayLarge => TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: textBlack,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => TextStyle(
    fontFamily: 'Inter',
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: textBlack,
  );

  static TextStyle get displaySmall => TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textBlack,
  );

  static TextStyle get headlineLarge => TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textBlack,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textBlack,
  );

  static TextStyle get headlineSmall => TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textBlack,
  );

  static TextStyle get titleLarge => TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textBlack,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textBlack,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textBlack,
    height: 1.5,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textBlack,
  );

  static TextStyle get labelLarge => TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textBlack,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textBlack,
  );

  // White text variants for dark backgrounds
  static const TextStyle whiteDisplayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: primaryWhite,
  );

  static const TextStyle whiteDisplayMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: primaryWhite,
  );

  static const TextStyle whiteHeadline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryWhite,
  );

  static const TextStyle whiteBody = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: primaryWhite,
  );

  static const TextStyle whiteBodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );

  // ============================================================
  // SPACING
  // ============================================================
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 15.0;
  static const double spacingLg = 20.0;
  static const double spacingXl = 30.0;
  static const double spacingXxl = 40.0;

  // ============================================================
  // BORDER RADIUS
  // ============================================================
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 15.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 30.0;
  static const double radiusFull = 200.0;

  // ============================================================
  // SHADOWS
  // ============================================================
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withAlpha(30),
      blurRadius: 15,
      offset: const Offset(0, 0),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withAlpha(12),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  // ============================================================
  // DECORATIONS
  // ============================================================
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusXl),
    boxShadow: cardShadow,
  );

  static BoxConstraints constraintsXs(BuildContext context) => BoxConstraints(
    maxWidth: MediaQuery.of(context).size.width,
    // maxHeight: 20,
  );

  // Returns a custom BoxDecoration using the provided color, radius, and shadow settings
  static BoxDecoration coloredCardDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radiusXl),
      boxShadow: cardShadow,
    );
  }

  static BoxDecoration get primaryCardDecoration => BoxDecoration(
    color: primaryPink,
    borderRadius: BorderRadius.circular(radiusXl),
  );

  static Container divider(BuildContext context, Color color) => Container(
    width: MediaQuery.of(context).size.width,
    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
    height: 0.5,
    decoration: BoxDecoration(
      color: color.withAlpha(50),
      borderRadius: BorderRadius.circular(radiusXl),
    ),
  );

  static Container dot(Color color) => Container(
    width: 6,
    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
    height: 6,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(200),
    ),
  );

  static BoxDecoration get inputDecoration => BoxDecoration(
    color: lightGrey.withAlpha(40),
    borderRadius: BorderRadius.circular(radiusFull),
  );

  // ============================================================
  // GRADIENTS
  // ============================================================
  // The brand uses flat primary pink - no gradients. These stay as
  // (single-colour) LinearGradients only so the many `gradient:` call sites keep
  // working and render as solid pink.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPink, primaryPink],
  );

  static const LinearGradient brandGradient = primaryGradient;

  static const LinearGradient secondaryGradient = primaryGradient;

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, Color(0xFF0AD42E)],
  );

  // Full-bleed hero/screen background. Pink-led like every other surface: the
  // blue only emerges from the pink towards the far corner.
  static const Color electricBlue = Color(0xFF1230D8);
  static const LinearGradient heroGradient = primaryGradient;

  // ============================================================
  // GLASSMORPHISM
  // Semi-transparent frosted-glass surfaces used over heroGradient, per the
  // wireframe brief ("frosted glass with a subtle white border").
  // ============================================================
  static final Color glassSurface = Colors.white.withValues(alpha: 0.14);
  static final Color glassSurfaceStrong = Colors.white.withValues(alpha: 0.22);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.30);
  static const double glassBlurSigma = 18.0;

  // ============================================================
  // RESPONSIVE HELPERS
  // ============================================================
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  static double responsivePadding(BuildContext context) {
    return isTablet(context) ? 40.0 : 15.0;
  }

  static double responsiveMaxWidth(BuildContext context) {
    return isTablet(context) ? 800.0 : double.infinity;
  }

  static double responsiveBottomPadding(BuildContext context) {
    return isTablet(context)
        ? 40.0
        : MediaQuery.of(context).padding.bottom + 120;
  }
}
