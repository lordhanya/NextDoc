final class SelectedFileModel {
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileType;

  const SelectedFileModel({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
