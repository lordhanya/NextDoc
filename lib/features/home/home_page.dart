import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/recent_files_provider.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/animated_tool_card.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/pdf_thumbnail_card.dart';
import '../../core/database/recent_file_entity.dart';

final class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _quickTools = [
    (icon: LucideIcons.filePlus, label: 'Merge PDF', route: '/tools/merge'),
    (icon: LucideIcons.minimize, label: 'Compress PDF', route: '/tools/compress'),
    (icon: LucideIcons.image, label: 'JPG to PDF', route: '/tools/image-to-pdf'),
    (icon: LucideIcons.scissors, label: 'Split PDF', route: '/tools/split'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentFilesAsync = ref.watch(recentFilesProvider);
    final files = recentFilesAsync.valueOrNull ?? [];

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildQuickToolsSection(context)),
          SliverToBoxAdapter(
            child: _buildRecentSection(context, ref, files),
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

  Widget _buildRecentSection(
    BuildContext context,
    WidgetRef ref,
    List<RecentFileEntity> files,
  ) {
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
            actionLabel: files.isEmpty ? null : 'View all',
            onActionTap: () {},
          ),
          if (files.isEmpty)
            const EmptyStateWidget(
              icon: LucideIcons.fileText,
              title: 'No recent files',
              subtitle: 'Files you process will appear here',
            )
          else
            _RecentFilesGrid(files: files),
        ],
      ),
    );
  }
}

final class _RecentFilesGrid extends ConsumerWidget {
  final List<RecentFileEntity> files;

  const _RecentFilesGrid({required this.files});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final heroTag = 'pdf_${file.id}';
        final thumbnailAsync = ref.watch(pdfThumbnailProvider(file.filePath));

        return thumbnailAsync.when(
          data: (bytes) => _FileCard(
            file: file,
            heroTag: heroTag,
            thumbnailBytes: bytes,
          ),
          loading: () => _FileCard(
            file: file,
            heroTag: heroTag,
            thumbnailBytes: null,
          ),
          error: (_, _) => _FileCard(
            file: file,
            heroTag: heroTag,
            thumbnailBytes: null,
          ),
        );
      },
    );
  }
}

final class _FileCard extends StatelessWidget {
  final RecentFileEntity file;
  final String heroTag;
  final Uint8List? thumbnailBytes;

  const _FileCard({
    required this.file,
    required this.heroTag,
    this.thumbnailBytes,
  });

  String _formattedSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return PdfThumbnailCard(
      heroTag: heroTag,
      thumbnailBytes: thumbnailBytes,
      fileName: file.fileName,
      fileSize: _formattedSize(file.fileSize),
      pageCount: file.pageCount > 0 ? file.pageCount : 1,
      onTap: () => context.push(
        '/pdf-detail',
        extra: {
          'filePath': file.filePath,
          'fileName': file.fileName,
          'fileSize': file.fileSize,
          'pageCount': file.pageCount > 0 ? file.pageCount : 1,
          'heroTag': heroTag,
        },
      ),
    );
  }
}
