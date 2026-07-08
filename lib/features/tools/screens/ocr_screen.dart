import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/isar_service.dart';
import '../../../core/database/recent_file_entity.dart';
import '../../../core/providers/recent_files_provider.dart';
import '../../../core/services/file_storage_service.dart';
import '../../../core/theme/typography.dart';

final class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

final class _OcrScreenState extends ConsumerState<OcrScreen> {
  final _picker = ImagePicker();
  String? _imagePath;
  String _recognizedText = '';
  bool _isProcessing = false;
  bool _hasRun = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(source: source, imageQuality: 90);
      if (xfile == null) return;
      if (!mounted) return;
      setState(() {
        _imagePath = xfile.path;
        _recognizedText = '';
        _hasRun = false;
      });
      _recognizeText();
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _recognizeText() async {
    if (_imagePath == null) return;
    setState(() => _isProcessing = true);

    try {
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFilePath(_imagePath!);
      final recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      if (!mounted) return;
      setState(() {
        _recognizedText = recognizedText.text;
        _isProcessing = false;
        _hasRun = true;
      });
    } catch (e) {
      debugPrint('OCR error: $e');
      if (!mounted) return;
      setState(() {
        _recognizedText = '';
        _isProcessing = false;
        _hasRun = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Text recognition failed: $e')),
      );
    }
  }

  void _copyText() {
    if (_recognizedText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _recognizedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  Future<void> _shareText() async {
    if (_recognizedText.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(text: _recognizedText, subject: 'Extracted Text'),
    );
  }

  Future<void> _saveText() async {
    if (_recognizedText.isEmpty) return;

    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'OCR_Text_$timestamp.txt';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(_recognizedText);

      final finalPath = await FileStorageService().copyToDownloads(
        sourcePath: tempFile.path,
        fileName: fileName,
        toolFolder: 'OCR_Text',
      );

      if (!mounted) return;

      final isarService = IsarService.instance;
      await isarService.saveRecentFile(RecentFileEntity(
        fileName: fileName,
        filePath: finalPath,
        fileSize: await File(finalPath).length(),
        fileType: 'text',
        createdAt: DateTime.now(),
      ));
      refreshRecentFiles(ref);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text saved in Downloads/NextDoc/OCR_Text/')),
      );

      try { await tempFile.delete(); } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSourceSheet(
        onGallery: () {
          Navigator.of(ctx).pop();
          _pickImage(ImageSource.gallery);
        },
        onCamera: () {
          Navigator.of(ctx).pop();
          _pickImage(ImageSource.camera);
        },
      ),
    );
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
        title: Text('OCR Text', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: _imagePath == null
            ? _buildEmptyState()
            : _buildResult(isLight),
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
                LucideIcons.scan_text,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Extract Text from Images',
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pick an image and let OCR extract all\ntext content automatically',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _OcrActionChip(
              icon: LucideIcons.image_plus,
              label: 'Pick Image',
              onTap: _showSourcePicker,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(bool isLight) {
    return Column(
      children: [
        // Image preview
        Container(
          height: 220,
          width: double.infinity,
          margin: const EdgeInsets.all(AppSpacing.screenPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.file(
              File(_imagePath!),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => Container(
                color: isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
                child: const Icon(LucideIcons.image, size: 40),
              ),
            ),
          ),
        ),
        // Action row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OcrSmallButton(
                    icon: LucideIcons.image_plus,
                    label: 'Change',
                    onTap: _showSourcePicker,
                  ),
                  if (_hasRun) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _OcrSmallButton(
                      icon: LucideIcons.refresh_cw,
                      label: 'Retry',
                      onTap: _recognizeText,
                    ),
                  ],
                ],
              ),
              if (_recognizedText.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OcrSmallButton(
                      icon: LucideIcons.copy,
                      label: 'Copy',
                      onTap: _copyText,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _OcrSmallButton(
                      icon: LucideIcons.share_2,
                      label: 'Share',
                      onTap: _shareText,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _OcrSmallButton(
                      icon: LucideIcons.save,
                      label: 'Save',
                      onTap: _saveText,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Recognized text area
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
                width: 0.5,
              ),
            ),
            child: _isProcessing
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text('Recognizing text...', style: AppTextStyles.caption),
                      ],
                    ),
                  )
                : _recognizedText.isNotEmpty
                    ? SingleChildScrollView(
                        child: SelectableText(
                          _recognizedText,
                          style: AppTextStyles.body,
                        ),
                      )
                    : _hasRun
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.scan_face, size: 40, color: AppColors.warning),
                                const SizedBox(height: AppSpacing.md),
                                Text('No text found', style: AppTextStyles.bodySmall),
                                const SizedBox(height: AppSpacing.xs),
                                Text('Try a clearer image', style: AppTextStyles.caption),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

// ── Image source bottom sheet ─────────────────────────────────────────

final class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _ImageSourceSheet({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Select Image Source', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: LucideIcons.image,
                  label: 'Gallery',
                  onTap: onGallery,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SourceOption(
                  icon: LucideIcons.camera,
                  label: 'Camera',
                  onTap: onCamera,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: (isLight ? AppColors.lightSurface2 : AppColors.darkSurface3).withAlpha(120),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTextStyles.button),
          ],
        ),
      ),
    );
  }
}

// ── Small action button ──────────────────────────────────────────────

final class _OcrSmallButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OcrSmallButton({required this.icon, required this.label, required this.onTap});

  @override
  State<_OcrSmallButton> createState() => _OcrSmallButtonState();
}

final class _OcrSmallButtonState extends State<_OcrSmallButton> {
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
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(80),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xxs),
              Text(widget.label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action chip ──────────────────────────────────────────────────────

final class _OcrActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _OcrActionChip({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  State<_OcrActionChip> createState() => _OcrActionChipState();
}

final class _OcrActionChipState extends State<_OcrActionChip> {
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
