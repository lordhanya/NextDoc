import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final class PdfReadingService {
  static const _key = 'pdf_last_pages';

  static final PdfReadingService instance = PdfReadingService._();
  PdfReadingService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Map<String, int> _getAll() {
    final raw = _prefs?.getString(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  int? getLastPage(String filePath) {
    return _getAll()[filePath];
  }

  Future<void> saveLastPage(String filePath, int page) async {
    final all = _getAll();
    all[filePath] = page;
    await _prefs?.setString(_key, jsonEncode(all));
  }
}
