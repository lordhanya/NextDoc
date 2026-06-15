import 'dart:io';
import 'package:flutter/foundation.dart';
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
          debugPrint('saveToDownloads SUCCESS: $result');
          return result;
        }
        debugPrint('saveToDownloads returned null/empty');
      } catch (e) {
        debugPrint('saveToDownloads native error: $e');
      }

      // Second attempt: try saving via legacy public path
      try {
        final result = await _channel.invokeMethod<String>('saveToDownloadsLegacy', {
          'sourcePath': sourcePath,
          'fileName': fileName,
          'toolFolder': toolFolder,
        });
        if (result != null && result.isNotEmpty) {
          debugPrint('saveToDownloadsLegacy SUCCESS: $result');
          return result;
        }
        debugPrint('saveToDownloadsLegacy returned null/empty');
      } catch (e) {
        debugPrint('saveToDownloadsLegacy error: $e');
      }

      throw Exception(
        'Failed to save file to Downloads/NextDoc/$toolFolder/. '
        'Please check storage permissions and available space.',
      );
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
