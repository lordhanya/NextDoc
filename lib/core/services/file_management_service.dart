import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import '../database/isar_service.dart';
import '../database/recent_file_entity.dart';
import 'pdf_service.dart';

enum FileManagementResult { success, fileNotFound, alreadyExists, invalidName, error }

final class FileManagementService {
  FileManagementService._();

  static final PdfService _pdfService = PdfService();

  static Future<FileManagementResult> renamePdf({
    required String filePath,
    required String newName,
  }) async {
    try {
      if (newName.trim().isEmpty) return FileManagementResult.invalidName;

      final hasExtension = newName.toLowerCase().endsWith('.pdf');
      final finalName = hasExtension ? newName : '$newName.pdf';

      if (!_isValidFileName(finalName)) return FileManagementResult.invalidName;

      final file = File(filePath);
      if (!await file.exists()) return FileManagementResult.fileNotFound;

      final dir = p.dirname(filePath);
      final newPath = p.join(dir, finalName);

      if (await File(newPath).exists()) return FileManagementResult.alreadyExists;

      await file.rename(newPath);

      final isar = IsarService.instance;
      final existing = await isar.isar!.recentFileEntitys
          .where()
          .filePathEqualTo(filePath)
          .findFirst();
      if (existing != null) {
        await isar.isar!.writeTxn(() async {
          await isar.isar!.recentFileEntitys.put(
            existing
              ..filePath = newPath
              ..fileName = finalName
              ..createdAt = DateTime.now(),
          );
        });
      }

      _pdfService.clearCache();

      return FileManagementResult.success;
    } catch (_) {
      return FileManagementResult.error;
    }
  }

  static Future<FileManagementResult> deletePdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return FileManagementResult.fileNotFound;

      await file.delete();

      final isar = IsarService.instance;
      final existing = await isar.isar!.recentFileEntitys
          .where()
          .filePathEqualTo(filePath)
          .findFirst();
      if (existing != null) {
        await isar.isar!.writeTxn(() async {
          await isar.isar!.recentFileEntitys.delete(existing.id);
        });
      }

      _pdfService.clearCache();

      return FileManagementResult.success;
    } catch (_) {
      return FileManagementResult.error;
    }
  }

  static Future<({FileManagementResult result, String? newPath})> duplicatePdf(
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return (result: FileManagementResult.fileNotFound, newPath: null);
      }

      final dir = p.dirname(filePath);
      final nameWithoutExt = p.basenameWithoutExtension(filePath);
      String newPath = p.join(dir, '${nameWithoutExt}_copy.pdf');
      int counter = 1;

      while (await File(newPath).exists()) {
        counter++;
        newPath = p.join(dir, '${nameWithoutExt}_copy_$counter.pdf');
      }

      await file.copy(newPath);

      final stat = await File(newPath).stat();

      final fileEntity = RecentFileEntity(
        fileName: p.basename(newPath),
        filePath: newPath,
        fileSize: stat.size,
        fileType: 'pdf',
        createdAt: DateTime.now(),
      );

      final isar = IsarService.instance;
      await isar.saveRecentFile(fileEntity);

      _pdfService.clearCache();

      return (result: FileManagementResult.success, newPath: newPath);
    } catch (_) {
      return (result: FileManagementResult.error, newPath: null);
    }
  }

  static bool _isValidFileName(String name) {
    if (name.isEmpty || name.length > 255) return false;
    final forbidden = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
    if (forbidden.hasMatch(name)) return false;
    if (name == '.' || name == '..') return false;
    if (name.trim() != name) return false;
    return true;
  }
}
