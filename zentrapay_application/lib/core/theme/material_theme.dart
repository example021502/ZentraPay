import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Builds the app's Material ThemeData from AppTheme's design tokens, so
/// anything that doesn't explicitly override a color/style inherits sensible
/// brand-consistent defaults instead of Material 3's stock purple-seeded
/// ColorScheme.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppTheme.gray50,
    colorScheme: const ColorScheme.light(
      primary: AppTheme.primaryPink,
      onPrimary: AppTheme.primaryWhite,
      secondary: AppTheme.secondaryNavy,
      onSecondary: AppTheme.primaryWhite,
      error: AppTheme.errorRed,
      onError: AppTheme.primaryWhite,
      surface: AppTheme.primaryWhite,
      onSurface: AppTheme.textBlack,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTheme.displayLarge,
      displayMedium: AppTheme.displayMedium,
      displaySmall: AppTheme.displaySmall,
      headlineLarge: AppTheme.headlineLarge,
      headlineMedium: AppTheme.headlineMedium,
      headlineSmall: AppTheme.headlineSmall,
      titleLarge: AppTheme.titleLarge,
      bodyLarge: AppTheme.bodyLarge,
      bodyMedium: AppTheme.bodyMedium,
      bodySmall: AppTheme.bodySmall,
      labelLarge: AppTheme.labelLarge,
      labelSmall: AppTheme.labelSmall,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTheme.primaryPink,
      foregroundColor: AppTheme.primaryWhite,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTheme.whiteHeadline,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: AppTheme.primaryWhite,
        minimumSize: const Size(double.infinity, 55),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryPink,
        side: const BorderSide(color: AppTheme.primaryPink),
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.gray100,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.primaryPink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.errorRed),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppTheme.primaryWhite,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerColor: AppTheme.dividerColor,
  );
}
