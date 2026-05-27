import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'System';

  // ── Display ──────────────────────────────────────────────────────────
  static TextStyle get display => const TextStyle(
        fontFamily: _font,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.15,
      );

  static TextStyle get headline => const TextStyle(
        fontFamily: _font,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: _font,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
      );

  // ── Titles ────────────────────────────────────────────────────────────
  static TextStyle get title => const TextStyle(
        fontFamily: _font,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontFamily: _font,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // ── Body ──────────────────────────────────────────────────────────────
  static TextStyle get body => const TextStyle(
        fontFamily: _font,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: _font,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ── Caption / Meta ────────────────────────────────────────────────────
  static TextStyle get caption => const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.2,
      );

  static TextStyle get label => const TextStyle(
        fontFamily: _font,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.4,
      );

  // ── Buttons ───────────────────────────────────────────────────────────
  static TextStyle get button => const TextStyle(
        fontFamily: _font,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        letterSpacing: 0.3,
        height: 1.2,
      );

  static TextStyle get buttonSmall => const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.2,
      );
}
