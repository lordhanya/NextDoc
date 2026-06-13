import 'dart:typed_data';
import 'package:image/image.dart' as img;

final class PageNumbersService {
  Uint8List? addPageNumber({
    required Uint8List sourceBytes,
    required int pageNumber,
    int startNumber = 1,
    String position = 'bottomRight',
    double fontSize = 24,
    int colorR = 100,
    int colorG = 100,
    int colorB = 100,
  }) {
    final src = img.decodeImage(sourceBytes);
    if (src == null) return null;

    final font = fontSize >= 48 ? img.arial48 : (fontSize >= 24 ? img.arial24 : img.arial14);
    final text = '${startNumber + pageNumber}';
    final charW = fontSize / 48 * 24;
    final textWidth = (text.length * charW).toInt();
    final textHeight = fontSize.toInt();

    final margin = 20;
    int cx, cy;
    switch (position) {
      case 'topLeft':
        cx = margin;
        cy = margin;
      case 'topRight':
        cx = src.width - textWidth - margin;
        cy = margin;
      case 'bottomLeft':
        cx = margin;
        cy = src.height - textHeight - margin;
      case 'center':
        cx = (src.width - textWidth) ~/ 2;
        cy = (src.height - textHeight) ~/ 2;
      case 'bottomRight':
      default:
        cx = src.width - textWidth - margin;
        cy = src.height - textHeight - margin;
    }

    final color = img.ColorRgba8(colorR, colorG, colorB, 200);
    img.drawString(src, text, font: font, x: cx, y: cy, color: color);

    return img.encodeJpg(src, quality: 95);
  }
}
