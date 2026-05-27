import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/design_tokens.dart';

final class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.width,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final defaultBg = isLight ? AppColors.lightSurface1 : AppColors.darkSurface2;
    final defaultBorder = isLight
        ? AppColors.lightBorder.withAlpha(120)
        : AppColors.darkBorder.withAlpha(100);
    final defaultShadow = isLight ? DesignTokens.shadowSm : <BoxShadow>[];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: backgroundColor ?? defaultBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: borderColor ?? defaultBorder,
            width: 0.5,
          ),
          boxShadow: boxShadow ?? defaultShadow,
        ),
        child: child,
      ),
    );
  }
}
