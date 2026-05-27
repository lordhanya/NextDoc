import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption { system, light, dark }

enum CompressionDefault { low, medium, high }

enum ExportQuality { standard, highQuality, smallSize }

final class SettingsService {
  static const _themeKey = 'app_theme';
  static const _compressionKey = 'compression_default';
  static const _exportQualityKey = 'export_quality';

  static final SettingsService instance = SettingsService._();
  SettingsService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  ThemeOption getThemeOption() {
    final value = _prefs?.getString(_themeKey) ?? 'dark';
    return ThemeOption.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeOption.dark,
    );
  }

  Future<void> setThemeOption(ThemeOption option) async {
    await _prefs?.setString(_themeKey, option.name);
  }

  ThemeMode getThemeMode() {
    final option = getThemeOption();
    switch (option) {
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
      case ThemeOption.system:
        return ThemeMode.system;
    }
  }

  CompressionDefault getCompressionDefault() {
    final value = _prefs?.getString(_compressionKey) ?? 'medium';
    return CompressionDefault.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CompressionDefault.medium,
    );
  }

  Future<void> setCompressionDefault(CompressionDefault value) async {
    await _prefs?.setString(_compressionKey, value.name);
  }

  ExportQuality getExportQuality() {
    final value = _prefs?.getString(_exportQualityKey) ?? 'standard';
    return ExportQuality.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExportQuality.standard,
    );
  }

  Future<void> setExportQuality(ExportQuality value) async {
    await _prefs?.setString(_exportQualityKey, value.name);
  }
}
