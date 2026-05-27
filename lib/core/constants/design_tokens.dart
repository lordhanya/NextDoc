import 'package:flutter/material.dart';

abstract final class DesignTokens {
  DesignTokens._();

  // ── Shadows ──────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x10000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // ── Durations ────────────────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 300);

  // ── Surface layers (used for elevation simulation) ───────────────────
  static const double elevationNone = 0;
  static const double elevationSm = 1;
  static const double elevationMd = 2;
  static const double elevationLg = 4;
}
