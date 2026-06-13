import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pdfx/pdfx.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/services/split_pdf_service.dart';
import '../../../core/theme/typography.dart';
import '../../editor_studio/models/editor_result.dart';
import '../../editor_studio/screens/unified_editor_screen.dart';

final class SplitPdfScreen extends ConsumerStatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  ConsumerState<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

final class _SplitPdfScreenState extends ConsumerState<SplitPdfScreen> {
  final _filePicker = FilePickerService();
  String? _filePath;
  String? _fileName;
  int _totalPages = 0;
  Set<int> _selectedPages = {};
  SplitMode _splitMode = SplitMode.extract;
  bool _loading = false;
  PdfDocument? _pdfDoc;

  @override
  void dispose() {
    _pdfDoc?.close();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await _filePicker.pickPdf();
    if (file == null || !mounted) return;

    setState(() {
      _loading = true;
      _filePath = null;
      _fileName = null;
      _totalPages = 0;
      _selectedPages = {};
    });

    await _pdfDoc?.close();
    _pdfDoc = null;
    _PageThumbnailCache.reset();

    try {
      final doc = await PdfDocument.openFile(file.filePath);
      if (!mounted) {
        await doc.close();
        return;
      }
      _pdfDoc = doc;
      setState(() {
        _filePath = file.filePath;
        _fileName = file.fileName;
        _totalPages = doc.pagesCount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open PDF: $e')),
      );
    }
  }

  void _togglePage(int pageIndex) {
    setState(() {
      if (_selectedPages.contains(pageIndex)) {
        _selectedPages.remove(pageIndex);
      } else {
        _selectedPages.add(pageIndex);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPages = Set.from(List.generate(_totalPages, (i) => i + 1));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPages = {};
    });
  }

  Future<void> _editPdf() async {
    if (_filePath == null) return;

    EditorResult? result;
    await Navigator.of(context).push<EditorResult>(
      MaterialPageRoute(
        builder: (_) => UnifiedEditorScreen(
          initialPath: _filePath,
          onSave: (r) => result = r,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _filePath = result!.filePath;
        _fileName = _fileName?.replaceAll('.pdf', '_edited.pdf');
        _totalPages = result!.pageCount;
      });
    }
  }

  void _startSplit() {
    if (_filePath == null || _selectedPages.isEmpty) return;

    final sortedPages = _selectedPages.toList()..sort();
    context.push('/processing', extra: {
      'type': 'split',
      'path': _filePath,
      'fileName': _fileName ?? 'document.pdf',
      'selectedPages': sortedPages,
      'splitMode': _splitMode.name,
      'totalPages': _totalPages,
    });
  }

  void _showModeInfo() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    LucideIcons.scissors,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('Split Modes', style: AppTextStyles.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _infoRow(
              'Extract',
              'Combine selected pages into a single new PDF file.\nExample: pages 1, 3, 5 → one PDF with those 3 pages.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _infoRow(
              'Split All',
              'Export each selected page as its own separate PDF file.\nExample: pages 1, 2, 3 → three PDFs (page_1, page_2, page_3).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String description) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodySmall.copyWith(
                color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Split PDF',
          style: AppTextStyles.title,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_filePath == null && !_loading)
              Expanded(child: _buildPicker())
            else if (_loading)
              const Expanded(child: _LoadingState())
            else
              Expanded(child: _buildContent()),
            if (_filePath != null && !_loading)
              _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxxl + AppSpacing.xl,
              horizontal: AppSpacing.xxl,
            ),
            decoration: BoxDecoration(
              color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    LucideIcons.scissors,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Select PDF File',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Split a PDF into multiple separate files',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(LucideIcons.file_up, size: 18),
                  label: const Text('Select PDF File'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: AppSpacing.md,
                    ),
                    side: BorderSide(color: AppColors.primary.withAlpha(60)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildFileHeader(),
        _buildModeSelector(),
        Expanded(child: _buildPageGrid()),
      ],
    );
  }

  Widget _buildFileHeader() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              LucideIcons.file_text,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? '',
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '$_totalPages page${_totalPages > 1 ? 's' : ''}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _pickFile,
            icon: const Icon(LucideIcons.refresh_cw, size: 16),
            label: const Text('Change'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Row(
        children: [
          _ModeChip(
            label: 'Extract',
            selected: _splitMode == SplitMode.extract,
            onTap: () => setState(() => _splitMode = SplitMode.extract),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ModeChip(
            label: 'Split All',
            selected: _splitMode == SplitMode.splitAll,
            onTap: () => setState(() => _splitMode = SplitMode.splitAll),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: _showModeInfo,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
                  width: 0.5,
                ),
              ),
              child: Icon(
                LucideIcons.info,
                size: 14,
                color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
              ),
            ),
          ),
          const Spacer(),
          _SelectionButton(
            label: 'All',
            onTap: _selectAll,
          ),
          const SizedBox(width: AppSpacing.sm),
          _SelectionButton(
            label: 'None',
            onTap: _deselectAll,
          ),
        ],
      ),
    );
  }

  Widget _buildPageGrid() {
    if (_totalPages == 0) {
      return Center(child: Text('No pages', style: AppTextStyles.bodySmall));
    }

    final crossAxisCount = MediaQuery.of(context).size.width < 360 ? 2 : 3;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.72,
      ),
      itemCount: _totalPages,
      itemBuilder: (context, index) {
        final pageIndex = index + 1;
        final isSelected = _selectedPages.contains(pageIndex);
        return _PageTile(
          pageIndex: pageIndex,
          isSelected: isSelected,
          pdfDoc: _pdfDoc,
          filePath: _filePath ?? '',
          onTap: _totalPages <= 100 ? () => _togglePage(pageIndex) : null,
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final count = _selectedPages.length;
    final hasFile = _filePath != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface1,
        border: Border(
          top: BorderSide(
            color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(30),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasFile)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _editPdf,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.iconEditorStudio,
                      side: BorderSide(color: AppColors.iconEditorStudio.withAlpha(80)),
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text('Edit Before Split', style: AppTextStyles.button),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: count > 0 ? _startSplit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
                  foregroundColor: AppColors.onPrimary,
                  disabledForegroundColor: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  count > 0
                      ? 'Split $_splitModeLabel ($count page${count > 1 ? 's' : ''})'
                      : 'Select pages to split',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _splitModeLabel {
    return _splitMode == SplitMode.extract ? 'Extract' : 'All';
  }
}

final class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: AppColors.primary,
      ),
    );
  }
}

