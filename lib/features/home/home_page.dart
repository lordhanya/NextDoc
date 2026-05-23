import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/animated_tool_card.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_title.dart';
import 'models/recent_file_model.dart';

final class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _quickTools = [
    (icon: LucideIcons.filePlus, label: 'Merge PDF'),
    (icon: LucideIcons.minimize, label: 'Compress PDF'),
    (icon: LucideIcons.image, label: 'JPG to PDF'),
    (icon: LucideIcons.scissors, label: 'Split PDF'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildQuickToolsSection(context)),
          SliverToBoxAdapter(child: _buildRecentSection(context)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          Text('NextDoc', style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Welcome back',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xxl,
        AppSpacing.screenPadding,
        0,
      ),
      child: CustomSearchBar(hintText: 'Search documents...'),
    );
  }

  Widget _buildQuickToolsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xxl,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: 'Quick Tools'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            itemCount: _quickTools.length,
            itemBuilder: (context, index) {
              final tool = _quickTools[index];
              return AnimatedToolCard(
                icon: tool.icon,
                label: tool.label,
                onTap: () {},
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xxl,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Recent Files',
            actionLabel: 'View all',
            onActionTap: () {},
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: fakeRecentFiles.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final file = fakeRecentFiles[index];
              return _RecentFileCard(file: file);
            },
          ),
        ],
      ),
    );
  }
}

final class _RecentFileCard extends StatelessWidget {
  final RecentFile file;

  const _RecentFileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {},
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: file.iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(file.icon, size: 22, color: file.iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${file.path} • ${file.size}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              file.formattedDate,
              style: AppTextStyles.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
