import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

final class ImageEditorResult {
  final String filePath;
  final int width;
  final int height;
  final int fileSize;

  const ImageEditorResult({
    required this.filePath,
    required this.width,
    required this.height,
    required this.fileSize,
  });
}

final class ImageEditorService {
  Future<Uint8List> decodeImageBytes(String sourcePath) async {
    final file = File(sourcePath);
    return file.readAsBytes();
  }

  Future<ImageEditorResult> saveImage({
    required List<int> imageBytes,
    required String fileName,
    required String toolFolder,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempPath = '${tempDir.path}/nextdoc_${toolFolder}_$timestamp/$fileName';
    await Directory(tempPath).parent.create(recursive: true);
    await File(tempPath).writeAsBytes(imageBytes);

    final file = File(tempPath);
    final decoded = img.decodeImage(Uint8List.fromList(imageBytes));
    return ImageEditorResult(
      filePath: tempPath,
      width: decoded?.width ?? 0,
      height: decoded?.height ?? 0,
      fileSize: await file.length(),
    );
  }

  Uint8List? rotateImage(Uint8List sourceBytes, {int degrees = 90}) {
    final src = img.decodeImage(sourceBytes);
    if (src == null) return null;
    final rotated = img.copyRotate(src, angle: degrees);
    return img.encodeJpg(rotated, quality: 95);
  }

  Uint8List? flipHorizontal(Uint8List sourceBytes) {
    final src = img.decodeImage(sourceBytes);
    if (src == null) return null;
    final flipped = img.flipHorizontal(src);
    return img.encodeJpg(flipped, quality: 95);
  }

  Uint8List? flipVertical(Uint8List sourceBytes) {
    final src = img.decodeImage(sourceBytes);
    if (src == null) return null;
    final flipped = img.flipVertical(src);
    return img.encodeJpg(flipped, quality: 95);
  }
}
