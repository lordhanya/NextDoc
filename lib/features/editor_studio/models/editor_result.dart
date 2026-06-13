import 'dart:typed_data';

final class EditorResult {
  final String filePath;
  final List<Uint8List> pageImages;
  final int pageCount;
  final bool isPdf;

  const EditorResult({
    required this.filePath,
    required this.pageImages,
    required this.pageCount,
    required this.isPdf,
  });
}
