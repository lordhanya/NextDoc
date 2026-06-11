import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';
import 'package:image/image.dart' as img;
import 'metadata_service.dart';

enum CompressionLevel { low, medium, high }

final class CompressResult {
  final String filePath;
  final String fileName;
  final int originalSize;
  final int compressedSize;
  final int pageCount;
  final CompressionLevel level;

  const CompressResult({
    required this.filePath,
    required this.fileName,
    required this.originalSize,
    required this.compressedSize,
    required this.pageCount,
    required this.level,
  });

  int get savedBytes => originalSize - compressedSize;
  double get savingsPercent => originalSize > 0
      ? ((originalSize - compressedSize) / originalSize * 100)
      : 0;

  String get formattedOriginalSize {
    if (originalSize < 1024) return '$originalSize B';
    if (originalSize < 1024 * 1024) {
      return '${(originalSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(originalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedCompressedSize {
    if (compressedSize < 1024) return '$compressedSize B';
    if (compressedSize < 1024 * 1024) {
      return '${(compressedSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(compressedSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedSavings => '${savingsPercent.toStringAsFixed(1)}%';
}

final class CompressPdfService {
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  Future<CompressResult> compressPdf({
    required String inputPath,
    required String outputPath,
    required CompressionLevel level,
    required void Function(double progress) onProgress,
  }) async {
    _cancelled = false;

    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw Exception('File not found');
    }
    final originalSize = await inputFile.length();
    if (originalSize == 0) {
      throw Exception('File is empty');
    }

    onProgress(0);

    final pdfDoc = await PdfDocument.openFile(inputPath);
    final pageCount = pdfDoc.pagesCount;

    final settings = _settingsForLevel(level);
    final imagePages = <_RenderedPage>[];
    final progressTotal = pageCount + 3;

    for (var i = 1; i <= pageCount; i++) {
      if (_cancelled) throw Exception('Cancelled');

      final page = await pdfDoc.getPage(i);

      final pageWidth = page.width;
      final pageHeight = page.height;

      final aspectRatio = pageWidth / pageHeight;
      final renderWidth = settings.maxWidth;
      final renderHeight = (renderWidth / aspectRatio).round();

      final image = await page.render(
        width: renderWidth.toDouble(),
        height: renderHeight.toDouble(),
        format: PdfPageImageFormat.jpeg,
        quality: settings.jpegQuality,
        backgroundColor: '#FFFFFF',
      );
      await page.close();

      if (image != null) {
        imagePages.add(_RenderedPage(bytes: image.bytes));
      }

      onProgress(i / progressTotal);
    }

    await pdfDoc.close();
    onProgress(pageCount / progressTotal);

    final doc = MetadataService.createPdfDocument(
        title: 'Compressed PDF',
        subject: 'Compressed with NextDoc (${level.name})',
        keywords: 'NextDoc, Compress PDF',
      );

    for (var i = 0; i < imagePages.length; i++) {
      if (_cancelled) throw Exception('Cancelled');

      final decoded = img.decodeImage(imagePages[i].bytes);
      if (decoded == null) continue;

      final compressedBytes = img.encodeJpg(decoded, quality: settings.jpegQuality);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            decoded.width.toDouble(),
            decoded.height.toDouble(),
          ),
          margin: const pw.EdgeInsets.all(0),
          build: (ctx) => pw.Center(
            child: pw.Image(pw.MemoryImage(compressedBytes)),
          ),
        ),
      );

      onProgress((pageCount + 1 + (i / imagePages.length)) / progressTotal);
    }

    onProgress((pageCount + 1) / progressTotal);

    final outBytes = await doc.save();
    final outFile = File(outputPath);
    await outFile.writeAsBytes(outBytes);

    onProgress((pageCount + 2) / progressTotal);

    final compressedSize = await outFile.length();
    if (compressedSize >= originalSize) {
      await outFile.writeAsBytes(await inputFile.readAsBytes());
    }

    onProgress(1.0);

    return CompressResult(
      filePath: outputPath,
      fileName: p.basename(outputPath),
      originalSize: originalSize,
      compressedSize: compressedSize >= originalSize ? originalSize : compressedSize,
      pageCount: pageCount,
      level: level,
    );
  }
}

final class _CompressSettings {
  final int maxWidth;
  final int jpegQuality;

  const _CompressSettings({
    required this.maxWidth,
    required this.jpegQuality,
  });
}

_CompressSettings _settingsForLevel(CompressionLevel level) {
  return switch (level) {
    CompressionLevel.low => const _CompressSettings(
        maxWidth: 1600,
        jpegQuality: 80,
      ),
    CompressionLevel.medium => const _CompressSettings(
        maxWidth: 1100,
        jpegQuality: 60,
      ),
    CompressionLevel.high => const _CompressSettings(
        maxWidth: 800,
        jpegQuality: 40,
      ),
  };
}

final class _RenderedPage {
  final Uint8List bytes;
  const _RenderedPage({required this.bytes});
}
