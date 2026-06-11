import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/providers/recent_files_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/typography.dart';

final class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: const _AppearanceSection()),
          SliverToBoxAdapter(child: const _DefaultsSection()),
          SliverToBoxAdapter(child: const _StorageSection()),
          SliverToBoxAdapter(child: const _AboutSection()),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'App preferences and configuration',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared UI Components
// ═══════════════════════════════════════════════════════════════════════════

Widget _buildSettingsIcon({
  required IconData icon,
  required Color color,
  double size = 18,
}) {
  return Icon(icon, size: size, color: color);
}

// ── Section header ─────────────────────────────────────────────────────

final class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xxxl,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          _buildSettingsIcon(icon: icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: AppTextStyles.title.copyWith(color: textColor)),
        ],
      ),
    );
  }
}

// ── Settings card container ─────────────────────────────────────────────

final class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? AppColors.lightSurface1 : AppColors.darkSurface2;
    final border = isLight
        ? AppColors.lightBorder.withAlpha(120)
        : AppColors.darkBorder.withAlpha(80);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border, width: 0.5),
          boxShadow: isLight ? DesignTokens.shadowSm : null,
        ),
        child: child,
      ),
    );
  }
}

// ── Settings row with semantic color icon ───────────────────────────────

final class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final Color semanticColor;
  final bool showDivider;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.semanticColor = AppColors.primary,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final dividerColor = isLight ? AppColors.lightDivider : AppColors.darkDivider;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
    final subtitleColor = isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary;
    final iconBg = semanticColor.withAlpha(isLight ? 12 : 15);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 18, color: semanticColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.body.copyWith(color: textColor)),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(subtitle!, style: AppTextStyles.caption.copyWith(color: subtitleColor)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(child: trailing),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: dividerColor,
            height: 1,
            indent: AppSpacing.lg + 30 + AppSpacing.md,
            endIndent: AppSpacing.lg,
          ),
      ],
    );
  }
}

// ── Dropdown container ──────────────────────────────────────────────────

final class _DropdownContainer extends StatelessWidget {
  final Widget child;

  const _DropdownContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? AppColors.lightSurface2 : AppColors.darkSurface2;
    final border = isLight ? AppColors.lightBorder : AppColors.darkBorder;

    return SizedBox(
      width: 140,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border.withAlpha(120), width: 0.5),
        ),
        child: child,
      ),
    );
  }
}

Widget _buildStyledDropdown<T>({
  required BuildContext context,
  required T value,
  required List<(T, String)> items,
  required ValueChanged<T> onChanged,
  TextStyle? textStyle,
}) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  final menuBg = isLight ? AppColors.lightSurface1 : AppColors.darkSurface2;
  final defaultTextColor = isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;

  return _DropdownContainer(
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: menuBg,
        style: textStyle ?? AppTextStyles.bodySmall.copyWith(color: defaultTextColor),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item.$1,
            child: Text(item.$2),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Appearance — Purple / Indigo
// ═══════════════════════════════════════════════════════════════════════════

final class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: LucideIcons.palette,
          title: 'Appearance',
          color: AppColors.settingsAppearance,
        ),
        _SettingsCard(
          child: _SettingsRow(
            icon: LucideIcons.sun_moon,
            title: 'Theme',
            subtitle: _themeLabel(themeMode),
            trailing: const _ThemeDropdown(),
            semanticColor: AppColors.settingsAppearance,
            showDivider: false,
          ),
        ),
      ],
    );
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light mode',
      ThemeMode.dark => 'Dark mode',
      ThemeMode.system => 'Follow system',
    };
  }
}

