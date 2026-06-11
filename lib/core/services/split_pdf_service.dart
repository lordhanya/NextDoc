import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';
import 'package:image/image.dart' as img;
import 'metadata_service.dart';

enum SplitMode { extract, splitAll }

final class SplitResult {
  final List<SplitFile> files;

  const SplitResult({required this.files});

  int get fileCount => files.length;
  int get totalPages => files.fold(0, (sum, f) => sum + f.pageCount);
  int get totalSize => files.fold(0, (sum, f) => sum + f.fileSize);
}

final class SplitFile {
  final String filePath;
  final String fileName;
  final int fileSize;
  final int pageCount;

  const SplitFile({
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

final class SplitPdfService {
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  Future<SplitResult> splitPdf({
    required String inputPath,
    required String outputDir,
    required List<int> selectedPageIndices,
    required SplitMode mode,
    required void Function(double progress) onProgress,
  }) async {
    _cancelled = false;

    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw Exception('File not found');
    }
    if (selectedPageIndices.isEmpty) {
      throw Exception('No pages selected');
    }

    onProgress(0);

    final pdfDoc = await PdfDocument.openFile(inputPath);
    final totalPageCount = pdfDoc.pagesCount;

    if (selectedPageIndices.any((i) => i < 1 || i > totalPageCount)) {
      await pdfDoc.close();
      throw Exception('Invalid page selection');
    }

    final baseName = p.basenameWithoutExtension(inputPath);
    final outputFiles = <SplitFile>[];

    if (mode == SplitMode.splitAll) {
      final progressTotal = selectedPageIndices.length + 2;

      for (var idx = 0; idx < selectedPageIndices.length; idx++) {
        if (_cancelled) throw Exception('Cancelled');

        final pageIdx = selectedPageIndices[idx];
        final page = await pdfDoc.getPage(pageIdx);
        final image = await page.render(
          width: 1200,
          height: 1600,
          format: PdfPageImageFormat.jpeg,
          quality: 85,
          backgroundColor: '#FFFFFF',
        );
        await page.close();

        if (_cancelled) throw Exception('Cancelled');
        onProgress((idx + 1) / progressTotal);

        final doc = MetadataService.createPdfDocument(
            title: '${baseName}_page_$pageIdx',
            subject: 'Extracted from $baseName',
            keywords: 'NextDoc, Split PDF',
          );
        if (image != null) {
          final decoded = img.decodeImage(image.bytes);
          if (decoded != null) {
            doc.addPage(
              pw.Page(
                pageFormat: PdfPageFormat(
                  decoded.width.toDouble(),
                  decoded.height.toDouble(),
                ),
                margin: const pw.EdgeInsets.all(0),
                build: (ctx) => pw.Center(
                  child: pw.Image(pw.MemoryImage(image.bytes)),
                ),
              ),
            );
          }
        }

        onProgress((selectedPageIndices.length + 1) / progressTotal);

        final outBytes = await doc.save();
        final outName = '${baseName}_page_$pageIdx.pdf';
        final outPath = '$outputDir/$outName';
        final outFile = File(outPath);
        await outFile.writeAsBytes(outBytes);

        outputFiles.add(SplitFile(
          filePath: outPath,
          fileName: outName,
          fileSize: await outFile.length(),
          pageCount: 1,
        ));

        onProgress((selectedPageIndices.length + 2) / progressTotal);
      }
    } else {
      final progressTotal = selectedPageIndices.length + 2;

      final imagePages = <_RenderedPage>[];

      for (var idx = 0; idx < selectedPageIndices.length; idx++) {
        if (_cancelled) throw Exception('Cancelled');

        final pageIdx = selectedPageIndices[idx];
        final page = await pdfDoc.getPage(pageIdx);
        final image = await page.render(
          width: 1200,
          height: 1600,
          format: PdfPageImageFormat.jpeg,
          quality: 85,
          backgroundColor: '#FFFFFF',
        );
        await page.close();

        if (image != null) {
          imagePages.add(_RenderedPage(bytes: image.bytes));
        }

        onProgress((idx + 1) / progressTotal);
      }

      if (_cancelled) throw Exception('Cancelled');
      onProgress((selectedPageIndices.length) / progressTotal);

      final doc = MetadataService.createPdfDocument(
          title: '${baseName}_extracted',
          subject: 'Extracted pages from $baseName',
          keywords: 'NextDoc, Split PDF',
        );
      for (var i = 0; i < imagePages.length; i++) {
        if (_cancelled) throw Exception('Cancelled');

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

        onProgress((selectedPageIndices.length + 1 + (i / imagePages.length)) / progressTotal);
      }

      if (_cancelled) throw Exception('Cancelled');
      onProgress((selectedPageIndices.length + 1) / progressTotal);

      final outBytes = await doc.save();
      final ts = DateTime.now();
      final outName = '${baseName}_extracted_${ts.millisecondsSinceEpoch}.pdf';
      final outPath = '$outputDir/$outName';
      final outFile = File(outPath);
      await outFile.writeAsBytes(outBytes);

      onProgress((selectedPageIndices.length + 2) / progressTotal);

      outputFiles.add(SplitFile(
        filePath: outPath,
        fileName: outName,
        fileSize: await outFile.length(),
        pageCount: imagePages.length,
      ));
    }

    onProgress(1.0);
    await pdfDoc.close();

    return SplitResult(files: outputFiles);
  }
}

final class _RenderedPage {
  final Uint8List bytes;
  const _RenderedPage({required this.bytes});
}
