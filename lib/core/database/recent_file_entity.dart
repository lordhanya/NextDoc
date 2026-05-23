import 'package:isar/isar.dart';

part 'recent_file_entity.g.dart';

@collection
final class RecentFileEntity {
  Id id = Isar.autoIncrement;

  late String fileName;

  late String filePath;

  late int fileSize;

  late String fileType;

  late DateTime createdAt;

  int pageCount;

  RecentFileEntity({
    this.id = -1,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.createdAt,
    this.pageCount = 0,
  });
}
