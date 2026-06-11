import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

final class PdfDocumentException implements Exception {
  final String title;
  final String description;
  PdfDocumentException({required this.title, required this.description});

  @override
  String toString() => '$title: $description';
}

final pdfDocumentProvider = FutureProvider.family<PdfDocument?, (String filePath, String? password)>(
  (ref, params) async {
    final (filePath, password) = params;
    try {
      final doc = password != null
          ? await PdfDocument.openFile(filePath, password: password)
          : await PdfDocument.openFile(filePath);
      ref.onDispose(() => doc.close());
      return doc;
    } on PdfDocumentException {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('no such file') || msg.contains('not found') || msg.contains('cannot open')) {
        throw PdfDocumentException(
          title: 'File Not Found',
          description: 'The PDF file could not be accessed. It may have been moved or deleted.',
        );
      }
      if (msg.contains('format') || msg.contains('corrupt') || msg.contains('password')) {
        throw PdfDocumentException(
          title: 'Invalid PDF',
          description: 'The file appears to be corrupted or password-protected.',
        );
      }
      throw PdfDocumentException(
        title: 'Failed to Open',
        description: 'An unexpected error occurred while opening the PDF.',
      );
    }
  },
);
