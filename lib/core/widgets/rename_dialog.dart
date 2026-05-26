import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../services/file_management_service.dart';
import '../theme/typography.dart';

Future<bool?> showRenameDialog({
  required BuildContext context,
  required String currentName,
  required String filePath,
}) {
  final nameWithoutExt = currentName.endsWith('.pdf')
      ? currentName.substring(0, currentName.length - 4)
      : currentName;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => _RenameDialog(
      currentName: nameWithoutExt,
      filePath: filePath,
    ),
  );
}

final class _RenameDialog extends StatefulWidget {
  final String currentName;
  final String filePath;

  const _RenameDialog({
    required this.currentName,
    required this.filePath,
  });

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

final class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.currentName.length - (widget.currentName.endsWith('.pdf') ? 4 : 0),
    );
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      setState(() => _errorText = 'File name cannot be empty');
      return;
    }

    if (newName == widget.currentName) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final result = await FileManagementService.renamePdf(
      filePath: widget.filePath,
      newName: newName,
    );

    if (!mounted) return;

    switch (result) {
      case FileManagementResult.success:
        Navigator.of(context).pop(true);
      case FileManagementResult.invalidName:
        setState(() {
          _errorText = 'Invalid file name';
          _isLoading = false;
        });
      case FileManagementResult.fileNotFound:
        setState(() {
          _errorText = 'File not found';
          _isLoading = false;
        });
      case FileManagementResult.alreadyExists:
        setState(() {
          _errorText = 'A file with this name already exists';
          _isLoading = false;
        });
      case FileManagementResult.error:
        setState(() {
          _errorText = 'Failed to rename file';
          _isLoading = false;
        });
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  LucideIcons.pencil,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Rename File', style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Enter file name',
              hintStyle: AppTextStyles.bodySmall,
              errorText: _errorText,
              suffixText: '.pdf',
              suffixStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              filled: true,
              fillColor: AppColors.card,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Text('Rename'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
