import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';
import '../../../core/services/metadata_service.dart';

final class PdfRenderResult {
  final List<Uint8List> pageImages;
  final int pageCount;

  const PdfRenderResult({
    required this.pageImages,
    required this.pageCount,
  });
}

final class PdfEditorService {
  Future<PdfRenderResult> renderAllPages(String inputPath) async {
    final pdfDoc = await PdfDocument.openFile(inputPath);
    final count = pdfDoc.pagesCount;
    final images = <Uint8List>[];

    try {
      for (int i = 0; i < count; i++) {
        final page = await pdfDoc.getPage(i + 1);
        try {
          final rendered = await page.render(
            width: 1200,
            height: 1600,
            format: PdfPageImageFormat.jpeg,
            quality: 85,
            backgroundColor: '#FFFFFF',
          );
          images.add(rendered?.bytes ?? Uint8List(0));
        } finally {
          if (!page.isClosed) await page.close();
        }
      }
    } finally {
      if (!pdfDoc.isClosed) await pdfDoc.close();
    }

    return PdfRenderResult(pageImages: images, pageCount: count);
  }

  Future<String> rebuildPdf({
    required List<Uint8List> pageImages,
    required String outputFileName,
  }) async {
    final doc = MetadataService.createPdfDocument(
      title: outputFileName.replaceAll('.pdf', ''),
      subject: 'Edited with NextDoc Editor Studio',
      keywords: 'NextDoc, Editor Studio, PDF',
    );

    for (final imageBytes in pageImages) {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) continue;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            decoded.width.toDouble(),
            decoded.height.toDouble(),
          ),
          margin: const pw.EdgeInsets.all(0),
          build: (ctx) => pw.Center(
            child: pw.Image(pw.MemoryImage(imageBytes)),
          ),
        ),
      );
    }

    final outBytes = await doc.save();
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outPath = '${tempDir.path}/nextdoc_Editor_Studio_$timestamp/$outputFileName';
    await Directory(outPath).parent.create(recursive: true);
    await File(outPath).writeAsBytes(outBytes);

    return outPath;
  }
}
