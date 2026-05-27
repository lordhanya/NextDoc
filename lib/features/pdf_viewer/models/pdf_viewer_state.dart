final class PdfViewerState {
  final int currentPage;
  final int totalPages;
  final double zoomLevel;
  final bool isLoading;
  final String? error;

  const PdfViewerState({
    this.currentPage = 0,
    this.totalPages = 0,
    this.zoomLevel = 1.0,
    this.isLoading = true,
    this.error,
  });

  PdfViewerState copyWith({
    int? currentPage,
    int? totalPages,
    double? zoomLevel,
    bool? isLoading,
    String? error,
  }) {
    return PdfViewerState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
