import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../editor_studio/models/editor_result.dart';
import '../../editor_studio/screens/unified_editor_screen.dart';

final class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

final class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _picker = ImagePicker();
  final _pages = <_ScanPage>[];
  int _selectedIndex = 0;
  bool _isLoading = false;

  Future<void> _capturePage() async {
    setState(() => _isLoading = true);
    try {
      final xfile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      if (!mounted) return;
      if (xfile == null) { setState(() => _isLoading = false); return; }
      setState(() {
        _isLoading = false;
        _pages.add(_ScanPage(path: xfile.path, rotation: 0));
        _selectedIndex = _pages.length - 1;
      });
    } catch (e) {
      debugPrint('Camera capture error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera failed: $e')),
        );
      }
    }
  }

  void _deletePage(int index) {
    final file = File(_pages[index].path);
    if (file.existsSync()) file.delete();
    setState(() {
      _pages.removeAt(index);
      if (_selectedIndex >= _pages.length) _selectedIndex = _pages.length - 1;
    });
  }

  void _rotatePage(int index) {
    setState(() {
      _pages[index].rotation = (_pages[index].rotation + 90) % 360;
    });
  }

  Future<void> _editPages() async {
    if (_pages.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    final tempPdf = File('${Directory.systemTemp.path}/nextdoc_scan_edit_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await tempPdf.parent.create(recursive: true);

    try {
      final doc = pw.Document();
      for (final page in _pages) {
        final bytes = await File(page.path).readAsBytes();
        var decoded = img.decodeImage(bytes);
        if (decoded == null) continue;

        if (page.rotation != 0) {
          decoded = img.copyRotate(decoded, angle: page.rotation);
        }

        final rotatedBytes = img.encodeJpg(decoded, quality: 90);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(decoded.width.toDouble(), decoded.height.toDouble()),
            margin: const pw.EdgeInsets.all(0),
            build: (ctx) => pw.Center(child: pw.Image(pw.MemoryImage(rotatedBytes))),
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
        final newPages = <_ScanPage>[];
        for (var i = 0; i < editedDoc.pagesCount; i++) {
          final page = await editedDoc.getPage(i + 1);
          final render = await page.render(width: 1200, height: 1600, format: PdfPageImageFormat.jpeg, quality: 85);
          if (render == null) continue;
          final imgPath = '${Directory.systemTemp.path}/nextdoc_scan_edit_img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          await File(imgPath).writeAsBytes(render.bytes);
          await page.close();
          newPages.add(_ScanPage(path: imgPath, rotation: 0));
        }
        await editedDoc.close();

        setState(() {
          _pages.clear();
          _pages.addAll(newPages);
          _selectedIndex = 0;
        });
      }

      try { await tempPdf.delete(); } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateOutputFileName() {
    final now = DateTime.now();
    final ts = '${now.year}${_pad(now.month)}${_pad(now.day)}_'
        '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    return 'Scan_$ts.pdf';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _startConversion() {
    if (_pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan at least one page')),
      );
      return;
    }

    final imagePaths = _pages.map((p) {
      final file = File(p.path);
      var bytes = file.readAsBytesSync();
      var decoded = img.decodeImage(bytes);
      if (decoded == null || p.rotation == 0) return p.path;

      decoded = img.copyRotate(decoded, angle: p.rotation);

      final rotatedPath = '${Directory.systemTemp.path}/nextdoc_scan_rotated_${DateTime.now().millisecondsSinceEpoch}_${_pages.indexOf(p)}.jpg';
      File(rotatedPath).writeAsBytesSync(img.encodeJpg(decoded, quality: 90));
      return rotatedPath;
    }).toList();

    final outputName = _generateOutputFileName();

    context.push('/processing', extra: {
      'type': 'image_to_pdf',
      'imagePaths': imagePaths,
      'fileName': outputName,
      'saveFolder': 'Scanned_Documents',
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
        title: Text('Scan Document', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _pages.isEmpty
                      ? _buildEmptyState()
                      : _buildPreview(),
                ),
                if (_pages.isNotEmpty) ...[
                  _buildThumbnailStrip(),
                  _buildActionButtons(),
                ],
                _buildBottomBar(),
              ],
            ),
            if (_isLoading)
              const ShimmerOverlay(message: 'Opening camera...'),
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
                LucideIcons.scan,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Scan Documents',
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Use your camera to capture documents\nand convert them to PDF',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _ScanActionChip(
              icon: LucideIcons.camera,
              label: 'Scan First Page',
              onTap: _capturePage,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final page = _pages[_selectedIndex];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: _RotatedImage(
            path: page.path,
            rotation: page.rotation,
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        itemCount: _pages.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final page = _pages[index];
          final isSelected = index == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm - 1),
                child: _RotatedImage(
                  path: page.path,
                  rotation: page.rotation,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ScanIconButton(
            icon: LucideIcons.plus,
            label: 'Add',
            onTap: _capturePage,
          ),
          const SizedBox(width: AppSpacing.md),
          _ScanIconButton(
            icon: LucideIcons.rotate_cw,
            label: 'Rotate',
            onTap: () => _rotatePage(_selectedIndex),
          ),
          const SizedBox(width: AppSpacing.md),
          _ScanIconButton(
            icon: LucideIcons.trash_2,
            label: 'Delete',
            color: AppColors.error,
            onTap: () => _deletePage(_selectedIndex),
          ),
          const SizedBox(width: AppSpacing.md),
          _ScanIconButton(
            icon: LucideIcons.pen_tool,
            label: 'Edit',
            onTap: _editPages,
          ),
        ],
      ),
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
      child: SizedBox(
        width: double.infinity,
        child: _ScanPrimaryButton(
          label: _pages.isEmpty
              ? 'Scan a Page First'
              : 'Convert ${_pages.length} Page${_pages.length > 1 ? 's' : ''} to PDF',
          isEnabled: _pages.isNotEmpty,
          onTap: _startConversion,
        ),
      ),
    );
  }
}

