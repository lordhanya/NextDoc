import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'pdf_document_provider.dart';

final pdfThumbnailProvider = FutureProvider.family<Uint8List?, (String filePath, int pageIndex)>(
  (ref, params) async {
    final (filePath, pageIndex) = params;
    final docAsync = ref.watch(pdfDocumentProvider(filePath));
    final doc = docAsync.valueOrNull;
    if (doc == null || doc.isClosed) return null;

    try {
      final page = await doc.getPage(pageIndex + 1);
      if (doc.isClosed) {
        if (!page.isClosed) await page.close();
        return null;
      }
      final aspectRatio = page.width > 0 ? page.height / page.width : 1.4;
      final thumbWidth = 120.0;
      final thumbHeight = thumbWidth * aspectRatio;
      final image = await page.render(
        width: thumbWidth,
        height: thumbHeight,
        format: PdfPageImageFormat.jpeg,
        quality: 50,
      );
      if (!page.isClosed) await page.close();
      return image?.bytes;
    } catch (_) {
      return null;
    }
  },
);
