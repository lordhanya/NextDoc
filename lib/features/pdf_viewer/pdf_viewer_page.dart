import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/typography.dart';
import 'dart:io';
import '../../core/services/pdf_reading_service.dart';
import 'providers/pdf_controller_provider.dart';
import 'providers/pdf_document_provider.dart';
import 'widgets/pdf_app_bar.dart';
import 'widgets/pdf_page_widget.dart';
import 'widgets/thumbnail_strip.dart';

final class PdfViewerPage extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;
  final int fileSize;
  final int pageCount;
  final String? password;
  final bool isTempFile;

  const PdfViewerPage({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
    this.password,
    this.isTempFile = false,
  });

  @override
  ConsumerState<PdfViewerPage> createState() => _PdfViewerPageState();
}

final class _PdfViewerPageState extends ConsumerState<PdfViewerPage> {
  final PageController _pageController = PageController();
  bool _isReadingMode = false;
  bool _showControls = true;
  double _overlayBrightness = 1.0;
  bool _didRestorePage = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = _pageController.page;
    if (page != null) {
      ref.read(pdfViewerProvider(widget.filePath).notifier).goToPage(page.round());
    }
  }

  void _toggleReadingMode() {
    setState(() {
      _isReadingMode = !_isReadingMode;
      _showControls = !_isReadingMode;
    });
  }

  void _showBrightnessSlider() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BrightnessSlider(
        initial: _overlayBrightness,
        onChanged: (v) => setState(() => _overlayBrightness = v),
      ),
    );
  }

  void _showPageJumpDialog() {
    final viewerState = ref.read(pdfViewerProvider(widget.filePath));
    showDialog(
      context: context,
      builder: (ctx) => _JumpToPageDialog(
        currentPage: viewerState.currentPage,
        totalPages: viewerState.totalPages,
        onGo: _goToPage,
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    final viewerState = ref.read(pdfViewerProvider(widget.filePath));
    if (viewerState.totalPages > 0) {
      PdfReadingService.instance.saveLastPage(
        widget.filePath,
        viewerState.currentPage,
      );
    }
    super.dispose();
    _pageController.dispose();
    if (widget.isTempFile) {
      File(widget.filePath).delete().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final docAsync = ref.watch(pdfDocumentProvider((widget.filePath, widget.password)));
    final viewerState = ref.watch(pdfViewerProvider(widget.filePath));

    if (!_didRestorePage && docAsync.hasValue) {
      final doc = docAsync.valueOrNull;
      if (doc != null && !doc.isClosed && viewerState.isLoading && doc.pagesCount > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(pdfViewerProvider(widget.filePath).notifier).setTotalPages(doc.pagesCount);
          final lastPage = PdfReadingService.instance.getLastPage(widget.filePath);
          if (lastPage != null && lastPage < doc.pagesCount) {
            _goToPage(lastPage);
          }
        });
        _didRestorePage = true;
      }
    }

    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 250),
                  offset: _isReadingMode && !_showControls
                      ? const Offset(0, -1)
                      : Offset.zero,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _isReadingMode && !_showControls ? 0 : 1,
                    child: PdfAppBar(
                      filePath: widget.filePath,
                      fileName: widget.fileName,
                      fileSize: widget.fileSize,
                      pageCount: widget.pageCount,
                      ref: ref,
                      isReadingMode: _isReadingMode,
                      onReadingModeToggle: _toggleReadingMode,
                      onPageJump: _showPageJumpDialog,
                      onBrightnessTap: _showBrightnessSlider,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _isReadingMode
                        ? () => setState(() => _showControls = !_showControls)
                        : null,
                    child: docAsync.when(
                      data: (doc) {
                        if (doc == null || doc.isClosed) {
                          return _EmptyStateView(
                            icon: LucideIcons.file_x,
                            title: 'Document Unavailable',
                            subtitle: 'The document is no longer accessible.',
                            isLight: isLight,
                          );
                        }
                        if (doc.pagesCount <= 0) {
                          return _EmptyStateView(
                            icon: LucideIcons.file_text,
                            title: 'Empty Document',
                            subtitle: 'This PDF contains no pages.',
                            isLight: isLight,
                          );
                        }
                        final totalPages = doc.pagesCount;
                        return PageView.builder(
                          controller: _pageController,
                          itemCount: totalPages,
                          itemBuilder: (context, index) {
                            return PdfPageWidget(
                              document: doc,
                              pageIndex: index,
                              zoomLevel: viewerState.zoomLevel,
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, _) => _LoadErrorView(
                        error: err,
                        filePath: widget.filePath,
                        isLight: isLight,
                        onRetry: () {
                          ref.invalidate(pdfDocumentProvider((widget.filePath, widget.password)));
                          _didRestorePage = false;
                        },
                      ),
                    ),
                  ),
                ),
                if (viewerState.totalPages > 0)
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 250),
                    offset: _isReadingMode && !_showControls
                        ? const Offset(0, 1)
                        : Offset.zero,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _isReadingMode && !_showControls ? 0 : 1,
                      child: ThumbnailStrip(
                        filePath: widget.filePath,
                        totalPages: viewerState.totalPages,
                        currentPage: viewerState.currentPage,
                        onPageTap: _goToPage,
                      ),
                    ),
                  ),
              ],
            ),
            if (_overlayBrightness < 1.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.black.withAlpha(((1.0 - _overlayBrightness) * 200).round())),
                ),
              ),
            if (_isReadingMode && _showControls)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface2.withAlpha(200),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Icon(LucideIcons.x, size: 18, color: AppColors.darkTextPrimary),
                  ),
                  onPressed: _toggleReadingMode,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _BrightnessSlider extends StatefulWidget {
  final double initial;
  final ValueChanged<double> onChanged;

  const _BrightnessSlider({
    required this.initial,
    required this.onChanged,
  });

  @override
  State<_BrightnessSlider> createState() => _BrightnessSliderState();
}

