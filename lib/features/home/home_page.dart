import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/animated_tool_card.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/recent_files_section.dart';
import '../../core/widgets/section_title.dart';

final class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _quickTools = [
    (icon: LucideIcons.file_plus, label: 'Merge PDF', route: '/tools/merge'),
    (icon: LucideIcons.minimize, label: 'Compress PDF', route: '/tools/compress'),
    (icon: LucideIcons.image, label: 'JPG to PDF', route: '/tools/image-to-pdf'),
    (icon: LucideIcons.scissors, label: 'Split PDF', route: '/tools/split'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildQuickToolsSection(context)),
          SliverToBoxAdapter(
            child: RecentFilesSection(
              displayMode: RecentFilesDisplayMode.grid,
              title: 'Recent Files',
            ),
          ),
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
                onTap: () => context.push(tool.route),
              );
            },
          ),
        ],
      ),
    );
  }
}

