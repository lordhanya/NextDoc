import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/typography.dart';

final class AnimatedToolCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback? onTap;

  const AnimatedToolCard({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.onTap,
  });

  @override
  State<AnimatedToolCard> createState() => _AnimatedToolCardState();
}

final class _AnimatedToolCardState extends State<AnimatedToolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.cardVariant : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _isHovered
                ? AppColors.primary.withAlpha(60)
                : AppColors.border.withAlpha(60),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.primaryContainer
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                widget.icon,
                size: 24,
                color: _isHovered
                    ? AppColors.primary
                    : AppColors.iconColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.label,
              style: AppTextStyles.buttonSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
