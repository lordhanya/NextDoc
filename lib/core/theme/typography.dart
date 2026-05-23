import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'System';

  static TextStyle get headline => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle get title => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
        height: 1.3,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
        height: 1.3,
        letterSpacing: 0.2,
      );

  static TextStyle get button => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        letterSpacing: 0.3,
        height: 1.2,
      );

  static TextStyle get buttonSmall => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
        height: 1.2,
      );

  static TextStyle get label => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
        letterSpacing: 0.5,
        height: 1.2,
      );
}
