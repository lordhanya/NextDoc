import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pdf_viewer_state.dart';

final pdfViewerProvider =
    StateNotifierProvider.family<PdfViewerNotifier, PdfViewerState, String>(
  (ref, filePath) => PdfViewerNotifier(),
);

final class PdfViewerNotifier extends StateNotifier<PdfViewerState> {
  PdfViewerNotifier() : super(const PdfViewerState());

  void setTotalPages(int totalPages) {
    state = state.copyWith(totalPages: totalPages, isLoading: false);
  }

  void goToPage(int page) {
    if (page < 0 || page >= state.totalPages) return;
    state = state.copyWith(currentPage: page);
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoomLevel: zoom.clamp(0.5, 5.0));
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void reset() {
    state = const PdfViewerState();
  }
}
