import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../database/recent_file_entity.dart';
import '../providers/recent_files_provider.dart';
import '../providers/search_provider.dart';
import '../services/file_action_service.dart';
import '../services/file_management_service.dart';
import '../services/image_action_service.dart';
import '../theme/typography.dart';
import 'delete_confirm_dialog.dart';
import 'empty_state_widget.dart';
import 'file_action_sheet.dart';
import 'glass_card.dart';
import 'pdf_thumbnail_card.dart';
import 'rename_dialog.dart';
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
    final filesAsync = ref.watch(filteredRecentFilesProvider);
    final query = ref.watch(searchQueryProvider);
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
          if (files.isEmpty && query.isNotEmpty)
            EmptyStateWidget(
              icon: LucideIcons.search,
              title: 'No matching files found',
              subtitle: 'No results for "$query"',
            )
          else if (files.isEmpty)
            const EmptyStateWidget(
              icon: LucideIcons.file_text,
              title: 'No recent files',
              subtitle: 'Files you process will appear here',
            )
          else
            displayMode == RecentFilesDisplayMode.grid
                ? _RecentFilesGrid(files: files, query: query)
                : _RecentFilesList(files: files, query: query),
        ],
      ),
    );
  }
}

final class _RecentFilesGrid extends ConsumerWidget {
  final List<RecentFileEntity> files;
  final String query;

  const _RecentFilesGrid({required this.files, required this.query});

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
        final isImage = file.fileType == 'image_export';

        if (isImage) {
          return _ImageFileCard(
            file: file,
            heroTag: heroTag,
            query: query,
          );
        }

        final thumbnailAsync = ref.watch(pageThumbnailProvider((file.filePath, 0)));

        return thumbnailAsync.when(
          data: (bytes) => _FileCard(
            file: file,
            heroTag: heroTag,
            thumbnailBytes: bytes,
            query: query,
          ),
          loading: () => _FileCard(
            file: file,
            heroTag: heroTag,
            thumbnailBytes: null,
            query: query,
          ),
          error: (_, _) => _FileCard(
            file: file,
            heroTag: heroTag,
            thumbnailBytes: null,
            query: query,
          ),
        );
      },
    );
  }
}

final class _RecentFilesList extends ConsumerWidget {
  final List<RecentFileEntity> files;
  final String query;

  const _RecentFilesList({required this.files, required this.query});

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
          query: query,
        );
      },
    );
  }
}

final class _RecentFileRow extends ConsumerWidget {
  final RecentFileEntity file;
  final String formattedSize;
  final String formattedDate;
  final String query;

  const _RecentFileRow({
    required this.file,
    required this.formattedSize,
    required this.formattedDate,
    required this.query,
  });

  bool get _isImage => file.fileType == 'image_export';

  void _showFileActions(BuildContext context, WidgetRef ref) {
    if (_isImage) {
      showFileActionSheet(
        context: context,
        fileName: file.fileName,
        filePath: file.filePath,
        fileSize: file.fileSize,
        pageCount: file.pageCount > 0 ? file.pageCount : 1,
        isImageFile: true,
        onOpen: () => ImageActionService.openImage(
          context,
          file.filePath,
          [file.filePath],
        ),
        onShare: () => ImageActionService.shareImages(
          context,
          [file.filePath],
        ),
        onRename: () => {},
        onDuplicate: () => {},
        onDelete: () => _handleDelete(context, ref),
      );
      return;
    }
    showFileActionSheet(
      context: context,
      fileName: file.fileName,
      filePath: file.filePath,
      fileSize: file.fileSize,
      pageCount: file.pageCount > 0 ? file.pageCount : 1,
      onOpen: () => context.push(
        '/pdf-viewer',
        extra: {
          'filePath': file.filePath,
          'fileName': file.fileName,
          'fileSize': file.fileSize,
          'pageCount': file.pageCount > 0 ? file.pageCount : 1,
          'heroTag': 'pdf_list_${file.id}',
        },
      ),
      onShare: () => FileActionService.sharePdf(context, file.filePath, file.fileName),
      onRename: () => _handleRename(context, ref),
      onDuplicate: () => _handleDuplicate(context, ref),
      onDelete: () => _handleDelete(context, ref),
    );
  }

