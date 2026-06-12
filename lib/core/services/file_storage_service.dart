import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileStorageService {
  static const _channel = MethodChannel('com.nextdoc.next_doc/downloads');

  static Future<Directory> createTempDir(String toolFolder) async {
    final temp = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dir = Directory('${temp.path}/nextdoc_${toolFolder}_$timestamp');
    await dir.create(recursive: true);
    return dir;
  }

  Future<String> copyToDownloads({
    required String sourcePath,
    required String fileName,
    required String toolFolder,
  }) async {
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<String>('saveToDownloads', {
          'sourcePath': sourcePath,
          'fileName': fileName,
          'toolFolder': toolFolder,
        });
        if (result != null && result.isNotEmpty) {
          return result;
        }
      } catch (_) {}
    }

    // iOS fallback: save to app documents
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/Downloads/NextDoc/$toolFolder');
    await dir.create(recursive: true);
    final targetPath = '${dir.path}/$fileName';
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }
}
