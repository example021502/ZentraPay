import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

/// Centralized theme configuration for Zentrapay application.
/// All feature screens should use these styles for consistency.
class AppTheme {
  // ============================================================
  // COLOR PALETTE - Zentrapay Design System
  // ============================================================
  static const Color primaryPink = Color(0xFFF21773);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color secondaryNavy = Color(0xFF210163);
  static const Color textBlack = Color(0xFF000000);
  static const Color accentPurple = Color(0xFF661E98);
  static const Color accentBlue = Color(0xFF396FD4);
  static const Color successGreen = Color(0xFF06881C);
  static const Color warningOrange = Color(0xFFF79E1B);
  static const Color lightGrey = Color(0x80808080);
  static const Color cardBackground = Color(0xFFF8F9FA);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Feature-specific accent colors
  static const Color zpayColor = Color(0xFFF21773);
  static const Color zbankColor = Color(0xFF210163);
  static const Color zremitColor = Color(0xFF396FD4);
  static const Color zvoiceColor = Color(0xFF661E98);
  static const Color zinvestColor = Color(0xFFF79E1B);
  static const Color zgrowColor = Color(0xFF06881C);
  static const Color payAnywhereColor = Color(0xFFF21773);
  static const Color secureColor = Color(0xFF210163);

  // ============================================================
  // TYPOGRAPHY
  // ============================================================
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: textBlack,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: textBlack,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textBlack,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textBlack,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textBlack,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textBlack,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textBlack,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textBlack,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textBlack,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textBlack,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textBlack,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textBlack,
  );

  // White text variants for dark backgrounds
  static const TextStyle whiteDisplayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: primaryWhite,
  );

  static const TextStyle whiteDisplayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: primaryWhite,
  );

  static const TextStyle whiteHeadline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryWhite,
  );

  static const TextStyle whiteBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: primaryWhite,
  );

  static const TextStyle whiteBodySmall = TextStyle(
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
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
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

  static BoxDecoration get primaryCardDecoration => BoxDecoration(
    color: primaryPink,
    borderRadius: BorderRadius.circular(radiusXl),
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