  Future<void> _handleRename(BuildContext context, WidgetRef ref) async {
    final result = await showRenameDialog(
      context: context,
      currentName: file.fileName,
      filePath: file.filePath,
    );
    if (result == true) {
      refreshRecentFiles(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File renamed successfully')),
        );
      }
    }
  }

  Future<void> _handleDuplicate(BuildContext context, WidgetRef ref) async {
    final r = await FileManagementService.duplicatePdf(file.filePath);
    if (r.result == FileManagementResult.success) {
      refreshRecentFiles(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File duplicated successfully')),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to duplicate file')),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      fileName: file.fileName,
      filePath: file.filePath,
    );
    if (confirmed) {
      refreshRecentFiles(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final threeDotsBg = isLight ? AppColors.lightSurface2 : AppColors.darkSurface3;
    final threeDotsIcon = isLight ? AppColors.lightIconColor : AppColors.darkTextMuted;

    final defaultTextStyle = DefaultTextStyle.of(context).style;
    final fileNameStyle = defaultTextStyle.merge(AppTextStyles.titleSmall);
    final highlightStyle = fileNameStyle.copyWith(
      color: AppColors.primary,
      backgroundColor: AppColors.primary.withAlpha(30),
    );

    final iconBg = _isImage
        ? AppColors.iconPdfToJpg.withAlpha(25)
        : AppColors.primary.withAlpha(25);
    final iconColor = _isImage ? AppColors.iconPdfToJpg : AppColors.primary;
    final iconData = _isImage ? LucideIcons.image : LucideIcons.file_text;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: _isImage
          ? () => ImageActionService.openImage(
                context,
                file.filePath,
                [file.filePath],
              )
          : () => context.push(
                '/pdf-viewer',
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
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              iconData,
              size: 22,
              color: iconColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: highlightText(
                    file.fileName,
                    query,
                    fileNameStyle,
                    highlightStyle,
                  ),
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
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                _isImage
                    ? '${file.pageCount} img'
                    : '${file.pageCount} pg',
                style: AppTextStyles.label,
              ),
            ),
          GestureDetector(
            onTap: () => _showFileActions(context, ref),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: threeDotsBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                LucideIcons.ellipsis,
                size: 18,
                color: threeDotsIcon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _FileCard extends ConsumerWidget {
  final RecentFileEntity file;
  final String heroTag;
  final Uint8List? thumbnailBytes;
  final String query;

  const _FileCard({
    required this.file,
    required this.heroTag,
    this.thumbnailBytes,
    required this.query,
  });

  String _formattedSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showFileActions(BuildContext context, WidgetRef ref) {
    showFileActionSheet(
      context: context,
      fileName: file.fileName,
      filePath: file.filePath,
      fileSize: file.fileSize,
      pageCount: file.pageCount > 0 ? file.pageCount : 1,
      onOpen: () => context.push(
        '/pdf-viewer',
        extra: {
          'filePath': file.filePath,
          'fileName': file.fileName,
          'fileSize': file.fileSize,
          'pageCount': file.pageCount > 0 ? file.pageCount : 1,
          'heroTag': heroTag,
        },
      ),
      onShare: () => FileActionService.sharePdf(context, file.filePath, file.fileName),
      onRename: () => _handleRename(context, ref),
      onDuplicate: () => _handleDuplicate(context, ref),
      onDelete: () => _handleDelete(context, ref),
    );
  }

  Future<void> _handleRename(BuildContext context, WidgetRef ref) async {
    final result = await showRenameDialog(
      context: context,
      currentName: file.fileName,
      filePath: file.filePath,
    );
    if (result == true) {
      refreshRecentFiles(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File renamed successfully')),
        );
      }
    }
  }

  Future<void> _handleDuplicate(BuildContext context, WidgetRef ref) async {
    final r = await FileManagementService.duplicatePdf(file.filePath);
    if (r.result == FileManagementResult.success) {
      refreshRecentFiles(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File duplicated successfully')),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to duplicate file')),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      fileName: file.fileName,
      filePath: file.filePath,
    );
    if (confirmed) {
      refreshRecentFiles(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showFileActions(context, ref),
      child: PdfThumbnailCard(
        heroTag: heroTag,
        thumbnailBytes: thumbnailBytes,
        fileName: file.fileName,
        fileSize: _formattedSize(file.fileSize),
        pageCount: file.pageCount > 0 ? file.pageCount : 1,
        query: query,
        onTap: () => context.push(
          '/pdf-viewer',
          extra: {
            'filePath': file.filePath,
            'fileName': file.fileName,
            'fileSize': file.fileSize,
            'pageCount': file.pageCount > 0 ? file.pageCount : 1,
            'heroTag': heroTag,
          },
        ),
      ),
    );
  }
}

final class _ImageFileCard extends ConsumerWidget {
  final RecentFileEntity file;
  final String heroTag;
  final String query;

  const _ImageFileCard({
    required this.file,
    required this.heroTag,
    required this.query,
  });

  String _formattedSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showFileActions(BuildContext context, WidgetRef ref) {
    showFileActionSheet(
      context: context,
      fileName: file.fileName,
      filePath: file.filePath,
      fileSize: file.fileSize,
      pageCount: file.pageCount > 0 ? file.pageCount : 1,
      isImageFile: true,
      onOpen: () => ImageActionService.openImage(
        context,
        file.filePath,
        [file.filePath],
      ),
      onShare: () => ImageActionService.shareImages(
        context,
        [file.filePath],
      ),
      onRename: () => {},
      onDuplicate: () => {},
      onDelete: () => _handleDelete(context, ref),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      fileName: file.fileName,
      filePath: file.filePath,
    );
    if (confirmed) {
      refreshRecentFiles(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image export deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final captionStyle = DefaultTextStyle.of(context).style.merge(AppTextStyles.caption);
    final captionHighlight = captionStyle.copyWith(
      color: AppColors.primary,
      backgroundColor: AppColors.primary.withAlpha(30),
    );

    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: () => _showFileActions(context, ref),
        child: GlassCard(
          onTap: () => ImageActionService.openImage(
            context,
            file.filePath,
            [file.filePath],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Hero(
                  tag: heroTag,
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Image.file(
                      File(file.filePath),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(isLight),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RichText(
                text: highlightText(
                  file.fileName,
                  query,
                  captionStyle,
                  captionHighlight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  Text(
                    '${file.pageCount} image${file.pageCount > 1 ? "s" : ""}',
                    style: AppTextStyles.label,
                  ),
                  const Spacer(),
                  Text(_formattedSize(file.fileSize), style: AppTextStyles.label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(bool isLight) {
    final bg = isLight ? AppColors.lightSurface2 : AppColors.darkSurface2;
    final icon = isLight
        ? AppColors.lightTextMuted.withAlpha(100)
        : AppColors.darkTextMuted.withAlpha(100);
    return Container(
      color: bg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.image, size: 36, color: icon),
          const SizedBox(height: AppSpacing.xs),
          Text('Image', style: AppTextStyles.label),
        ],
      ),
    );
  }
}
