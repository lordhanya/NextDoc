import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:image/image.dart' as img;

enum ProtectionMode { protect, unlock }

final class ProtectionResult {
  final String filePath;
  final String fileName;
  final int fileSize;
  final int pageCount;
  final ProtectionMode mode;

  const ProtectionResult({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
    required this.mode,
  });
}

final class PdfProtectionService {
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  Future<ProtectionResult> protectPdf({
    required String inputPath,
    required String outputPath,
    required String password,
    required void Function(double progress) onProgress,
  }) async {
    _cancelled = false;
    onProgress(0);

    final inputFile = File(inputPath);
    if (!await inputFile.exists()) throw Exception('File not found');
    final inputBytes = await inputFile.readAsBytes();
    if (inputBytes.isEmpty) throw Exception('File is empty');

    onProgress(0.15);

    final doc = syncfusion.PdfDocument(inputBytes: inputBytes);
    if (_cancelled) {
      doc.dispose();
      throw Exception('Cancelled');
    }

    final pageCount = doc.pages.count;
    onProgress(0.3);

    doc.security.userPassword = password;
    doc.security.ownerPassword = password;
    doc.security.algorithm = syncfusion.PdfEncryptionAlgorithm.aesx256Bit;

    onProgress(0.5);

    final outputBytes = await doc.save();
    if (_cancelled) {
      doc.dispose();
      throw Exception('Cancelled');
    }

    onProgress(0.8);
    doc.dispose();

    await File(outputPath).writeAsBytes(outputBytes);
    final fileSize = await File(outputPath).length();

    onProgress(1.0);

    return ProtectionResult(
      filePath: outputPath,
      fileName: p.basename(outputPath),
      fileSize: fileSize,
      pageCount: pageCount,
      mode: ProtectionMode.protect,
    );
  }

  Future<ProtectionResult> unlockPdf({
    required String inputPath,
    required String outputPath,
    required String password,
    required void Function(double progress) onProgress,
  }) async {
    _cancelled = false;
    onProgress(0);

    final inputFile = File(inputPath);
    if (!await inputFile.exists()) throw Exception('File not found');
    final originalSize = await inputFile.length();
    if (originalSize == 0) throw Exception('File is empty');

    onProgress(0.05);

    final pdfDoc = await PdfDocument.openFile(
      inputPath,
      password: password,
    );
    final pageCount = pdfDoc.pagesCount;

    onProgress(0.1);

    final imagePages = <Uint8List>[];
    final progressTotal = pageCount + 3;

    for (var i = 1; i <= pageCount; i++) {
      if (_cancelled) {
        await pdfDoc.close();
        throw Exception('Cancelled');
      }

      final page = await pdfDoc.getPage(i);
      final image = await page.render(
        width: page.width,
        height: page.height,
        format: PdfPageImageFormat.jpeg,
        quality: 85,
        backgroundColor: '#FFFFFF',
      );
      await page.close();

      if (image != null) {
        imagePages.add(image.bytes);
      }

      onProgress((i) / progressTotal);
    }

    await pdfDoc.close();
    onProgress(pageCount / progressTotal);

    final doc = pw.Document();

    for (var i = 0; i < imagePages.length; i++) {
      if (_cancelled) throw Exception('Cancelled');

      final decoded = img.decodeImage(imagePages[i]);
      if (decoded == null) continue;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            decoded.width.toDouble(),
            decoded.height.toDouble(),
          ),
          margin: const pw.EdgeInsets.all(0),
          build: (ctx) => pw.Center(
            child: pw.Image(pw.MemoryImage(imagePages[i])),
          ),
        ),
      );

      onProgress((pageCount + 1 + (i / imagePages.length)) / progressTotal);
    }

    onProgress((pageCount + 1) / progressTotal);

    final outBytes = await doc.save();
    final outFile = File(outputPath);
    await outFile.writeAsBytes(outBytes);

    onProgress(1.0);

    final fileSize = await outFile.length();

    return ProtectionResult(
      filePath: outputPath,
      fileName: p.basename(outputPath),
      fileSize: fileSize,
      pageCount: pageCount,
      mode: ProtectionMode.unlock,
    );
  }
}
