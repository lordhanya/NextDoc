import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/typography.dart';

final class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLight
            ? AppColors.lightSurface1.withAlpha(230)
            : AppColors.darkSurface1.withAlpha(230),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight ? AppColors.lightBorder : AppColors.darkBorder,
          width: 0.5,
        ),
      ),
      child: Text(
        '${currentPage + 1} / $totalPages',
        style: AppTextStyles.label.copyWith(
          color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
        ),
      ),
    );
  }
}
