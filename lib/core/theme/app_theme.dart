import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

abstract final class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _darkTheme();
  static ThemeData get lightTheme => _lightTheme();

  // ═════════════════════════════════════════════════════════════════════
  //  DARK THEME — muted premium
  // ═════════════════════════════════════════════════════════════════════
  static ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface1,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
        onError: AppColors.onPrimary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface1,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkIconColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(
            color: AppColors.darkBorder,
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      textTheme: _darkTextTheme(),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface2,
        contentTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      inputDecorationTheme: _darkInputTheme(),
      iconTheme: const IconThemeData(
        color: AppColors.darkIconColor,
        size: 22,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static TextTheme _darkTextTheme() {
    return TextTheme(
      displayLarge: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.8,
        height: 1.15,
      ),
      headlineLarge: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextPrimary,
        height: 1.4,
      ),
      bodyLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextPrimary,
        height: 1.6,
      ),
      bodyMedium: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextSecondary,
        height: 1.5,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextMuted,
        height: 1.4,
        letterSpacing: 0.2,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        letterSpacing: 0.3,
        height: 1.2,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextMuted,
        height: 1.3,
        letterSpacing: 0.4,
      ),
    );
  }

  static InputDecorationTheme _darkInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface2,
      border: _outlineBorder(AppColors.darkBorder),
      enabledBorder: _outlineBorder(AppColors.darkBorder),
      focusedBorder: _outlineBorder(AppColors.primary, 1.5),
      errorBorder: _outlineBorder(AppColors.error),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      hintStyle: const TextStyle(
        color: AppColors.darkTextMuted,
        fontSize: 14,
      ),
      labelStyle: const TextStyle(
        color: AppColors.darkTextSecondary,
        fontSize: 14,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  //  LIGHT THEME — warm, clean, professional
  // ═════════════════════════════════════════════════════════════════════
  static ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface1,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
        onError: AppColors.onPrimary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface1,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightIconColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      textTheme: _lightTextTheme(),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightTextPrimary,
        contentTextStyle: const TextStyle(
          color: AppColors.lightSurface1,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      inputDecorationTheme: _lightInputTheme(),
      iconTheme: const IconThemeData(
        color: AppColors.lightIconColor,
        size: 22,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static TextTheme _lightTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.lightTextPrimary,
        letterSpacing: -0.8,
        height: 1.15,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.lightTextPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextPrimary,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextPrimary,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextMuted,
        height: 1.4,
        letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        letterSpacing: 0.3,
        height: 1.2,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextMuted,
        height: 1.3,
        letterSpacing: 0.4,
      ),
    );
  }

  static InputDecorationTheme _lightInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface2,
      border: _outlineBorder(AppColors.lightBorder),
      enabledBorder: _outlineBorder(AppColors.lightBorder),
      focusedBorder: _outlineBorder(AppColors.primary, 1.5),
      errorBorder: _outlineBorder(AppColors.error),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      hintStyle: const TextStyle(
        color: AppColors.lightTextMuted,
        fontSize: 14,
      ),
      labelStyle: const TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: 14,
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  static OutlineInputBorder _outlineBorder(Color color, [double width = 0.5]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
