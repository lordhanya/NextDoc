import 'dart:io';
import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';

final class PdfMetadata {
  final String fileName;
  final int pageCount;
  final int fileSize;
  final String filePath;
  final DateTime? creationDate;

  const PdfMetadata({
    required this.fileName,
    required this.pageCount,
    required this.fileSize,
    required this.filePath,
    this.creationDate,
  });
}

final class PdfService {
  final _thumbnailCache = <String, Uint8List>{};
  final _encryptedCache = <String, bool>{};

  Future<PdfMetadata?> getMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final doc = await PdfDocument.openFile(filePath);
      final pageCount = doc.pagesCount;
      final fileSize = await file.length();
      await doc.close();

      return PdfMetadata(
        fileName: file.uri.pathSegments.last,
        pageCount: pageCount,
        fileSize: fileSize,
        filePath: filePath,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> isEncrypted(String filePath) async {
    if (_encryptedCache.containsKey(filePath)) {
      return _encryptedCache[filePath]!;
    }
    try {
      final doc = await PdfDocument.openFile(filePath);
      await doc.close();
      _encryptedCache[filePath] = false;
      return false;
    } catch (_) {
      _encryptedCache[filePath] = true;
      return true;
    }
  }

  Future<bool> verifyPassword(String filePath, String password) async {
    try {
      final doc = await PdfDocument.openFile(filePath, password: password);
      await doc.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> getThumbnail(String filePath, {int page = 0}) async {
    final cacheKey = '$filePath:$page';
    if (_thumbnailCache.containsKey(cacheKey)) {
      return _thumbnailCache[cacheKey];
    }

    try {
      final doc = await PdfDocument.openFile(filePath);
      try {
        final p = await doc.getPage(page + 1);
        try {
          final pageImage = await p.render(
            width: 200,
            height: 260,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#0D0D0D',
          );
          if (pageImage == null) return null;

          final bytes = pageImage.bytes;
          _thumbnailCache[cacheKey] = bytes;
          return bytes;
        } finally {
          if (!p.isClosed) await p.close();
        }
      } finally {
        await doc.close();
      }
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _thumbnailCache.clear();
    _encryptedCache.clear();
  }
}
