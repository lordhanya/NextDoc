import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/typography.dart';

final class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'Search documents...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.border.withAlpha(80),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodySmall,
          prefixIcon: const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.textHint,
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          fillColor: Colors.transparent,
          filled: true,
        ),
      ),
    );
  }
}
