import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/file_action_service.dart';
import '../../../core/theme/typography.dart';

final class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  String _formattedSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;

    String filePath = '';
    String fileName = 'document.pdf';
    int fileSize = 0;
    int pageCount = 0;

    if (extra is Map) {
      filePath = (extra['filePath'] as String?) ?? '';
      fileName = (extra['fileName'] as String?) ?? 'document.pdf';
      fileSize = (extra['fileSize'] as int?) ?? 0;
      pageCount = (extra['pageCount'] as int?) ?? 0;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildSuccessIcon(),
              const SizedBox(height: AppSpacing.xxl),
              Text('Complete!', style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.sm),
              Text(
                filePath.isNotEmpty ? 'JPG to PDF' : 'PDF Tool',
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              if (filePath.isNotEmpty)
                _buildFileInfo(fileName, fileSize, pageCount),
              const Spacer(flex: 2),
              _SuccessActions(filePath: filePath, fileName: fileName),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl + AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.success.withAlpha(60),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 48,
        color: AppColors.success,
      ),
    );
  }

  Widget _buildFileInfo(String fileName, int fileSize, int pageCount) {
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
          _infoRow('File Name', fileName),
          const SizedBox(height: AppSpacing.md),
          _infoRow('Size', _formattedSize(fileSize)),
          const SizedBox(height: AppSpacing.md),
          _infoRow('Pages', '$pageCount'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

final class _SuccessActions extends StatefulWidget {
  final String filePath;
  final String fileName;

  const _SuccessActions({
    required this.filePath,
    required this.fileName,
  });

  @override
  State<_SuccessActions> createState() => _SuccessActionsState();
}

final class _SuccessActionsState extends State<_SuccessActions> {
  bool _isOpening = false;
  bool _isSharing = false;

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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _ActionButton(
            label: 'Open PDF',
            icon: Icons.open_in_new_rounded,
            isPrimary: true,
            isLoading: _isOpening,
            onTap: _openFile,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: _ActionButton(
            label: 'Share PDF',
            icon: Icons.share_rounded,
            isLoading: _isSharing,
            onTap: _shareFile,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: () => context.go('/home'),
          child: Text(
            'Back to Home',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

final class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

final class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.isLoading;

    return GestureDetector(
      onTapDown: isLoading ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isLoading ? null : (_) {
        setState(() => _isPressed = false);
        widget.onTap.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 4),
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
                    width: 20,
                    height: 20,
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
