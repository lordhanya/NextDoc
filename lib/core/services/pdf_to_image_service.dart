import 'dart:io';
import 'package:gal/gal.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'metadata_service.dart';
import 'settings_service.dart';

final class PdfToImageResult {
  final String outputDir;
  final List<String> imagePaths;
  final int totalSize;
  final int imageCount;

  const PdfToImageResult({
    required this.outputDir,
    required this.imagePaths,
    required this.totalSize,
    required this.imageCount,
  });
}

final class PdfToImageService {
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<PdfToImageResult> convert({
    required String filePath,
    required List<int> selectedPages,
    required ExportQuality quality,
    required void Function(double progress) onProgress,
  }) async {
    _cancelled = false;

    final doc = await PdfDocument.openFile(filePath);
    try {
      final totalPages = doc.pagesCount;

      final pagesToExport = selectedPages.isEmpty
          ? List.generate(totalPages, (i) => i)
          : selectedPages;

      final totalToExport = pagesToExport.length;

      final (int qualityValue, double renderWidth) = switch (quality) {
        ExportQuality.standard => (75, 1500.0),
        ExportQuality.highQuality => (100, 3000.0),
        ExportQuality.smallSize => (40, 800.0),
      };

      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sourceDir = '${appDir.path}/NextDoc/PDF_to_JPG/$timestamp';
      await Directory(sourceDir).create(recursive: true);

      final imagePaths = <String>[];
      int totalSize = 0;

      for (int i = 0; i < totalToExport; i++) {
        if (_cancelled) {
          throw Exception('Export cancelled');
        }

        final pageIndex = pagesToExport[i];
        final page = await doc.getPage(pageIndex + 1);
        try {
          final pageImage = await page.render(
            width: renderWidth,
            height: renderWidth * 1.414,
            format: PdfPageImageFormat.jpeg,
            quality: qualityValue,
          );

          if (pageImage == null) continue;

          final outputPath = '$sourceDir/page_${pageIndex + 1}.jpg';
          final imageBytes = MetadataService.injectJpegExif(
            pageImage.bytes,
            quality: qualityValue,
          );
          await File(outputPath).writeAsBytes(imageBytes);

          imagePaths.add(outputPath);
          totalSize += imageBytes.length;
        } finally {
          if (!page.isClosed) await page.close();
        }

        onProgress((i + 1) / totalToExport);
      }

      _saveToGallery(imagePaths);

      return PdfToImageResult(
        outputDir: sourceDir,
        imagePaths: imagePaths,
        totalSize: totalSize,
        imageCount: imagePaths.length,
      );
    } finally {
      if (!doc.isClosed) await doc.close();
    }
  }

  void _saveToGallery(List<String> imagePaths) {
    try {
      for (final path in imagePaths) {
        Gal.putImage(path, album: 'NextDoc/PDF_to_JPG');
      }
    } catch (_) {
      // Gallery save is best-effort; images remain accessible from app
    }
  }
}
