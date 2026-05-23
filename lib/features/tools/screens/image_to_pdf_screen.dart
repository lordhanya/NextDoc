import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/glass_card.dart';

final class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  ConsumerState<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

final class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen> {
  final _filePicker = FilePickerService();
  final _images = <_ImageItem>[];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final files = await _filePicker.pickImages();
    if (!mounted) return;
    if (files.isEmpty) return;

    setState(() {
      for (final file in files) {
        _images.add(_ImageItem(
          path: file.filePath,
          name: file.fileName,
          size: file.fileSize,
        ));
      }
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  String _generateOutputFileName() {
    final now = DateTime.now();
    final ts = '${now.year}${_pad(now.month)}${_pad(now.day)}_'
        '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    return 'NextDoc_$ts.pdf';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _startConversion() {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one image')),
      );
      return;
    }

    final imagePaths = _images.map((e) => e.path).toList();
    final outputName = _generateOutputFileName();

    context.push('/processing', extra: {
      'type': 'image_to_pdf',
      'imagePaths': imagePaths,
      'fileName': outputName,
    });
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
        title: const Text('JPG to PDF', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _images.isEmpty
                  ? _buildEmptyState()
                  : _buildImageList(),
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
                LucideIcons.image,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Select Images',
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose JPG or PNG images to convert\ninto a single PDF document',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _ActionChip(
              icon: LucideIcons.plus,
              label: 'Pick Images',
              onTap: _pickImages,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageList() {
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
                '${_images.length} image${_images.length > 1 ? 's' : ''} selected',
                style: AppTextStyles.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickImages,
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
            itemCount: _images.length,
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
              final item = _images[index];
              return _ImagePreviewCard(
                key: ValueKey(item.path),
                item: item,
                index: index,
                onDelete: () => _removeImage(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withAlpha(60),
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: _PrimaryButton(
          label: _images.isEmpty
              ? 'Select Images First'
              : 'Convert ${_images.length} Image${_images.length > 1 ? 's' : ''} to PDF',
          isEnabled: _images.isNotEmpty,
          onTap: _startConversion,
        ),
      ),
    );
  }
}

final class _ImageItem {
  final String path;
  final String name;
  final int size;

  const _ImageItem({
    required this.path,
    required this.name,
    required this.size,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

final class _ImagePreviewCard extends StatelessWidget {
  final _ImageItem item;
  final int index;
  final VoidCallback onDelete;

  const _ImagePreviewCard({
    super.key,
    required this.item,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                child: Image.file(
                  File(item.path),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surfaceVariant,
                    child: Icon(
                      LucideIcons.image,
                      size: 24,
                      color: AppColors.textHint.withAlpha(100),
                    ),
                  ),
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
                    '${item.formattedSize} • Page ${index + 1}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                LucideIcons.trash2,
                size: 18,
                color: AppColors.error,
              ),
              visualDensity: VisualDensity.compact,
            ),
            const ReorderListenerDragHandle(),
          ],
        ),
      ),
    );
  }
}

final class ReorderListenerDragHandle extends StatelessWidget {
  const ReorderListenerDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.drag_handle_rounded,
      size: 20,
      color: AppColors.textHint,
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
            color: widget.isPrimary ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: AppColors.border.withAlpha(100),
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
    final effectiveColor =
        widget.isEnabled ? AppColors.primary : AppColors.textHint.withAlpha(60);

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
                    : AppColors.textHint.withAlpha(120),
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
