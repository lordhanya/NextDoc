import 'dart:typed_data';
import 'package:image/image.dart' as img;

final class WatermarkService {
  Uint8List? applyTextWatermark({
    required Uint8List sourceBytes,
    required String text,
    double opacity = 0.3,
    int rotation = 0,
    String position = 'center',
    double fontSize = 48,
    int colorR = 180,
    int colorG = 180,
    int colorB = 180,
  }) {
    final src = img.decodeImage(sourceBytes);
    if (src == null) return null;

    final font = fontSize >= 48 ? img.arial48 : (fontSize >= 24 ? img.arial24 : img.arial14);
    final charW = fontSize / 48 * 24;
    final textWidth = (text.length * charW).toInt();
    final textHeight = fontSize.toInt();
    final alpha = (opacity * 255).toInt().clamp(0, 255);
    final color = img.ColorRgba8(
      colorR.clamp(0, 255),
      colorG.clamp(0, 255),
      colorB.clamp(0, 255),
      alpha,
    );

    if (rotation == 0) {
      final cx = _positionX(position, src.width, textWidth);
      final cy = _positionY(position, src.height, textHeight);
      img.drawString(src, text, font: font, x: cx, y: cy, color: color);
      return img.encodeJpg(src, quality: 95);
    }

    // For rotated: draw on a small transparent text-sized image, rotate, then composite
    final margin = 20;
    final wmW = textWidth + margin * 2;
    final wmH = textHeight + margin * 2;
    final wm = img.Image(width: wmW, height: wmH);
    img.drawString(wm, text, font: font, x: margin, y: margin, color: color);

    final rotated = img.copyRotate(wm, angle: rotation);
    final cx = _positionX(position, src.width, rotated.width);
    final cy = _positionY(position, src.height, rotated.height);

    // Per-pixel alpha blend to avoid compositing artifacts
    for (final p in rotated) {
      final pa = p.a.toInt();
      if (pa > 0) {
        final dstX = cx + p.x;
        final dstY = cy + p.y;
        if (dstX >= 0 && dstX < src.width && dstY >= 0 && dstY < src.height) {
          final sp = src.getPixel(dstX, dstY);
          final dstR = (p.r.toInt() * pa + sp.r.toInt() * (255 - pa)) ~/ 255;
          final dstG = (p.g.toInt() * pa + sp.g.toInt() * (255 - pa)) ~/ 255;
          final dstB = (p.b.toInt() * pa + sp.b.toInt() * (255 - pa)) ~/ 255;
          src.setPixelRgba(dstX, dstY, dstR, dstG, dstB, 255);
        }
      }
    }

    return img.encodeJpg(src, quality: 95);
  }

  Uint8List? applyImageWatermark({
    required Uint8List sourceBytes,
    required Uint8List watermarkBytes,
    double opacity = 0.3,
    int rotation = 0,
    String position = 'center',
    double scale = 0.3,
  }) {
    final src = img.decodeImage(sourceBytes);
    final wmSrc = img.decodeImage(watermarkBytes);
    if (src == null || wmSrc == null) return null;

    final wmW = (src.width * scale).toInt().clamp(50, src.width ~/ 2);
    final wmH = (wmSrc.height * wmW / wmSrc.width).toInt();
    final resizedWm = img.copyResize(wmSrc, width: wmW, height: wmH);

    final alpha = (opacity * 255).toInt().clamp(0, 255);

    // Apply opacity per pixel
    for (final p in resizedWm) {
      final a = (p.a * alpha / 255).toInt().clamp(0, 255);
      resizedWm.setPixelRgba(p.x, p.y, p.r, p.g, p.b, a);
    }

    var finalWm = resizedWm;
    if (rotation != 0) {
      finalWm = img.copyRotate(finalWm, angle: rotation);
    }

    final cx = _positionX(position, src.width, finalWm.width);
    final cy = _positionY(position, src.height, finalWm.height);

    // Per-pixel alpha blend
    for (final p in finalWm) {
      final pa = p.a.toInt();
      if (pa > 0) {
        final dstX = cx + p.x;
        final dstY = cy + p.y;
        if (dstX >= 0 && dstX < src.width && dstY >= 0 && dstY < src.height) {
          final sp = src.getPixel(dstX, dstY);
          final dstR = (p.r.toInt() * pa + sp.r.toInt() * (255 - pa)) ~/ 255;
          final dstG = (p.g.toInt() * pa + sp.g.toInt() * (255 - pa)) ~/ 255;
          final dstB = (p.b.toInt() * pa + sp.b.toInt() * (255 - pa)) ~/ 255;
          src.setPixelRgba(dstX, dstY, dstR, dstG, dstB, 255);
        }
      }
    }

    return img.encodeJpg(src, quality: 95);
  }

  int _positionX(String position, int imageW, int wmW) {
    switch (position) {
      case 'topLeft':
      case 'bottomLeft':
        return 20;
      case 'topRight':
      case 'bottomRight':
        return imageW - wmW - 20;
      case 'topCenter':
      case 'bottomCenter':
        return (imageW - wmW) ~/ 2;
      case 'center':
      default:
        return (imageW - wmW) ~/ 2;
    }
  }

  int _positionY(String position, int imageH, int wmH) {
    switch (position) {
      case 'topLeft':
      case 'topRight':
      case 'topCenter':
        return 20;
      case 'bottomLeft':
      case 'bottomRight':
      case 'bottomCenter':
        return imageH - wmH - 20;
      case 'center':
      default:
        return (imageH - wmH) ~/ 2;
    }
  }
}
