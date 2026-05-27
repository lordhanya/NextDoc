import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

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

  @override
  void initState() {
    super.initState();
    _renderPage();
  }

  @override
  void didUpdateWidget(PdfPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex) {
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
        await page.close();
        return;
      }
      final screenWidth = MediaQuery.of(context).size.width;
      final scale = page.width > 0 ? screenWidth / page.width : 1.0;
      final renderW = (page.width * scale).toInt();
      final renderH = (page.height * scale).toInt();
      final image = await page.render(
        width: renderW.toDouble(),
        height: renderH.toDouble(),
        format: PdfPageImageFormat.jpeg,
        quality: 85,
      );
      await page.close();
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Failed to load page', style: Theme.of(context).textTheme.bodySmall),
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
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
