import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import 'settings_provider.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return switch (settings.themeOption) {
    ThemeOption.light => ThemeMode.light,
    ThemeOption.dark => ThemeMode.dark,
    ThemeOption.system => ThemeMode.system,
  };
});
