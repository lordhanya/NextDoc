import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/file_action_service.dart';
import '../../../core/services/image_action_service.dart';
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final extra = GoRouterState.of(context).extra;

    String filePath = '';
    String fileName = 'document.pdf';
    int fileSize = 0;
    int pageCount = 0;
    String toolName = '';
    int originalSize = 0;
    int fileCount = 0;
    String saveFolder = '';

    String type = '';

    List<String> imagePaths = [];

    if (extra is Map) {
      filePath = (extra['filePath'] as String?) ?? '';
      fileName = (extra['fileName'] as String?) ?? 'document.pdf';
      fileSize = (extra['fileSize'] as int?) ?? 0;
      pageCount = (extra['pageCount'] as int?) ?? 0;
      toolName = (extra['toolName'] as String?) ?? '';
      originalSize = (extra['originalSize'] as int?) ?? 0;
      fileCount = (extra['fileCount'] as int?) ?? 0;
      type = (extra['type'] as String?) ?? '';
      imagePaths = (extra['imagePaths'] as List?)?.cast<String>() ?? [];
      saveFolder = (extra['saveFolder'] as String?) ?? '';
    }

    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.darkBackground,
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
                toolName.isNotEmpty
                    ? toolName
                    : filePath.isNotEmpty
                        ? 'JPG to PDF'
                        : 'PDF Tool',
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              if (filePath.isNotEmpty)
                _buildFileInfo(isLight, fileName, fileSize, pageCount, originalSize, fileCount, type),
              const Spacer(flex: 2),
               _SuccessActions(filePath: filePath, fileName: fileName, type: type, imagePaths: imagePaths, saveFolder: saveFolder),
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

  Widget _buildFileInfo(
    bool isLight,
    String fileName,
    int fileSize,
    int pageCount,
    int originalSize,
    int fileCount,
    String type,
  ) {
    final isPdfToImage = type == 'pdf_to_image';
    final isCompressed = originalSize > 0;
    final isSplit = fileCount > 0 && !isPdfToImage;
    final savings = isCompressed
        ? ((originalSize - fileSize) / originalSize * 100)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          if (isPdfToImage) ...[
            _infoRow(isLight, 'Images Created', '$pageCount'),
            const SizedBox(height: AppSpacing.md),
            _infoRow(isLight, 'Total Size', _formattedSize(fileSize)),
          ] else if (isSplit) ...[
            _infoRow(isLight, 'Files Created', '$fileCount'),
            const SizedBox(height: AppSpacing.md),
            _infoRow(isLight, 'Total Pages', '$pageCount'),
            if (fileSize > 0) ...[
              const SizedBox(height: AppSpacing.md),
              _infoRow(isLight, 'Total Size', _formattedSize(fileSize)),
            ],
          ] else ...[
            _infoRow(isLight, 'File Name', fileName),
            if (isCompressed) ...[
              const SizedBox(height: AppSpacing.md),
              _infoRow(isLight, 'Original Size', _formattedSize(originalSize)),
            ],
            const SizedBox(height: AppSpacing.md),
            _infoRow(
              isLight,
              isCompressed ? 'Compressed Size' : 'Size',
              _formattedSize(fileSize),
            ),
            if (isCompressed) ...[
              const SizedBox(height: AppSpacing.md),
              _infoRow(
                isLight,
                'You Saved',
                '${savings.toStringAsFixed(1)}%',
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _infoRow(isLight, 'Pages', '$pageCount'),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(bool isLight, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
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
  final String type;
  final List<String> imagePaths;
  final String saveFolder;

  const _SuccessActions({
    required this.filePath,
    required this.fileName,
    this.type = '',
    this.imagePaths = const [],
    this.saveFolder = '',
  });

  @override
  State<_SuccessActions> createState() => _SuccessActionsState();
}

final class _SuccessActionsState extends State<_SuccessActions> {
  bool _isOpening = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    if (widget.saveFolder.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final isImage = widget.type == 'pdf_to_image';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isImage ? "JPG files" : "PDF file"} saved in ${widget.saveFolder}',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
  }

  Future<void> _openFile() async {
    setState(() => _isOpening = true);
    if (widget.type == 'pdf_to_image') {
      await ImageActionService.openImage(context, widget.filePath, widget.imagePaths);
    } else {
      await FileActionService.openPdf(context, widget.filePath);
    }
    if (mounted) setState(() => _isOpening = false);
  }

  Future<void> _shareFile() async {
    setState(() => _isSharing = true);
    if (widget.type == 'pdf_to_image') {
      await ImageActionService.shareImages(context, widget.imagePaths);
    } else {
      await FileActionService.sharePdf(context, widget.filePath, widget.fileName);
    }
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isPdfToImage = widget.type == 'pdf_to_image';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _ActionButton(
            label: isPdfToImage ? 'Open Images' : 'Open PDF',
            icon: isPdfToImage ? Icons.image_rounded : Icons.open_in_new_rounded,
            isPrimary: true,
            isLoading: _isOpening,
            onTap: _openFile,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: _ActionButton(
            label: isPdfToImage ? 'Share Images' : 'Share PDF',
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
              color: isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
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
                : (isLight ? AppColors.lightSurface1 : AppColors.darkSurface2),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(100),
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
                            : (isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        widget.label,
                        style: AppTextStyles.button.copyWith(
                          color: widget.isPrimary
                              ? AppColors.onPrimary
                              : (isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary),
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
