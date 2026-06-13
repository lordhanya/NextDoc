import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// NextDoc Design System — Color Tokens
// ═══════════════════════════════════════════════════════════════════════
// Inspired by Linear, Notion, Arc — muted premium productivity aesthetic.
// ═══════════════════════════════════════════════════════════════════════

abstract final class AppColors {
  AppColors._();

  // ── Dark theme ──────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0A0B);
  static const Color darkSurface1 = Color(0xFF111113);
  static const Color darkSurface2 = Color(0xFF18181B);
  static const Color darkSurface3 = Color(0xFF1F1F23);
  static const Color darkBorder = Color(0xFF27272A);
  static const Color darkDivider = Color(0xFF1C1C20);

  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextMuted = Color(0xFF71717A);

  static const Color darkIconColor = Color(0xFFA1A1AA);
  static const Color darkNavBackground = Color(0xF0111113);

  // ── Light theme ─────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface1 = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF1F1F4);
  static const Color lightSurface3 = Color(0xFFE8E8ED);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightDivider = Color(0xFFE8E8ED);

  static const Color lightTextPrimary = Color(0xFF111113);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextMuted = Color(0xFFA1A1AA);

  static const Color lightIconColor = Color(0xFF9CA3AF);
  static const Color lightNavBackground = Color(0xF0FFFFFF);

  // ── Semantic / Accent (shared across themes) ────────────────────────
  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryVariant = Color(0xFF6B4FE8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF5B8CFF);
  static const Color secondaryVariant = Color(0xFF4A7AE8);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Semantic icon colors (tools) ────────────────────────────────────
  static const Color iconMerge = Color(0xFF5B8CFF);
  static const Color iconCompress = Color(0xFFF59E0B);
  static const Color iconSplit = Color(0xFF22C55E);
  static const Color iconImageToPdf = Color(0xFF7C5CFF);
  static const Color iconPdfToJpg = Color(0xFF06B6D4);
  static const Color iconProtection = Color(0xFFE85D3A);
  static const Color iconEditorStudio = Color(0xFF8B5CF6);
  static const Color iconDelete = Color(0xFFEF4444);
  static const Color iconSettings = Color(0xFF7C5CFF);

  // ── Semantic icon colors (settings categories) ──────────────────────
  // Muted premium hues for visual scanning by category
  static const Color settingsAppearance = Color(0xFF7C5CFF);  // purple / indigo
  static const Color settingsDefaults  = Color(0xFF5B8CFF);  // blue
  static const Color settingsCompression = Color(0xFFF59E0B); // amber
  static const Color settingsStorage   = Color(0xFF06B6D4);  // cyan
  static const Color settingsAbout     = Color(0xFF14B8A6);  // teal
  static const Color settingsDanger    = Color(0xFFEF4444);  // red

  // ── Shimmer ─────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFF1F1F23);
  static const Color shimmerHighlight = Color(0xFF27272A);

  // ── Container / Glass ───────────────────────────────────────────────
  static const Color glassBackground = Color(0x80111113);
  static const Color glassBorder = Color(0x3327272A);

  // ── Primary container (accent bg for icon rings etc.) ───────────────
  static const Color primaryContainer = Color(0xFF2A2566);
  static const Color onPrimaryContainer = Color(0xFFD0CDFF);
  static const Color lightPrimaryContainer = Color(0xFFEEECFF);
  static const Color lightOnPrimaryContainer = Color(0xFF2A2566);

  // ═════════════════════════════════════════════════════════════════════
  // Backward‑compatible aliases (point to dark theme defaults)
  // ═════════════════════════════════════════════════════════════════════

  static const Color background = darkBackground;
  static const Color surface = darkSurface1;
  static const Color surfaceVariant = darkSurface2;
  static const Color card = darkSurface2;
  static const Color cardVariant = darkSurface3;

  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textHint = darkTextMuted;

  static const Color border = darkBorder;
  static const Color divider = darkDivider;

  static const Color iconColor = darkIconColor;
  static const Color iconSelected = primary;

  static const Color navBackground = darkNavBackground;
}
