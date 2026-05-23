import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'recent_file_entity.dart';

final class IsarService {
  Isar? _isar;

  IsarService._();

  static final IsarService instance = IsarService._();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [RecentFileEntitySchema],
      directory: dir.path,
    );
  }

  bool get isInitialized => _isar != null;

  Future<void> saveRecentFile(RecentFileEntity file) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.recentFileEntitys.put(file);
    });
  }

  Future<List<RecentFileEntity>> getRecentFiles({int limit = 20}) async {
    if (_isar == null) return [];
    return _isar!.recentFileEntitys
        .where()
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
  }

  Future<void> deleteRecentFile(Id id) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.recentFileEntitys.delete(id);
    });
  }

  Future<void> clearAll() async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.recentFileEntitys.clear();
    });
  }

  Isar? get isar => _isar;
}
