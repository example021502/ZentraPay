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

  // Near-black rather than pure black — softer, more modern text color.
  // Kept under the existing name so every AppTheme.textBlack /
  // AppColors.textBlack reference across the app benefits automatically.
  static const Color textBlack = Color(0xFF111827);
  static const Color accentPurple = Color(0xFF661E98);
  static const Color accentBlue = Color(0xFF396FD4);
  static const Color successGreen = Color(0xFF06881C);
  static const Color warningOrange = Color(0xFFF79E1B);
  static const Color lightGrey = Color(0x80808080);
  static const Color cardBackground = Color(0xFFF8F9FA);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Semantic colors
  static const Color errorRed = Color(0xFFD92D20);
  static const Color infoBlue = accentBlue;

  // Neutral gray scale — text hierarchy, borders, surfaces
  static const Color gray900 = Color(0xFF111827);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray50 = Color(0xFFF9FAFB);

  // Feature-specific accent colors
  static const Color zpayColor = Color(0xFFF21773);
  static const Color zbankColor = Color(0xFF210163);
  static const Color zremitColor = Color(0xFF396FD4);
  static const Color zvoiceColor = Color(0xFF661E98);
  static const Color zinvestColor = Color(0xFFF79E1B);
  static const Color zgrowColor = Color(0xFF06881C);
  static const Color payAnywhereColor = Color(0xFFF21773);
  static const Color secureColor = Color(0xFF210163);
  static const Color merchantColor = Color(0xFF0D9488);

  // ============================================================
  // TYPOGRAPHY
  // ============================================================
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: textBlack,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: textBlack,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textBlack,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textBlack,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textBlack,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textBlack,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textBlack,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textBlack,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textBlack,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textBlack,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textBlack,
  );

  static const TextStyle labelSmall = TextStyle(
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
    color: primaryWhite,
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
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPink, accentPurple],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryNavy, accentBlue],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, Color(0xFF0AD42E)],
  );

  // Deep electric blue (left) -> vivid hot pink (right), per the ZPay wireframe
  // brief's core screen background spec. Distinct from primaryGradient (which
  // runs pink -> purple) — this is the full-bleed hero/screen background.
  static const Color electricBlue = Color(0xFF1230D8);
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [electricBlue, primaryPink],
  );

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
