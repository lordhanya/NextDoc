import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/recent_files_provider.dart';
import '../../core/services/file_action_service.dart';
import '../../core/services/file_management_service.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/delete_confirm_dialog.dart';
import '../../core/widgets/file_action_sheet.dart';
import '../../core/widgets/rename_dialog.dart';

final class PdfDetailScreen extends StatelessWidget {
  final String filePath;
  final String fileName;
  final int fileSize;
  final int pageCount;
  final String heroTag;

  const PdfDetailScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
    required this.heroTag,
  });

  String _formattedSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          fileName,
          style: AppTextStyles.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) => _MoreMenuButton(
              filePath: filePath,
              fileName: fileName,
              fileSize: fileSize,
              pageCount: pageCount,
              ref: ref,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreview(context),
              const SizedBox(height: AppSpacing.xxl),
              _buildInfoSection(context),
              const SizedBox(height: AppSpacing.xxl),
              _ActionsRow(filePath: filePath, fileName: fileName),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Hero(
        tag: heroTag,
        child: Container(
          width: double.infinity,
          height: 280,
          color: AppColors.surfaceVariant,
          child: _buildPageView(),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      itemCount: pageCount.clamp(1, 10),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                size: 64,
                color: AppColors.textHint.withAlpha(80),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Page ${index + 1} of ${pageCount.clamp(1, 10)}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.border.withAlpha(60),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _infoRow(LucideIcons.file_text, 'File Name', fileName),
          const SizedBox(height: AppSpacing.md),
          _infoRow(LucideIcons.file, 'Size', _formattedSize(fileSize)),
          const SizedBox(height: AppSpacing.md),
          _infoRow(LucideIcons.layers, 'Pages', '$pageCount'),
          const SizedBox(height: AppSpacing.md),
          _infoRow(
            LucideIcons.calendar,
            'Created',
            _formatDate(File(filePath).statSync().modified),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: AppTextStyles.caption),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

final class _MoreMenuButton extends StatelessWidget {
  final String filePath;
  final String fileName;
  final int fileSize;
  final int pageCount;
  final WidgetRef ref;

  const _MoreMenuButton({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
    required this.ref,
  });

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
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.ellipsis_vertical, color: AppColors.textHint),
      onPressed: () => _showActions(context),
    );
  }
}

final class _ActionsRow extends StatefulWidget {
  final String filePath;
  final String fileName;

  const _ActionsRow({
    required this.filePath,
    required this.fileName,
  });

  @override
  State<_ActionsRow> createState() => _ActionsRowState();
}

final class _ActionsRowState extends State<_ActionsRow> {
  bool _isSharing = false;
  bool _isOpening = false;

  Future<void> _openFile() async {
    setState(() => _isOpening = true);
    await FileActionService.openPdf(context, widget.filePath);
    if (mounted) setState(() => _isOpening = false);
  }

  Future<void> _shareFile() async {
    setState(() => _isSharing = true);
    await FileActionService.sharePdf(context, widget.filePath, widget.fileName);
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: LucideIcons.share_2,
            label: 'Share',
            isLoading: _isSharing,
            onTap: _isSharing ? null : _shareFile,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionChip(
            icon: LucideIcons.eye,
            label: 'Open',
            isPrimary: true,
            isLoading: _isOpening,
            onTap: _isOpening ? null : _openFile,
          ),
        ),
      ],
    );
  }
}

final class _ActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

final class _ActionChipState extends State<_ActionChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.isLoading;

    return GestureDetector(
      onTapDown: (isLoading || widget.onTap == null)
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: (isLoading || widget.onTap == null)
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? AppColors.primary
                : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: AppColors.border.withAlpha(100),
                    width: 0.5,
                  ),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 18,
                        color: widget.isPrimary
                            ? AppColors.onPrimary
                            : AppColors.textPrimary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        widget.label,
                        style: AppTextStyles.button.copyWith(
                          color: widget.isPrimary
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
