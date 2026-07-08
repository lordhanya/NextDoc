import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

Widget _shimmerGradient(BuildContext context, Widget child) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  return child.animate(onInit: (controller) => controller.repeat()).shimmer(
    duration: 1500.ms,
    colors: [
      isLight ? AppColors.lightSurface3 : AppColors.shimmerBase,
      isLight ? AppColors.lightSurface2 : AppColors.shimmerHighlight,
      isLight ? AppColors.lightSurface3 : AppColors.shimmerBase,
    ],
  );
}

Color _shimmerBase(BuildContext context) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  return isLight ? AppColors.lightSurface3 : AppColors.shimmerBase;
}

final class ShimmerText extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerText({super.key, this.width = 80, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return _shimmerGradient(
      context,
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _shimmerBase(context),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

final class ShimmerThumbnail extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerThumbnail({
    super.key,
    this.width = 64,
    this.height = 64,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return _shimmerGradient(
      context,
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _shimmerBase(context),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

final class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(100),
          width: 0.5,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerThumbnail(width: double.infinity, height: 140, radius: AppRadius.md),
          SizedBox(height: AppSpacing.sm),
          ShimmerText(width: 120, height: 14),
          SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              ShimmerText(width: 50, height: 12),
              Spacer(),
              ShimmerText(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

final class ShimmerRecentFilesGrid extends StatelessWidget {
  final int itemCount;

  const ShimmerRecentFilesGrid({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => const ShimmerCard(),
    );
  }
}

final class ShimmerRecentFilesRow extends StatelessWidget {
  final int itemCount;

  const ShimmerRecentFilesRow({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      children: List.generate(itemCount, (_) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(100),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              _shimmerGradient(
                context,
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _shimmerBase(context),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerText(width: 160, height: 14),
                    SizedBox(height: AppSpacing.xxs),
                    ShimmerText(width: 100, height: 12),
                  ],
                ),
              ),
              const ShimmerText(width: 36, height: 12),
              const SizedBox(width: AppSpacing.sm),
              _shimmerGradient(
                context,
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _shimmerBase(context),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}

final class ShimmerOverlay extends StatelessWidget {
  final String message;

  const ShimmerOverlay({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      color: (isLight ? AppColors.lightBackground : AppColors.darkBackground).withAlpha(200),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _shimmerGradient(
              context,
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _shimmerBase(context),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _shimmerGradient(
              context,
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: _shimmerBase(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