final class _ThemeDropdown extends ConsumerWidget {
  const _ThemeDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return _buildStyledDropdown<ThemeOption>(
      context: context,
      value: settings.themeOption,
      items: const [
        (ThemeOption.dark, 'Dark'),
        (ThemeOption.light, 'Light'),
        (ThemeOption.system, 'System'),
      ],
      onChanged: (option) => ref.read(settingsProvider.notifier).setThemeOption(option),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Defaults — Blue
// ═══════════════════════════════════════════════════════════════════════════

final class _DefaultsSection extends ConsumerWidget {
  const _DefaultsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: LucideIcons.sliders_horizontal,
          title: 'Defaults',
          color: AppColors.settingsDefaults,
        ),
        _SettingsCard(
          child: Column(
            children: [
              const _CompressionRow(),
              const _SettingsRow(
                icon: LucideIcons.image,
                title: 'Export Quality',
                subtitle: 'Default quality for image to PDF conversion',
                trailing: _ExportQualityDropdown(),
                semanticColor: AppColors.settingsDefaults,
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _CompressionRow extends ConsumerWidget {
  const _CompressionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsProvider);
    return const _SettingsRow(
      icon: LucideIcons.archive,
      title: 'Compression Level',
      subtitle: 'Default compression for PDF compress tool',
      trailing: _CompressionDropdown(),
      semanticColor: AppColors.settingsCompression,
    );
  }
}

final class _CompressionDropdown extends ConsumerWidget {
  const _CompressionDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return _buildStyledDropdown<CompressionDefault>(
      context: context,
      value: settings.compressionDefault,
      items: const [
        (CompressionDefault.low, 'Low'),
        (CompressionDefault.medium, 'Medium'),
        (CompressionDefault.high, 'High'),
      ],
      onChanged: (value) => ref.read(settingsProvider.notifier).setCompressionDefault(value),
    );
  }
}

final class _ExportQualityDropdown extends ConsumerWidget {
  const _ExportQualityDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return _buildStyledDropdown<ExportQuality>(
      context: context,
      value: settings.exportQuality,
      items: const [
        (ExportQuality.standard, 'Standard'),
        (ExportQuality.highQuality, 'High Quality'),
        (ExportQuality.smallSize, 'Small Size'),
      ],
      onChanged: (value) => ref.read(settingsProvider.notifier).setExportQuality(value),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Storage — Cyan
// ═══════════════════════════════════════════════════════════════════════════

final class _StorageSection extends ConsumerWidget {
  const _StorageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: LucideIcons.database,
          title: 'Storage',
          color: AppColors.settingsStorage,
        ),
        _SettingsCard(
          child: const _CacheRow(),
        ),
      ],
    );
  }
}

final class _CacheRow extends ConsumerStatefulWidget {
  const _CacheRow();

  @override
  ConsumerState<_CacheRow> createState() => _CacheRowState();
}

final class _CacheRowState extends ConsumerState<_CacheRow> {
  String _cacheSize = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    final tempDir = await getTemporaryDirectory();
    int totalSize = 0;

    if (await tempDir.exists()) {
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (_) {}
        }
      }
    }

    final String formatted;
    if (totalSize < 1024) {
      formatted = '$totalSize B';
    } else if (totalSize < 1024 * 1024) {
      formatted = '${(totalSize / 1024).toStringAsFixed(1)} KB';
    } else {
      formatted = '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    if (mounted) setState(() => _cacheSize = formatted);
  }

  Future<void> _clearCache() async {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final dialogSurface = isLight ? AppColors.lightSurface1 : AppColors.darkSurface1;
    final textSecondary = isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.xxl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(
                LucideIcons.trash_2,
                size: 28,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Clear Cache', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This will remove all cached thumbnails and temporary files ($_cacheSize).',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final tempDir = await getTemporaryDirectory();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      await tempDir.create();
    }

    ref.read(pdfServiceProvider).clearCache();

    if (mounted) {
      setState(() => _cacheSize = '0 B');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: LucideIcons.trash_2,
      title: 'Clear Cache',
      subtitle: '$_cacheSize • Thumbnails and temporary files',
      trailing: GestureDetector(
        onTap: _clearCache,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.warning.withAlpha(25),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'Clear',
            style: AppTextStyles.buttonSmall.copyWith(color: AppColors.warning),
          ),
        ),
      ),
      semanticColor: AppColors.settingsDanger,
      showDivider: false,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// About — Teal
// ═══════════════════════════════════════════════════════════════════════════

final class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: LucideIcons.info,
          title: 'About',
          color: AppColors.settingsAbout,
        ),
        _SettingsCard(
          child: Column(
            children: [
              const _SettingsRow(
                icon: LucideIcons.app_window,
                title: 'App Name',
                trailing: _AboutValue('NextDoc'),
                semanticColor: AppColors.settingsAbout,
              ),
              const _SettingsRow(
                icon: LucideIcons.tag,
                title: 'Version',
                trailing: _AboutValue('1.0.0'),
                semanticColor: AppColors.settingsAbout,
              ),
              const _SettingsRow(
                icon: LucideIcons.hash,
                title: 'Build Number',
                trailing: _AboutValue('1'),
                semanticColor: AppColors.settingsAbout,
              ),
              const _SettingsRow(
                icon: LucideIcons.user,
                title: 'Developer',
                trailing: _AboutValue('ASHIFCODES'),
                semanticColor: AppColors.settingsAbout,
              ),
              const _SettingsRow(
                icon: LucideIcons.code,
                title: 'Flutter Version',
                trailing: _AboutValue('3.44.0'),
                semanticColor: AppColors.settingsAbout,
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _AboutValue extends StatelessWidget {
  final String value;

  const _AboutValue(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: AppTextStyles.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
