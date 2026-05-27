import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/recent_files_provider.dart';
import '../../../core/services/file_management_service.dart';
import '../../../core/widgets/delete_confirm_dialog.dart';
import '../../../core/widgets/file_action_sheet.dart';
import '../../../core/widgets/rename_dialog.dart';

final class PdfAppBar extends StatelessWidget {
  final String filePath;
  final String fileName;
  final int fileSize;
  final int pageCount;
  final WidgetRef ref;
  final bool isReadingMode;
  final VoidCallback onReadingModeToggle;
  final VoidCallback onPageJump;
  final VoidCallback onBrightnessTap;

  const PdfAppBar({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
    required this.ref,
    this.isReadingMode = false,
    required this.onReadingModeToggle,
    required this.onPageJump,
    required this.onBrightnessTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        color: isLight
            ? AppColors.lightNavBackground
            : AppColors.darkNavBackground,
        border: Border(
          bottom: BorderSide(
            color: isLight
                ? AppColors.lightBorder.withAlpha(80)
                : AppColors.darkBorder.withAlpha(80),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  LucideIcons.arrow_left,
                  color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fileName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.search,
                  size: 20,
                  color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
                ),
                onPressed: onPageJump,
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.sun,
                  size: 20,
                  color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
                ),
                onPressed: onBrightnessTap,
              ),
              IconButton(
                icon: Icon(
                  isReadingMode ? LucideIcons.minimize_2 : LucideIcons.maximize_2,
                  size: 20,
                  color: isReadingMode
                      ? AppColors.primary
                      : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted),
                ),
                onPressed: onReadingModeToggle,
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.ellipsis_vertical,
                  color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
                ),
                onPressed: () => _showActions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showFileActionSheet(
      context: context,
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      pageCount: pageCount > 0 ? pageCount : 1,
      showOpen: false,
      showShare: false,
      onRename: () => _handleRename(context),
      onDuplicate: () => _handleDuplicate(context),
      onDelete: () => _handleDelete(context),
    );
  }

  Future<void> _handleRename(BuildContext context) async {
    final result = await showRenameDialog(
      context: context,
      currentName: fileName,
      filePath: filePath,
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

  Future<void> _handleDuplicate(BuildContext context) async {
    final r = await FileManagementService.duplicatePdf(filePath);
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

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      fileName: fileName,
      filePath: filePath,
    );
    if (confirmed) {
      refreshRecentFiles(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted')),
        );
        context.pop();
      }
    }
  }
}
