import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/theme/typography.dart';

final class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  static const _tools = [
    _ToolInfo(
      icon: LucideIcons.image,
      label: 'JPG to PDF',
      description: 'Convert images to PDF documents',
      route: '/tools/image-to-pdf',
      color: AppColors.iconImageToPdf,
    ),
    _ToolInfo(
      icon: LucideIcons.file_plus,
      label: 'Merge PDF',
      description: 'Combine multiple PDFs into one',
      route: '/tools/merge',
      color: AppColors.iconMerge,
    ),
    _ToolInfo(
      icon: LucideIcons.minimize,
      label: 'Compress PDF',
      description: 'Reduce PDF file size efficiently',
      route: '/tools/compress',
      color: AppColors.iconCompress,
    ),
    _ToolInfo(
      icon: LucideIcons.scissors,
      label: 'Split PDF',
      description: 'Extract or split PDF pages',
      route: '/tools/split',
      color: AppColors.iconSplit,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.xxl,
              AppSpacing.screenPadding,
              AppSpacing.xxxl,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ToolCard(tool: _tools[index]),
                childCount: _tools.length,
              ),
            ),
          ),
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
          Text('Tools', style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'All the tools you need',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

final class _ToolInfo {
  final IconData icon;
  final String label;
  final String description;
  final String route;
  final Color color;

  const _ToolInfo({
    required this.icon,
    required this.label,
    required this.description,
    required this.route,
    required this.color,
  });
}

final class _ToolCard extends StatefulWidget {
  final _ToolInfo tool;

  const _ToolCard({required this.tool});

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

final class _ToolCardState extends State<_ToolCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? AppColors.lightSurface1 : AppColors.darkSurface2;
    final pressedBg = isLight ? AppColors.lightSurface2 : AppColors.darkSurface3;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        context.push(tool.route);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        curve: Curves.easeOut,
        transform: _isPressed ? (Matrix4.identity()..scaleByDouble(0.97, 0.97, 0.97, 1.0)) : Matrix4.identity(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: _isPressed ? pressedBg : cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _isPressed
                ? tool.color.withAlpha(80)
                : (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(80),
            width: 0.5,
          ),
          boxShadow: _isPressed ? null : DesignTokens.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: DesignTokens.durationNormal,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (_isPressed ? tool.color : tool.color).withAlpha(20),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                tool.icon,
                size: 24,
                color: _isPressed ? tool.color : tool.color.withAlpha(200),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              tool.label,
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: Text(
                tool.description,
                style: AppTextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
