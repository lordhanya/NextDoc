import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService.instance;
});

final class AppSettings {
  final ThemeOption themeOption;
  final CompressionDefault compressionDefault;
  final ExportQuality exportQuality;

  const AppSettings({
    required this.themeOption,
    required this.compressionDefault,
    required this.exportQuality,
  });

  AppSettings copyWith({
    ThemeOption? themeOption,
    CompressionDefault? compressionDefault,
    ExportQuality? exportQuality,
  }) {
    return AppSettings(
      themeOption: themeOption ?? this.themeOption,
      compressionDefault: compressionDefault ?? this.compressionDefault,
      exportQuality: exportQuality ?? this.exportQuality,
    );
  }
}

final class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _service;

  SettingsNotifier(this._service)
      : super(AppSettings(
          themeOption: _service.getThemeOption(),
          compressionDefault: _service.getCompressionDefault(),
          exportQuality: _service.getExportQuality(),
        ));

  Future<void> setThemeOption(ThemeOption option) async {
    state = state.copyWith(themeOption: option);
    await _service.setThemeOption(option);
  }

  Future<void> setCompressionDefault(CompressionDefault value) async {
    state = state.copyWith(compressionDefault: value);
    await _service.setCompressionDefault(value);
  }

  Future<void> setExportQuality(ExportQuality value) async {
    state = state.copyWith(exportQuality: value);
    await _service.setExportQuality(value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsServiceProvider));
});