// ── Models ─────────────────────────────────────────────────────────────

final class _ScanPage {
  final String path;
  int rotation;

  _ScanPage({required this.path, required this.rotation});
}

// ── Rotated image widget ───────────────────────────────────────────────

final class _RotatedImage extends StatelessWidget {
  final String path;
  final int rotation;
  final BoxFit? fit;

  const _RotatedImage({required this.path, required this.rotation, this.fit});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    Widget image = Image.file(
      File(path),
      fit: fit ?? BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => Container(
        color: isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
        child: const Icon(LucideIcons.image, size: 32, color: AppColors.primary),
      ),
    );

    if (rotation != 0) {
      image = Transform.rotate(
        angle: rotation * 3.14159265 / 180,
        child: image,
      );
    }

    return image;
  }
}

// ── Action Chip ────────────────────────────────────────────────────────

final class _ScanActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ScanActionChip({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  State<_ScanActionChip> createState() => _ScanActionChipState();
}

final class _ScanActionChipState extends State<_ScanActionChip> {
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

// ── Icon Button for action row ─────────────────────────────────────────

final class _ScanIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ScanIconButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  State<_ScanIconButton> createState() => _ScanIconButtonState();
}

final class _ScanIconButtonState extends State<_ScanIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final effectiveColor = widget.color ?? AppColors.primary;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: (_isPressed ? effectiveColor : (isLight ? AppColors.lightBorder : AppColors.darkBorder)).withAlpha(80),
                  width: _isPressed ? 1.0 : 0.5,
                ),
              ),
              child: Icon(widget.icon, size: 20, color: _isPressed ? effectiveColor : effectiveColor.withAlpha(180)),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(widget.label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ── Primary Button ─────────────────────────────────────────────────────

final class _ScanPrimaryButton extends StatefulWidget {
  final String label;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ScanPrimaryButton({
    required this.label,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_ScanPrimaryButton> createState() => _ScanPrimaryButtonState();
}

final class _ScanPrimaryButtonState extends State<_ScanPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final effectiveColor = widget.isEnabled ? AppColors.primary : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(60);

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
