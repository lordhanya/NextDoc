import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

final class MetadataService {
  static const String appName = 'NextDoc';
  static const String developer = 'ASHIFCODES';
  static const String pdfEngine = 'NextDoc PDF Engine';

  static pw.Document createPdfDocument({
    String? title,
    String? subject,
    String? keywords,
  }) {
    return pw.Document(
      title: title ?? 'NextDoc Document',
      author: developer,
      creator: appName,
      subject: subject ?? 'Created with $appName',
      keywords: keywords ?? '$appName, PDF',
      producer: pdfEngine,
    );
  }

  static Uint8List injectJpegExif(Uint8List jpegBytes, {int quality = 95}) {
    try {
      final image = img.decodeImage(jpegBytes);
      if (image == null) return jpegBytes;

      image.exif.imageIfd.software = appName;
      image.exif.imageIfd.imageDescription = 'Created with $appName';
      image.exif.imageIfd.copyright = developer;
      image.exif.imageIfd[0x013B] = developer;

      return img.encodeJpg(image, quality: quality);
    } catch (_) {
      return jpegBytes;
    }
  }
}
