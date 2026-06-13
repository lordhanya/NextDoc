import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/typography.dart';

enum FilterType {
  original,
  grayscale,
  blackAndWhite,
  sepia,
  highContrast,
}

final class FiltersPanel extends StatelessWidget {
  final FilterType currentFilter;
  final ValueChanged<FilterType> onFilterChanged;
  final Uint8List? previewBytes;

  const FiltersPanel({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    this.previewBytes,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.sm),
          child: Text('Filters', style: AppTextStyles.titleSmall),
        ),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              _filterTile('Original', FilterType.original, isLight),
              const SizedBox(width: AppSpacing.md),
              _filterTile('Grayscale', FilterType.grayscale, isLight),
              const SizedBox(width: AppSpacing.md),
              _filterTile('B&W', FilterType.blackAndWhite, isLight),
              const SizedBox(width: AppSpacing.md),
              _filterTile('Sepia', FilterType.sepia, isLight),
              const SizedBox(width: AppSpacing.md),
              _filterTile('High Contrast', FilterType.highContrast, isLight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterTile(String label, FilterType type, bool isLight) {
    final selected = currentFilter == type;
    return GestureDetector(
      onTap: () => onFilterChanged(type),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? AppColors.iconEditorStudio
                : (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(50),
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filterIcon(type),
              size: 28,
              color: selected
                  ? AppColors.iconEditorStudio
                  : (isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected
                    ? AppColors.iconEditorStudio
                    : (isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _filterIcon(FilterType type) {
    switch (type) {
      case FilterType.original:
        return Icons.image_rounded;
      case FilterType.grayscale:
        return Icons.blur_on_rounded;
      case FilterType.blackAndWhite:
        return Icons.contrast_rounded;
      case FilterType.sepia:
        return Icons.filter_vintage_rounded;
      case FilterType.highContrast:
        return Icons.brightness_high_rounded;
    }
  }
}