final class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(30) : (isLight ? AppColors.lightSurface1 : AppColors.darkSurface2),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.primary : (isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

final class _SelectionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SelectionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}

final class _PageThumbnailCache {
  _PageThumbnailCache._();

  static final Map<String, Uint8List?> _cache = {};

  static Uint8List? get(int pageIndex, String filePath) {
    return _cache['$filePath:$pageIndex'];
  }

  static void set(int pageIndex, String filePath, Uint8List? bytes) {
    if (_cache.length > 200) {
      _cache.clear();
    }
    _cache['$filePath:$pageIndex'] = bytes;
  }

  static void reset() {
    _cache.clear();
  }
}

final class _PageTile extends StatefulWidget {
  final int pageIndex;
  final bool isSelected;
  final PdfDocument? pdfDoc;
  final String filePath;
  final VoidCallback? onTap;

  const _PageTile({
    required this.pageIndex,
    required this.isSelected,
    this.pdfDoc,
    required this.filePath,
    this.onTap,
  });

  @override
  State<_PageTile> createState() => _PageTileState();
}

final class _PageTileState extends State<_PageTile> {
  Uint8List? _thumbnail;
  bool _loadingThumbnail = false;
  bool _thumbnailLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(_PageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfDoc != widget.pdfDoc) {
      _thumbnail = null;
      _loadingThumbnail = false;
      _thumbnailLoaded = false;
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    final doc = widget.pdfDoc;
    final filePath = widget.filePath;
    if (doc == null || filePath.isEmpty || _thumbnailLoaded) return;

    final cached = _PageThumbnailCache.get(widget.pageIndex, filePath);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _thumbnail = cached;
          _thumbnailLoaded = true;
        });
      }
      return;
    }

    if (_loadingThumbnail) return;
    _loadingThumbnail = true;

    try {
      final page = await doc.getPage(widget.pageIndex);
      final image = await page.render(
        width: 400,
        height: 560,
        format: PdfPageImageFormat.jpeg,
        quality: 60,
        backgroundColor: '#FFFFFF',
      );
      await page.close();

      if (image != null) {
        _PageThumbnailCache.set(widget.pageIndex, filePath, image.bytes);
        if (mounted) {
          setState(() {
            _thumbnail = image.bytes;
            _thumbnailLoaded = true;
          });
        }
      } else {
        _PageThumbnailCache.set(widget.pageIndex, filePath, null);
        if (mounted) {
          setState(() => _thumbnailLoaded = true);
        }
      }
    } catch (_) {
      _PageThumbnailCache.set(widget.pageIndex, filePath, null);
      if (mounted) {
        setState(() => _thumbnailLoaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final showThumbnail = _thumbnail != null;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: isSelected ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withAlpha(15)
                : (isLight ? AppColors.lightSurface1 : AppColors.darkSurface2),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(40),
              width: isSelected ? 2 : 0.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(40),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (showThumbnail)
                          Image.memory(
                            _thumbnail!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          )
                        else
                          Container(
                            color: isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
                            child: _loadingThumbnail
                                ? Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 28,
                                    color: isSelected
                                        ? AppColors.primary.withAlpha(120)
                                        : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(60),
                                  ),
                          ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.onPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, AppSpacing.xxs, 0, AppSpacing.xs),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withAlpha(25)
                        : (isLight ? AppColors.lightSurface2 : AppColors.darkSurface2).withAlpha(120),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${widget.pageIndex}',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: isSelected
                          ? AppColors.primary
                          : (isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
