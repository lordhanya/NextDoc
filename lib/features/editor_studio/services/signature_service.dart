import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SignatureService {
  static const String _savedKey = 'editor_saved_signature_path';

  Future<void> saveSignature(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/nextdoc_signature.png';
    await File(path).writeAsBytes(bytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedKey, path);
  }

  Future<Uint8List?> loadSavedSignature() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_savedKey);
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<bool> hasSavedSignature() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_savedKey);
    if (path == null) return false;
    return File(path).exists();
  }

  Future<void> deleteSavedSignature() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_savedKey);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
      await prefs.remove(_savedKey);
    }
  }

  Uint8List? applySignature({
    required Uint8List sourceBytes,
    required Uint8List signatureBytes,
    int offsetX = 100,
    int offsetY = 100,
    double scale = 1.0,
  }) {
    final src = img.decodeImage(sourceBytes);
    final sig = img.decodeImage(signatureBytes);
    if (src == null || sig == null) return null;

    final baseW = (src.width * 0.3).toInt().clamp(50, 300);
    final sigW = (baseW * scale).toInt().clamp(20, src.width);
    final sigH = (sig.height * sigW / sig.width).toInt();
    final resized = img.copyResize(sig, width: sigW, height: sigH);

    final x = offsetX.clamp(0, src.width - sigW);
    final y = offsetY.clamp(0, src.height - sigH);

    return img.encodeJpg(
      img.compositeImage(src, resized, dstX: x, dstY: y),
      quality: 95,
    );
  }
}
