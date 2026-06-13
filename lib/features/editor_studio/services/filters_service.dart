import 'dart:typed_data';
import 'package:image/image.dart' as img;

final class FiltersService {
  Uint8List? applyGrayscale(Uint8List source) {
    final src = img.decodeImage(source);
    if (src == null) return null;
    final result = img.grayscale(src);
    return img.encodeJpg(result, quality: 95);
  }

  Uint8List? applyBlackAndWhite(Uint8List source, {int threshold = 128}) {
    final src = img.decodeImage(source);
    if (src == null) return null;
    final gray = img.grayscale(src);
    for (final pixel in gray) {
      pixel.r = pixel.g = pixel.b = pixel.r > threshold ? 255 : 0;
    }
    return img.encodeJpg(gray, quality: 95);
  }

  Uint8List? applySepia(Uint8List source) {
    final src = img.decodeImage(source);
    if (src == null) return null;
    img.colorOffset(src, red: 20, green: 10, blue: -30);
    return img.encodeJpg(src, quality: 95);
  }

  Uint8List? applyHighContrast(Uint8List source) {
    final src = img.decodeImage(source);
    if (src == null) return null;
    img.contrast(src, contrast: 150);
    return img.encodeJpg(src, quality: 95);
  }
}