final class _BrightnessSliderState extends State<_BrightnessSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface1,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isLight ? AppColors.lightBorder : AppColors.darkBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sun, size: 18, color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted),
              Expanded(
                child: Slider(
                  value: _value,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  activeColor: AppColors.primary,
                  inactiveColor: isLight ? AppColors.lightBorder : AppColors.darkBorder,
                  onChanged: (v) {
                    setState(() => _value = v);
                    widget.onChanged(v);
                  },
                ),
              ),
              Icon(LucideIcons.moon, size: 18, color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted),
            ],
          ),
            Text(
              '${(_value * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
              ),
            ),
          ],
        ),
      );
  }
}

final class _JumpToPageDialog extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onGo;

  const _JumpToPageDialog({
    required this.currentPage,
    required this.totalPages,
    required this.onGo,
  });

  @override
  State<_JumpToPageDialog> createState() => _JumpToPageDialogState();
}

final class _JumpToPageDialogState extends State<_JumpToPageDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: '${widget.currentPage + 1}',
    );
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleGo() {
    final page = int.tryParse(_controller.text.trim());
    if (page != null && page >= 1 && page <= widget.totalPages) {
      widget.onGo(page - 1);
    }
    Navigator.of(context).pop();
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return AlertDialog(
      backgroundColor: isLight ? AppColors.lightSurface1 : AppColors.darkSurface1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: Text(
        'Jump to Page',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
        ),
      ),
      content: SizedBox(
        width: 200,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 - ${widget.totalPages}',
            hintStyle: TextStyle(
              color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
            ),
            filled: true,
            fillColor: isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(
            color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _handleCancel,
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
            ),
          ),
        ),
        FilledButton(
          onPressed: _handleGo,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Go', style: TextStyle(color: AppColors.onPrimary)),
        ),
      ],
    );
  }
}

final class _LoadErrorView extends StatelessWidget {
  final Object error;
  final String filePath;
  final bool isLight;
  final VoidCallback onRetry;

  const _LoadErrorView({
    required this.error,
    required this.filePath,
    required this.isLight,
    required this.onRetry,
  });

  String get _title {
    if (error is PdfDocumentException) return (error as PdfDocumentException).title;
    return 'Failed to Open PDF';
  }

  String get _description {
    if (error is PdfDocumentException) return (error as PdfDocumentException).description;
    return 'An unexpected error occurred.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.file_x,
              size: 56,
              color: (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(100),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _title,
              style: AppTextStyles.title.copyWith(
                color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _description,
              style: AppTextStyles.bodySmall.copyWith(
                color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refresh_cw, size: 18),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

final class _EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLight;

  const _EmptyStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(80),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
