import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/recent_files_provider.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/glass_card.dart';

final class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<MergePdfScreen> createState() => _MergePdfScreenState();
}

final class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  final _filePicker = FilePickerService();
  final _pdfService = PdfService();
  final _files = <_PdfItem>[];

  Future<void> _pickFiles() async {
    final picked = await _filePicker.pickMultiplePdf();
    if (!mounted) return;
    if (picked.isEmpty) return;

    final existingPaths = _files.map((f) => f.path).toSet();
    final newItems = <_PdfItem>[];

    for (final file in picked) {
      if (existingPaths.contains(file.filePath)) continue;
      newItems.add(_PdfItem(
        path: file.filePath,
        name: file.fileName,
        size: file.fileSize,
      ));
    }

    setState(() => _files.addAll(newItems));

    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    for (var i = 0; i < _files.length; i++) {
      final item = _files[i];
      if (item.pageCount != null) continue;

      final metadata = await _pdfService.getMetadata(item.path);
      if (!mounted) return;

      setState(() {
        _files[i] = _PdfItem(
          path: item.path,
          name: item.name,
          size: item.size,
          pageCount: metadata?.pageCount,
        );
      });
    }
  }

  void _removeFile(int index) {
    setState(() => _files.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _files.removeAt(oldIndex);
      _files.insert(newIndex, item);
    });
  }

  String _generateOutputFileName() {
    final now = DateTime.now();
    final ts = '${now.year}${_pad(now.month)}${_pad(now.day)}_'
        '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    return 'Merged_$ts.pdf';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _startMerge() {
    if (_files.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 PDF files')),
      );
      return;
    }

    final paths = _files.map((e) => e.path).toList();
    final outputName = _generateOutputFileName();
    final totalPages = _files.fold<int>(0, (sum, f) => sum + (f.pageCount ?? 0));

    context.push('/processing', extra: {
      'type': 'merge',
      'paths': paths,
      'fileName': outputName,
      'pageCount': totalPages,
    });
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
        title: Text('Merge PDF', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _files.isEmpty
                  ? _buildEmptyState()
                  : _buildFileList(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl + AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.file_plus,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Select PDF Files',
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose 2 or more PDF files to merge\ninto a single document',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _ActionChip(
              icon: LucideIcons.plus,
              label: 'Pick PDF Files',
              onTap: _pickFiles,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            0,
          ),
          child: Row(
            children: [
              Text(
                '${_files.length} file${_files.length > 1 ? 's' : ''} selected',
                style: AppTextStyles.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            itemCount: _files.length,
            onReorder: _onReorder,
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                elevation: 4,
                shadowColor: AppColors.primary.withAlpha(60),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final item = _files[index];
              return _PdfFileCard(
                key: ValueKey(item.path),
                item: item,
                index: index,
                onDelete: () => _removeFile(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final pageCount = _files.fold<int>(0, (sum, f) => sum + (f.pageCount ?? 0));
    final enabled = _files.length >= 2;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_files.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_files.length} files',
                    style: AppTextStyles.caption,
                  ),
                  if (pageCount > 0) ...[
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '$pageCount total pages',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: enabled
                  ? 'Merge ${_files.length} Files'
                  : 'Select at Least 2 Files',
              isEnabled: enabled,
              onTap: _startMerge,
            ),
          ),
        ],
      ),
    );
  }
}

final class _PdfItem {
  final String path;
  final String name;
  final int size;
  final int? pageCount;

  const _PdfItem({
    required this.path,
    required this.name,
    required this.size,
    this.pageCount,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

final class _PdfFileCard extends ConsumerWidget {
  final _PdfItem item;
  final int index;
  final VoidCallback onDelete;

  const _PdfFileCard({
    super.key,
    required this.item,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final thumbnailAsync = ref.watch(pdfThumbnailProvider(item.path));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 56,
                height: 56,
                child: thumbnailAsync.when(
                  data: (bytes) {
                    if (bytes != null) {
                      return Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      );
                    }
                    return _pdfPlaceholder(isLight);
                  },
                  loading: () => _pdfPlaceholder(isLight),
                  error: (_, _) => _pdfPlaceholder(isLight),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${item.formattedSize}  ·  ${item.pageCount != null ? '${item.pageCount} page${item.pageCount! > 1 ? "s" : ""}' : "Loading..."}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                LucideIcons.trash_2,
                size: 18,
                color: AppColors.error,
              ),
              visualDensity: VisualDensity.compact,
            ),
            Icon(
              Icons.drag_handle_rounded,
              size: 20,
              color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfPlaceholder(bool isLight) {
    return Container(
      color: isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
      child: Icon(
        LucideIcons.file_text,
        size: 24,
        color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
      ),
    );
  }
}

final class _ActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

final class _ActionChipState extends State<_ActionChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md + 2,
          ),
          decoration: BoxDecoration(
            color: widget.isPrimary ? AppColors.primary : (isLight ? AppColors.lightSurface1 : AppColors.darkSurface2),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(100),
                    width: 0.5,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
