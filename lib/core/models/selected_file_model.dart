import 'dart:typed_data';

final class SelectedFileModel {
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileType;
  final Uint8List? bytes;

  const SelectedFileModel({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    this.bytes,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
