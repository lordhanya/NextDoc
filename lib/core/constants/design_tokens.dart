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

  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // ── Duration ─────────────────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 300);

  // ── Surface layers (used for elevation simulation) ───────────────────
  static const double elevationNone = 0;
  static const double elevationSm = 1;
  static const double elevationMd = 2;
  static const double elevationLg = 4;

  // ── Color glow shadows (for tool cards, accent elements) ─────────────
  static List<BoxShadow> glowSm(Color color) => [
        BoxShadow(
          color: color.withAlpha(20),
          blurRadius: 8,
          offset: Offset.zero,
        ),
      ];

  static List<BoxShadow> glowMd(Color color) => [
        BoxShadow(
          color: color.withAlpha(30),
          blurRadius: 16,
          offset: Offset.zero,
        ),
      ];

  static List<BoxShadow> searchFocusGlow(bool isLight) => [
        BoxShadow(
          color: isLight
              ? Color(0x1A7C5CFF)
              : Color(0x337C5CFF),
          blurRadius: 16,
          offset: Offset.zero,
        ),
        BoxShadow(
          color: isLight
              ? Color(0x0D7C5CFF)
              : Color(0x1A7C5CFF),
          blurRadius: 32,
          offset: Offset.zero,
        ),
      ];

  static List<BoxShadow> navShadow(bool isLight) => isLight
      ? [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ]
      : [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ];
}
