import 'package:file_picker/file_picker.dart';
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
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) return [];

      return result.files.map((file) {
        final ext = file.name.split('.').last.toLowerCase();
        return SelectedFileModel(
          fileName: file.name,
          filePath: file.path ?? '',
          fileSize: file.size,
          fileType: ext,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
