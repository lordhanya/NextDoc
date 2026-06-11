import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';
import 'package:image/image.dart' as img;
import 'metadata_service.dart';

final class MergeResult {
  final String filePath;
  final String fileName;
  final int fileSize;
  final int pageCount;

  const MergeResult({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

final class MergePdfService {
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  Future<MergeResult> mergePdfs({
    required List<String> inputPaths,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    _cancelled = false;

    if (inputPaths.isEmpty) {
      throw Exception('No files to merge');
    }
    if (inputPaths.length < 2) {
      throw Exception('Select at least 2 PDF files');
    }

    final imagePages = <_RenderedPage>[];
    var totalPages = 0;

    for (var i = 0; i < inputPaths.length; i++) {
      if (_cancelled) throw Exception('Cancelled');
      onProgress((i / (inputPaths.length + 2)));

      final file = File(inputPaths[i]);
      if (!await file.exists()) {
        throw Exception('File not found: ${p.basename(inputPaths[i])}');
      }

      final pdfDoc = await PdfDocument.openFile(inputPaths[i]);
      final pageCount = pdfDoc.pagesCount;

      for (var pIdx = 1; pIdx <= pageCount; pIdx++) {
        if (_cancelled) throw Exception('Cancelled');

        final page = await pdfDoc.getPage(pIdx);
        final image = await page.render(
          width: 1200,
          height: 1600,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
        );
        await page.close();

        if (image != null) {
          imagePages.add(_RenderedPage(bytes: image.bytes));
          totalPages++;
        }

        final subProgress = (i + (pIdx / pageCount)) / (inputPaths.length + 2);
        onProgress(subProgress);
      }

      await pdfDoc.close();
    }

    onProgress((inputPaths.length) / (inputPaths.length + 2));

    final doc = MetadataService.createPdfDocument(
        title: 'Merged PDF',
        subject: 'Merged from ${inputPaths.length} PDF file(s)',
        keywords: 'NextDoc, Merge PDF',
      );

    for (var i = 0; i < imagePages.length; i++) {
      if (_cancelled) throw Exception('Cancelled');
      onProgress(
        (inputPaths.length + 1 + (i / imagePages.length)) /
            (inputPaths.length + 2),
      );

      final decoded = img.decodeImage(imagePages[i].bytes);
      if (decoded == null) continue;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            decoded.width.toDouble(),
            decoded.height.toDouble(),
          ),
          margin: const pw.EdgeInsets.all(0),
          build: (ctx) => pw.Center(
            child: pw.Image(pw.MemoryImage(imagePages[i].bytes)),
          ),
        ),
      );
    }

    onProgress((inputPaths.length + 1) / (inputPaths.length + 2));

    final outBytes = await doc.save();
    final outFile = File(outputPath);
    await outFile.writeAsBytes(outBytes);

    onProgress(1.0);

    return MergeResult(
      filePath: outputPath,
      fileName: p.basename(outputPath),
      fileSize: await outFile.length(),
      pageCount: totalPages,
    );
  }
}

final class _RenderedPage {
  final Uint8List bytes;
  const _RenderedPage({required this.bytes});
}
