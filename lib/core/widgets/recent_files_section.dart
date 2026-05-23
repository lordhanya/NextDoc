import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../database/recent_file_entity.dart';
import '../providers/recent_files_provider.dart';
import '../theme/typography.dart';
import 'empty_state_widget.dart';
import 'glass_card.dart';
import 'pdf_thumbnail_card.dart';
import 'section_title.dart';

enum RecentFilesDisplayMode { list, grid }

final class RecentFilesSection extends ConsumerWidget {
  final RecentFilesDisplayMode displayMode;
  final String? title;
  final EdgeInsetsGeometry? padding;

  const RecentFilesSection({
    super.key,
    this.displayMode = RecentFilesDisplayMode.list,
    this.title,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(recentFilesProvider);
    final files = filesAsync.valueOrNull ?? [];

    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.xxl,
            AppSpacing.screenPadding,
            0,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: title ?? 'Recent Files',
          ),
          if (files.isEmpty)
            const EmptyStateWidget(
              icon: LucideIcons.fileText,
              title: 'No recent files',
              subtitle: 'Files you process will appear here',
            )
          else
            displayMode == RecentFilesDisplayMode.grid
                ? _RecentFilesGrid(files: files)
                : _RecentFilesList(files: files),
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

final class _RecentFilesList extends ConsumerWidget {
  final List<RecentFileEntity> files;

  const _RecentFilesList({required this.files});

  String _formattedSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final file = files[index];
        return _RecentFileRow(
          file: file,
          formattedSize: _formattedSize(file.fileSize),
          formattedDate: _formatDate(file.createdAt),
        );
      },
    );
  }
}

final class _RecentFileRow extends StatelessWidget {
  final RecentFileEntity file;
  final String formattedSize;
  final String formattedDate;

  const _RecentFileRow({
    required this.file,
    required this.formattedSize,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push(
        '/pdf-detail',
        extra: {
          'filePath': file.filePath,
          'fileName': file.fileName,
          'fileSize': file.fileSize,
          'pageCount': file.pageCount > 0 ? file.pageCount : 1,
          'heroTag': 'pdf_list_${file.id}',
        },
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              LucideIcons.fileText,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '$formattedSize • $formattedDate',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (file.pageCount > 0)
            Text(
              '${file.pageCount} pg',
              style: AppTextStyles.label,
            ),
        ],
      ),
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
