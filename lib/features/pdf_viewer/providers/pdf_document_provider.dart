import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

final pdfDocumentProvider = FutureProvider.family<PdfDocument?, String>(
  (ref, filePath) async {
    final doc = await PdfDocument.openFile(filePath);
    ref.onDispose(() => doc.close());
    return doc;
  },
);
