import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';

final class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.width,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: borderColor ?? AppColors.border.withAlpha(80),
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}
