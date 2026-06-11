import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/recent_files_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/typography.dart';

final class PdfToImageScreen extends ConsumerStatefulWidget {
  const PdfToImageScreen({super.key});

  @override
  ConsumerState<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

final class _PdfToImageScreenState extends ConsumerState<PdfToImageScreen> {
  final _filePicker = FilePickerService();
  String? _filePath;
  String? _fileName;
  int? _fileSize;
  int? _pageCount;
  Set<int> _selectedPages = {};
  bool _selectAll = true;

  ExportQuality _selectedQuality = ExportQuality.standard;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _selectedQuality = ref.read(settingsProvider).exportQuality;
    }
  }

  Future<void> _pickFile() async {
    final file = await _filePicker.pickPdf();
    if (!mounted) return;
    if (file == null) return;

    setState(() {
      _filePath = file.filePath;
      _fileName = file.fileName;
      _fileSize = file.fileSize;
      _pageCount = null;
      _selectedPages = {};
      _selectAll = true;
    });

    final metadata = await ref.read(pdfMetadataProvider(file.filePath).future);
    if (!mounted) return;
    if (metadata != null) {
      setState(() => _pageCount = metadata.pageCount);
      if (metadata.pageCount > 0) {
        _selectedPages = Set.from(List.generate(metadata.pageCount, (i) => i));
      }
    }
  }

  void _togglePage(int index) {
    setState(() {
      if (_selectedPages.contains(index)) {
        _selectedPages.remove(index);
        _selectAll = false;
      } else {
        _selectedPages.add(index);
        if (_selectedPages.length == _pageCount) {
          _selectAll = true;
        }
      }
    });
  }

  void _toggleSelectAll() {
    if (_pageCount == null) return;
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedPages = Set.from(List.generate(_pageCount!, (i) => i));
      } else {
        _selectedPages = {};
      }
    });
  }

  void _startExport() {
    if (_filePath == null || _filePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a PDF file')),
      );
      return;
    }

    if (_selectedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one page')),
      );
      return;
    }

    context.push('/processing', extra: {
      'type': 'pdf_to_image',
      'filePath': _filePath,
      'fileName': _fileName,
      'fileSize': _fileSize,
      'pageCount': _pageCount,
      'selectedPages': _selectedPages.toList(),
      'exportQuality': _selectedQuality.name,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accentColor = AppColors.iconPdfToJpg;

    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('PDF to JPG', style: AppTextStyles.title),
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
                    _buildFileSection(isLight, accentColor),
                    if (_filePath != null && _pageCount != null) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildPageSection(isLight, accentColor),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildQualitySection(accentColor),
                    ],
                  ],
                ),
              ),
            ),
            if (_filePath != null)
              _buildBottomBar(isLight),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSection(bool isLight, Color accent) {
    if (_filePath == null) {
      return _buildEmptyPicker(isLight, accent);
    }
    return _buildFileInfo(isLight, accent);
  }

  Widget _buildEmptyPicker(bool isLight, Color accent) {
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
                color: accent.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.file_image,
                size: 32,
                color: accent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Select PDF File', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose a PDF to export pages as JPG images',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(LucideIcons.file_up, size: 18),
              label: const Text('Select PDF File'),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
                side: BorderSide(color: accent.withAlpha(60)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo(bool isLight, Color accent) {
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
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withAlpha(15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  LucideIcons.file_text,
                  size: 24,
                  color: accent.withAlpha(200),
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

  Widget _buildPageSection(bool isLight, Color accent) {
    final totalPages = _pageCount ?? 0;
    final selectedCount = _selectedPages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Select Pages', style: AppTextStyles.titleSmall),
            const Spacer(),
            Text(
              '$selectedCount of $totalPages',
              style: AppTextStyles.titleSmall.copyWith(
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _SelectAllChip(
              isLight: isLight,
              isSelected: _selectAll,
              accent: accent,
              onTap: _toggleSelectAll,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.72,
          ),
          itemCount: totalPages,
          itemBuilder: (context, index) {
            final isSelected = _selectedPages.contains(index);
            return _PageTile(
              index: index,
              isSelected: isSelected,
              filePath: _filePath!,
              onToggle: () => _togglePage(index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQualitySection(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Export Quality', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Higher quality = larger file size',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        _QualityCard(
          title: 'Standard',
          subtitle: 'Good quality, moderate file size',
          icon: LucideIcons.image,
          isSelected: _selectedQuality == ExportQuality.standard,
          accent: accent,
          onTap: () => setState(() => _selectedQuality = ExportQuality.standard),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QualityCard(
          title: 'High Quality',
          subtitle: 'Best quality, larger files',
          icon: LucideIcons.maximize,
          isSelected: _selectedQuality == ExportQuality.highQuality,
          accent: accent,
          onTap: () => setState(() => _selectedQuality = ExportQuality.highQuality),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QualityCard(
          title: 'Small Size',
          subtitle: 'Smallest file size, lower quality',
          icon: LucideIcons.minimize,
          isSelected: _selectedQuality == ExportQuality.smallSize,
          accent: accent,
          onTap: () => setState(() => _selectedQuality = ExportQuality.smallSize),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isLight) {
    final enabled = _filePath != null && _selectedPages.isNotEmpty;

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
          label: enabled
              ? 'Export ${_selectedPages.length} page${_selectedPages.length > 1 ? "s" : ""}'
              : 'Select a File First',
          isEnabled: enabled,
          accent: AppColors.iconPdfToJpg,
          onTap: _startExport,
        ),
      ),
    );
  }

  String _formattedSize(int? bytes) {
    if (bytes == null) return '--';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

final class _SelectAllChip extends StatelessWidget {
  final bool isLight;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _SelectAllChip({
    required this.isLight,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withAlpha(15)
              : (isLight ? AppColors.lightSurface2 : AppColors.darkSurface2),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? accent.withAlpha(100)
                : (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 16,
              color: isSelected ? accent : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              isSelected ? 'Deselect All' : 'Select All',
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? accent
                    : (isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PageTile extends ConsumerStatefulWidget {
  final int index;
  final bool isSelected;
  final String filePath;
  final VoidCallback onToggle;

  const _PageTile({
    required this.index,
    required this.isSelected,
    required this.filePath,
    required this.onToggle,
  });

  @override
  ConsumerState<_PageTile> createState() => _PageTileState();
}

final class _PageTileState extends ConsumerState<_PageTile> {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = AppColors.iconPdfToJpg;
    final isSelected = widget.isSelected;
    final index = widget.index;

    final thumbnailAsync = ref.watch(pageThumbnailProvider((widget.filePath, index)));

    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? accent.withAlpha(12) : (isLight ? AppColors.lightSurface1 : AppColors.darkSurface2),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? accent.withAlpha(150)
                : (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md - 1)),
                child: thumbnailAsync.when(
                  loading: () => Container(
                    color: (isLight ? AppColors.lightSurface2 : AppColors.darkSurface2).withAlpha(180),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, _) => Container(
                    color: (isLight ? AppColors.lightSurface2 : AppColors.darkSurface2).withAlpha(180),
                    child: Center(
                      child: Icon(
                        LucideIcons.file_text,
                        size: 20,
                        color: (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(120),
                      ),
                    ),
                  ),
                  data: (bytes) {
                    if (bytes != null) {
                      return Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      );
                    }
                    return Container(
                      color: (isLight ? AppColors.lightSurface2 : AppColors.darkSurface2).withAlpha(180),
                      child: Center(
                        child: Icon(
                          LucideIcons.file_text,
                          size: 20,
                          color: (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(120),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xxs + 1,
                horizontal: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? accent.withAlpha(15) : Colors.transparent,
                border: Border(
                  top: BorderSide(
                    color: isSelected
                        ? accent.withAlpha(60)
                        : (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(30),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 14,
                    color: isSelected ? accent : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${index + 1}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? accent
                          : (isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _QualityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _QualityCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.accent,
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
              ? accent.withAlpha(15)
              : isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? accent
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
                    ? accent.withAlpha(25)
                    : isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? accent
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
                          ? accent
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
                  color: accent,
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
  final Color accent;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isEnabled,
    required this.accent,
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
        widget.isEnabled ? widget.accent : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(60);

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
