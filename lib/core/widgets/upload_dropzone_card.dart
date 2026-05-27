import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/typography.dart';

final class UploadDropzoneCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? onTap;

  const UploadDropzoneCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  State<UploadDropzoneCard> createState() => _UploadDropzoneCardState();
}

final class _UploadDropzoneCardState extends State<UploadDropzoneCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) async {
        setState(() => _isHovered = false);
        await widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.huge + AppSpacing.lg,
          horizontal: AppSpacing.xxl,
        ),
        decoration: BoxDecoration(
          color: _isHovered
              ? (isLight ? AppColors.lightSurface2 : AppColors.darkSurface3)
              : (isLight ? AppColors.lightSurface1 : AppColors.darkSurface2),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: _isHovered
                ? AppColors.primary.withAlpha(80)
                : (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(100),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.primaryContainer
                    : (isLight ? AppColors.lightSurface2 : AppColors.darkSurface2),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(
                widget.icon,
                size: 36,
                color: _isHovered
                    ? AppColors.primary
                    : (isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              widget.title,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.subtitle,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
