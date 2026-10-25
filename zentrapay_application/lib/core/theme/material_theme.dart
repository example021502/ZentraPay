import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Builds the app's Material ThemeData from AppTheme's design tokens, so
/// anything that doesn't explicitly override a color/style inherits sensible
/// brand-consistent defaults instead of Material 3's stock purple-seeded
/// ColorScheme.
///
/// Reads [AppTheme.isDark], so call it again (the root MaterialApp does, via
/// ThemeController) whenever the mode changes. Light mode is the original
/// design; dark mode swaps in darkened pinks, white text and pink buttons.
ThemeData buildAppTheme() {
  final dark = AppTheme.isDark;
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: AppTheme.gray50,
    colorScheme: dark
        ? ColorScheme.dark(
            primary: AppTheme.primaryPink,
            onPrimary: AppTheme.primaryWhite,
            secondary: AppTheme.primaryPink,
            onSecondary: AppTheme.primaryWhite,
            error: AppTheme.errorRed,
            onError: AppTheme.primaryWhite,
            surface: AppTheme.surface,
            onSurface: AppTheme.textBlack,
          )
        : ColorScheme.light(
            primary: AppTheme.primaryPink,
            onPrimary: AppTheme.primaryWhite,
            secondary: AppTheme.secondaryNavy,
            onSecondary: AppTheme.primaryWhite,
            error: AppTheme.errorRed,
            onError: AppTheme.primaryWhite,
            surface: AppTheme.surface,
            onSurface: AppTheme.textBlack,
          ),
    textTheme: TextTheme(
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
    appBarTheme: AppBarTheme(
      backgroundColor: AppTheme.headerPink,
      foregroundColor: AppTheme.primaryWhite,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTheme.whiteHeadline,
    ),
    // Every button in the app: white label on secondary navy in light mode and
    // on primary pink in dark mode (AppTheme.buttonColor). The bottom navigation
    // bar is drawn by its own widget and is not affected.
    //
    // Icons follow the text colour: near-black in light mode, white in dark.
    iconTheme: IconThemeData(color: AppTheme.textBlack),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppTheme.textBlack),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.buttonColor,
        foregroundColor: AppTheme.primaryWhite,
        minimumSize: const Size(double.infinity, 55),
        elevation: 2,
        shape: shape,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.buttonColor,
        foregroundColor: AppTheme.primaryWhite,
        minimumSize: const Size(double.infinity, 55),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppTheme.buttonColor,
        foregroundColor: AppTheme.primaryWhite,
        side: BorderSide(color: AppTheme.buttonColor),
        minimumSize: const Size(double.infinity, 55),
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppTheme.buttonColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.gray100,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      hintStyle: TextStyle(color: AppTheme.gray500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide(color: AppTheme.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.errorRed),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppTheme.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      margin: EdgeInsets.zero,
    ),
    // Modal overlays — dialogs and bottom sheets that don't pass their own
    // `shape`/`backgroundColor` — share the same 30px top-corner radius so
    // every overlay in the app looks identical.
    dialogTheme: DialogThemeData(
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? AppTheme.brand : null,
      ),
      checkColor: WidgetStatePropertyAll(AppTheme.primaryWhite),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(AppTheme.primaryWhite),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? AppTheme.brand : null,
      ),
    ),
    dividerColor: AppTheme.dividerColor,
  );
}
