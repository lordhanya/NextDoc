import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/selected_file_model.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/services/metadata_service.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../editor_studio/models/editor_result.dart';
import '../../editor_studio/screens/unified_editor_screen.dart';

final class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  ConsumerState<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

final class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen> {
  final _filePicker = FilePickerService();
  final _images = <_ImageItem>[];

  Future<void> _pickImages() async {
    debugPrint('=== JPG→PDF Picker ===');
    debugPrint('Picker opened');
    debugPrint('Picker type: FileType.image');
    debugPrint('Allowed extensions: none (built-in image filter)');
    List<SelectedFileModel> files;
    try {
      files = await _filePicker.pickImages();
      debugPrint('Selected file count: ${files.length}');
    } catch (e) {
      debugPrint('Picker threw exception: $e');
      return;
    }
    if (!mounted) return;
    if (files.isEmpty) {
      debugPrint('Picker returned empty (user cancelled or error)');
      return;
    }

    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    debugPrint('Resolving paths for ${files.length} images');
    final items = <_ImageItem>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      var resolvedPath = file.filePath;
      var resolvedName = file.fileName;
      var resolvedSize = file.fileSize;

      if ((resolvedPath.isEmpty || !File(resolvedPath).existsSync()) && file.bytes != null) {
        final ext = file.fileType.isNotEmpty ? '.${file.fileType}' : '.jpg';
        resolvedName = resolvedName.isNotEmpty ? resolvedName : 'image_$i$ext';
        resolvedPath = '${tempDir.path}/nextdoc_img_${timestamp}_$i$ext';
        await File(resolvedPath).writeAsBytes(file.bytes!);
        resolvedSize = file.bytes!.length;
        debugPrint('  Wrote bytes -> $resolvedPath ($resolvedSize bytes)');
      }

      debugPrint('  file: path=$resolvedPath, name=$resolvedName, size=$resolvedSize');
      items.add(_ImageItem(
        path: resolvedPath,
        name: resolvedName,
        size: resolvedSize,
      ));
    }

    debugPrint('Updating state with ${items.length} images');
    setState(() {
      _images.addAll(items);
    });
    debugPrint('State updated, total images: ${_images.length}');
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

  Future<void> _editImages() async {
    if (_images.isEmpty) return;

    final tempPdf = File('${Directory.systemTemp.path}/nextdoc_edit_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await tempPdf.parent.create(recursive: true);

    try {
      final doc = MetadataService.createPdfDocument(
        title: 'Edit Images',
        subject: 'Temporary PDF for editing',
        keywords: 'NextDoc, Editor Studio',
      );
      for (final item in _images) {
        final bytes = await File(item.path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) continue;
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(decoded.width.toDouble(), decoded.height.toDouble()),
            margin: const pw.EdgeInsets.all(0),
            build: (ctx) => pw.Center(child: pw.Image(pw.MemoryImage(bytes))),
          ),
        );
      }
      await tempPdf.writeAsBytes(await doc.save());

      if (!mounted) return;
      EditorResult? result;
      await Navigator.of(context).push<EditorResult>(
        MaterialPageRoute(
          builder: (_) => UnifiedEditorScreen(
            initialPath: tempPdf.path,
            onSave: (r) => result = r,
          ),
        ),
      );

      if (result != null && mounted) {
        final editedDoc = await PdfDocument.openFile(result!.filePath);
        final newImages = <_ImageItem>[];
        for (var i = 0; i < editedDoc.pagesCount; i++) {
          final page = await editedDoc.getPage(i + 1);
          final render = await page.render(width: 1200, height: 1600, format: PdfPageImageFormat.jpeg, quality: 85);
          if (render == null) continue;
          final imgPath = '${Directory.systemTemp.path}/nextdoc_edit_img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          await File(imgPath).writeAsBytes(render.bytes);
          await page.close();
          final stat = await File(imgPath).stat();
          newImages.add(_ImageItem(path: imgPath, name: 'edited_page_${i + 1}.jpg', size: stat.size));
        }
        await editedDoc.close();

        setState(() {
          _images.clear();
          _images.addAll(newImages);
        });
      }

      try { await tempPdf.delete(); } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit failed: $e')));
      }
    }
  }

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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('JPG to PDF', style: AppTextStyles.title),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
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
          if (_images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                child: _PrimaryButton(
                  label: 'Edit Selected Images',
                  isEnabled: true,
                  onTap: _editImages,
                  isSecondary: true,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: _images.isEmpty
                  ? 'Select Images First'
                  : 'Convert ${_images.length} Image${_images.length > 1 ? 's' : ''} to PDF',
              isEnabled: _images.isNotEmpty,
              onTap: _startConversion,
            ),
          ),
        ],
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
    final isLight = Theme.of(context).brightness == Brightness.light;
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
                    color: isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
                    child: Icon(
                      LucideIcons.image,
                      size: 24,
                      color: (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(100),
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
                LucideIcons.trash_2,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Icon(
      Icons.drag_handle_rounded,
      size: 20,
      color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
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
  final bool isSecondary;

  const _PrimaryButton({
    required this.label,
    required this.isEnabled,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

final class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final effectiveColor = widget.isSecondary
        ? Colors.transparent
        : (widget.isEnabled ? AppColors.primary : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(60));
    final borderSide = widget.isSecondary
        ? BorderSide(color: AppColors.iconEditorStudio.withAlpha(80))
        : null;

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
            border: borderSide != null ? Border.all(color: AppColors.iconEditorStudio.withAlpha(80)) : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTextStyles.button.copyWith(
                color: widget.isEnabled
                    ? (widget.isSecondary ? AppColors.iconEditorStudio : AppColors.onPrimary)
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
