import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pdfx/pdfx.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/theme/typography.dart';

final class PdfPageWidget extends ConsumerStatefulWidget {
  final PdfDocument document;
  final int pageIndex;
  final double zoomLevel;

  const PdfPageWidget({
    super.key,
    required this.document,
    required this.pageIndex,
    required this.zoomLevel,
  });

  @override
  ConsumerState<PdfPageWidget> createState() => _PdfPageWidgetState();
}

final class _PdfPageWidgetState extends ConsumerState<PdfPageWidget> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _error;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _renderPage();
  }

  @override
  void didUpdateWidget(PdfPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex) {
      _retryCount = 0;
      _renderPage();
    }
  }

  Future<void> _renderPage() async {
    if (widget.document.isClosed) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _imageBytes = null;
    });
    try {
      final page = await widget.document.getPage(widget.pageIndex + 1);
      if (widget.document.isClosed || !mounted) {
        if (!page.isClosed) await page.close();
        return;
      }
      final screenWidth = MediaQuery.of(context).size.width;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final targetWidth = screenWidth * pixelRatio * 1.5;
      final scale = page.width > 0 ? targetWidth / page.width : 1.0;
      final renderW = (page.width * scale).toInt();
      final renderH = (page.height * scale).toInt();
      final image = await page.render(
        width: renderW.toDouble(),
        height: renderH.toDouble(),
        format: PdfPageImageFormat.png,
      );
      if (!page.isClosed) await page.close();
      if (mounted && !widget.document.isClosed) {
        setState(() {
          _imageBytes = image?.bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _retry() {
    if (_retryCount >= _maxRetries) return;
    _retryCount++;
    _renderPage();
  }

  @override
  void dispose() {
    _imageBytes = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(120),
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load page',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
                ),
              ),
              if (_retryCount < _maxRetries) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(LucideIcons.refresh_cw, size: 16),
                    label: Text('Retry', style: AppTextStyles.buttonSmall),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withAlpha(80)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (_imageBytes == null) {
      return const SizedBox.shrink();
    }
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
