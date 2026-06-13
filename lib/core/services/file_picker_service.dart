import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/selected_file_model.dart';

final class FilePickerService {
  Future<SelectedFileModel?> pickPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      return SelectedFileModel(
        fileName: file.name,
        filePath: file.path ?? '',
        fileSize: file.size,
        fileType: 'pdf',
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<SelectedFileModel>> pickMultiplePdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) return [];

      return result.files.map((file) {
        return SelectedFileModel(
          fileName: file.name,
          filePath: file.path ?? '',
          fileSize: file.size,
          fileType: 'pdf',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SelectedFileModel>> pickImages() async {
    try {
      debugPrint('--- FilePickerService.pickImages ---');
      debugPrint('Calling FilePicker.pickFiles(type: FileType.custom, allowedExtensions: [jpg,jpeg,png,webp,bmp], allowMultiple: true, withData: true)');
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
        allowMultiple: true,
        withData: true,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('Picker returned null or empty');
        return [];
      }

      debugPrint('Picker returned ${result.files.length} files');
      final imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'bmp'};
      final models = <SelectedFileModel>[];
      for (final file in result.files) {
        debugPrint('  file: name=${file.name}, path=${file.path}, size=${file.size}, hasBytes=${file.bytes != null}');
        var ext = file.name.split('.').last.toLowerCase();
        if (!imageExtensions.contains(ext)) {
          debugPrint('  -> SKIPPED: non-image extension "$ext"');
          continue;
        }
        if (ext == 'jpeg') ext = 'jpg';
        models.add(SelectedFileModel(
          fileName: file.name,
          filePath: file.path ?? '',
          fileSize: file.size,
          fileType: ext,
          bytes: file.bytes,
        ));
      }
      debugPrint('Valid images: ${models.length}');
      debugPrint('Files with path: ${models.where((m) => m.filePath.isNotEmpty).length}');
      debugPrint('Files falling back to bytes: ${models.where((m) => m.filePath.isEmpty && m.bytes != null).length}');
      return models;
    } catch (e, stack) {
      debugPrint('FilePickerService.pickImages exception: $e');
      debugPrint('Stack trace: $stack');
      return [];
    }
  }
}
