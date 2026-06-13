import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/theme/typography.dart';
import 'unified_editor_screen.dart';

final class EditorStudioScreen extends StatelessWidget {
  const EditorStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(isLight)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.xxl,
                AppSpacing.screenPadding,
                AppSpacing.xxxl,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _EditorOptionCard(
                      icon: Icons.image_rounded,
                      label: 'Edit Image',
                      description: 'Crop, rotate, filter, and enhance images',
                      color: AppColors.iconEditorStudio,
                      isLight: isLight,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UnifiedEditorScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _EditorOptionCard(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'Edit PDF',
                      description: 'Rotate, delete, reorder pages, and more',
                      color: AppColors.iconEditorStudio,
                      isLight: isLight,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UnifiedEditorScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLight) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.iconEditorStudio.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 22,
                  color: AppColors.iconEditorStudio,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Editor Studio', style: AppTextStyles.headline),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Crop, rotate, watermark, and organize your documents',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

final class _EditorOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isLight;
  final VoidCallback onTap;

  const _EditorOptionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: color.withAlpha(40),
            width: 1,
          ),
          boxShadow: DesignTokens.shadowMd,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(120),
            ),
          ],
        ),
      ),
    );
  }
}
