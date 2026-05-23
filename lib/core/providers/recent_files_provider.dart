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

final pdfThumbnailProvider = FutureProvider.family<Uint8List?, String>((ref, filePath) async {
  final pdfService = ref.watch(pdfServiceProvider);
  return pdfService.getThumbnail(filePath);
});

final pdfMetadataProvider = FutureProvider.family<PdfMetadata?, String>((ref, filePath) async {
  final pdfService = ref.watch(pdfServiceProvider);
  return pdfService.getMetadata(filePath);
});
