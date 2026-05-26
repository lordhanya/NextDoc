import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/recent_files_section.dart';

final class RecentPage extends StatelessWidget {
  const RecentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(
            child: RecentFilesSection(
              displayMode: RecentFilesDisplayMode.list,
              title: 'All Recent Files',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
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
          Text('Recent', style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Recently opened documents',
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
      child: CustomSearchBar(hintText: 'Search recent files...'),
    );
  }
}
