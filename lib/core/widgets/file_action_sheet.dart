import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/typography.dart';

enum FileAction { open, share, rename, duplicate, delete }

void showFileActionSheet({
  required BuildContext context,
  required String fileName,
  required String filePath,
  required int fileSize,
  required int pageCount,
  FileActionCallback? onOpen,
  FileActionCallback? onShare,
  required FileActionCallback onRename,
  required FileActionCallback onDuplicate,
  required FileActionCallback onDelete,
  bool showOpen = true,
  bool showShare = true,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _FileActionSheet(
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      pageCount: pageCount,
      onOpen: onOpen,
      onShare: onShare,
      onRename: onRename,
      onDuplicate: onDuplicate,
      onDelete: onDelete,
      showOpen: showOpen,
      showShare: showShare,
    ),
  );
}

typedef FileActionCallback = VoidCallback;

final class _FileActionSheet extends StatelessWidget {
  final String fileName;
  final String filePath;
  final int fileSize;
  final int pageCount;
  final FileActionCallback? onOpen;
  final FileActionCallback? onShare;
  final FileActionCallback onRename;
  final FileActionCallback onDuplicate;
  final FileActionCallback onDelete;
  final bool showOpen;
  final bool showShare;

  const _FileActionSheet({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.pageCount,
    this.onOpen,
    this.onShare,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.showOpen,
    required this.showShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xxl),
          topRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.xs,
            AppSpacing.screenPadding,
            AppSpacing.xxxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              const SizedBox(height: AppSpacing.sm),
              _buildHeader(),
              const SizedBox(height: AppSpacing.lg),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.sm),
              if (showOpen) _ActionTile(icon: LucideIcons.eye, label: 'Open', onTap: onOpen),
              if (showShare) _ActionTile(icon: LucideIcons.share_2, label: 'Share', onTap: onShare),
              _ActionTile(icon: LucideIcons.pencil, label: 'Rename', onTap: onRename),
              _ActionTile(icon: LucideIcons.copy, label: 'Duplicate', onTap: onDuplicate),
              const SizedBox(height: AppSpacing.xs),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.xs),
              _ActionTile(
                icon: LucideIcons.trash_2,
                label: 'Delete',
                isDestructive: true,
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.textHint.withAlpha(80),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            LucideIcons.file_text,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '$pageCount page${pageCount > 1 ? 's' : ''}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md + 2,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: AppTextStyles.body.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
