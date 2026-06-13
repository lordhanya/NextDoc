import 'dart:typed_data';
import 'package:image/image.dart' as img;

final class AdjustmentsService {
  Uint8List? adjustBrightness(Uint8List source, double value) {
    final src = img.decodeImage(source);
    if (src == null) return null;
    final offset = (value * 255).toInt();
    img.colorOffset(src, red: offset, green: offset, blue: offset);
    return img.encodeJpg(src, quality: 95);
  }

  Uint8List? adjustContrast(Uint8List source, double value) {
    final src = img.decodeImage(source);
    if (src == null) return null;
    final contrastVal = 100 + (value * 100).toInt();
    img.contrast(src, contrast: contrastVal);
    return img.encodeJpg(src, quality: 95);
  }

  Uint8List? adjustSaturation(Uint8List source, double value) {
    final src = img.decodeImage(source);
    if (src == null) return null;
    img.adjustColor(src, saturation: 1.0 + value);
    return img.encodeJpg(src, quality: 95);
  }

  Uint8List? adjustSharpness(Uint8List source, double value) {
    final src = img.decodeImage(source);
    if (src == null) return null;

    if (value > 0) {
      final blurred = src.clone();
      img.smooth(blurred, weight: 3.0);
      final amount = value;
      for (int y = 0; y < src.height; y++) {
        for (int x = 0; x < src.width; x++) {
          final sp = src.getPixel(x, y);
          final bp = blurred.getPixel(x, y);
          final sr = sp.r.toInt();
          final sg = sp.g.toInt();
          final sb = sp.b.toInt();
          final br = bp.r.toInt();
          final bg = bp.g.toInt();
          final bb = bp.b.toInt();
          src.setPixelRgba(
            x, y,
            (sr + ((sr - br) * amount).round()).clamp(0, 255),
            (sg + ((sg - bg) * amount).round()).clamp(0, 255),
            (sb + ((sb - bb) * amount).round()).clamp(0, 255),
            sp.a.toInt(),
          );
        }
      }
    } else if (value < 0) {
      final weight = 1.0 + (-value) * 2;
      img.smooth(src, weight: weight);
    }

    return img.encodeJpg(src, quality: 95);
  }
}
