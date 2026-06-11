import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/isar_service.dart';
import '../database/recent_file_entity.dart';
import '../services/pdf_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService.instance;
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

final _recentFilesRefreshProvider = StateProvider<int>((ref) => 0);

final recentFilesProvider = FutureProvider<List<RecentFileEntity>>((ref) async {
  ref.watch(_recentFilesRefreshProvider);
  final service = ref.watch(isarServiceProvider);
  return service.getRecentFiles();
});

void refreshRecentFiles(WidgetRef ref) {
  ref.read(_recentFilesRefreshProvider.notifier).state++;
}

final recentFilesCountProvider = Provider<int>((ref) {
  final files = ref.watch(recentFilesProvider);
  return files.valueOrNull?.length ?? 0;
});

final pageThumbnailProvider = FutureProvider.family<Uint8List?, (String filePath, int pageIndex)>((ref, params) async {
  final (filePath, pageIndex) = params;
  final pdfService = ref.watch(pdfServiceProvider);
  return pdfService.getThumbnail(filePath, page: pageIndex);
});

final pdfMetadataProvider = FutureProvider.family<PdfMetadata?, String>((ref, filePath) async {
  final pdfService = ref.watch(pdfServiceProvider);
  return pdfService.getMetadata(filePath);
});
