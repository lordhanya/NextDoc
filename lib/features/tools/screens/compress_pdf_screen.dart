import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/recent_files_provider.dart';
import '../../../core/services/compress_pdf_service.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/glass_card.dart';

final class CompressPdfScreen extends ConsumerStatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  ConsumerState<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

final class _CompressPdfScreenState extends ConsumerState<CompressPdfScreen> {
  final _filePicker = FilePickerService();
  final _pdfService = PdfService();
  String? _filePath;
  String? _fileName;
  int? _fileSize;
  int? _pageCount;
  CompressionLevel _selectedLevel = CompressionLevel.medium;

  Future<void> _pickFile() async {
    final file = await _filePicker.pickPdf();
    if (!mounted) return;
    if (file == null) return;

    setState(() {
      _filePath = file.filePath;
      _fileName = file.fileName;
      _fileSize = file.fileSize;
      _pageCount = null;
    });

    final metadata = await _pdfService.getMetadata(file.filePath);
    if (!mounted) return;
    if (metadata != null) {
      setState(() => _pageCount = metadata.pageCount);
    }
  }

  String _generateOutputFileName() {
    final now = DateTime.now();
    final ts = '${now.year}${_pad(now.month)}${_pad(now.day)}_'
        '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final base = _fileName?.replaceAll('.pdf', '') ?? 'document';
    return '${base}_compressed_$ts.pdf';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _startCompress() {
    if (_filePath == null || _filePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a PDF file')),
      );
      return;
    }

    final outputName = _generateOutputFileName();

    context.push('/processing', extra: {
      'type': 'compress',
      'path': _filePath,
      'fileName': outputName,
      'compressionLevel': _selectedLevel.name,
      'originalSize': _fileSize,
      'pageCount': _pageCount,
    });
  }

  String _formattedSize(int? bytes) {
    if (bytes == null) return '--';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Compress PDF', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFileSection(isLight),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildLevelSelector(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(isLight),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSection(bool isLight) {
    if (_filePath == null) {
      return _buildEmptyPicker(isLight);
    }
    return _buildFileInfo(isLight);
  }

  Widget _buildEmptyPicker(bool isLight) {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxxl + AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(100),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.file_up,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Select PDF File', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose a PDF to reduce its file size',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo(bool isLight) {
    final thumbnailAsync = ref.watch(pageThumbnailProvider((_filePath!, 0)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Selected File', style: AppTextStyles.titleSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(LucideIcons.refresh_cw, size: 16),
              label: const Text('Change'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: thumbnailAsync.when(
                    data: (bytes) {
                      if (bytes != null) {
                        return Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        );
                      }
                      return _pdfIcon(isLight);
                    },
                    loading: () => _pdfIcon(isLight),
                    error: (_, _) => _pdfIcon(isLight),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? '',
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${_formattedSize(_fileSize)}  ·  ${_pageCount != null ? "$_pageCount page${_pageCount! > 1 ? "s" : ""}" : "Loading..."}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pdfIcon(bool isLight) {
    return Container(
      color: isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
      child: Icon(
        LucideIcons.file_text,
        size: 28,
        color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Compression Level', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Higher compression = smaller file, lower quality',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        _LevelCard(
          icon: LucideIcons.maximize,
          title: 'High Quality',
          subtitle: 'Minimal size reduction, best quality',
          isSelected: _selectedLevel == CompressionLevel.low,
          onTap: () => setState(() => _selectedLevel = CompressionLevel.low),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LevelCard(
          icon: LucideIcons.move_horizontal,
          title: 'Balanced',
          subtitle: 'Good balance of size and quality',
          isSelected: _selectedLevel == CompressionLevel.medium,
          onTap: () => setState(() => _selectedLevel = CompressionLevel.medium),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LevelCard(
          icon: LucideIcons.minimize,
          title: 'Maximum',
          subtitle: 'Smallest file size, lower quality',
          isSelected: _selectedLevel == CompressionLevel.high,
          onTap: () => setState(() => _selectedLevel = CompressionLevel.high),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isLight) {
    final enabled = _filePath != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface1,
        border: Border(
          top: BorderSide(
            color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: _PrimaryButton(
          label: enabled ? 'Compress PDF' : 'Select a File First',
          isEnabled: enabled,
          onTap: _startCompress,
        ),
      ),
    );
  }
}

final class _LevelCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(15)
              : isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlpha(25)
                    : isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _PrimaryButton extends StatefulWidget {
  final String label;
  final bool isEnabled;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

final class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final effectiveColor =
        widget.isEnabled ? AppColors.primary : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(60);

    return GestureDetector(
      onTapDown: widget.isEnabled
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 4),
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTextStyles.button.copyWith(
                color: widget.isEnabled
                    ? AppColors.onPrimary
                    : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(120),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
