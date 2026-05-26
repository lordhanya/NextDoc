import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../services/file_management_service.dart';
import '../theme/typography.dart';

Future<bool> showDeleteConfirmDialog({
  required BuildContext context,
  required String fileName,
  required String filePath,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _DeleteConfirmDialog(
      fileName: fileName,
      filePath: filePath,
    ),
  ).then((v) => v ?? false);
}

final class _DeleteConfirmDialog extends StatefulWidget {
  final String fileName;
  final String filePath;

  const _DeleteConfirmDialog({
    required this.fileName,
    required this.filePath,
  });

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

final class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  bool _isDeleting = false;

  Future<void> _delete() async {
    setState(() => _isDeleting = true);

    final result = await FileManagementService.deletePdf(widget.filePath);

    if (!mounted) return;

    if (result == FileManagementResult.success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.xxl),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              LucideIcons.trash_2,
              size: 28,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Delete File',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Are you sure you want to delete "${widget.fileName}"? This action cannot be undone.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isDeleting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: _isDeleting ? null : _delete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md + 2,
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
