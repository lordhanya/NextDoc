import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/services/file_storage_service.dart';
import '../models/editor_history.dart';
import '../models/editor_tool.dart';
import '../services/adjustments_service.dart';
import '../services/filters_service.dart';
import '../services/image_editor_service.dart';
import '../services/page_numbers_service.dart';
import '../services/pdf_editor_service.dart';
import '../services/signature_service.dart';
import '../services/watermark_service.dart';
import '../widgets/adjustments_panel.dart';
import '../widgets/filters_panel.dart';
import '../widgets/page_numbers_panel.dart';
import '../widgets/pages_panel.dart';
import '../widgets/signature_panel.dart';
import '../widgets/watermark_panel.dart';

final class UnifiedEditorScreen extends StatefulWidget {
  final String? initialPath;
  const UnifiedEditorScreen({super.key, this.initialPath});

  @override
  State<UnifiedEditorScreen> createState() => _UnifiedEditorScreenState();
}

final class _UnifiedEditorScreenState extends State<UnifiedEditorScreen> {
  // Document
  String _fileName = '';
  bool _isPdf = false;
  List<Uint8List> _pageImages = [];
  List<int> _pageOrder = [];
  int _currentPage = 0;

  // Services
  final _imageService = ImageEditorService();
  final _pdfService = PdfEditorService();
  final _filtersService = FiltersService();
  final _adjustmentsService = AdjustmentsService();
  final _watermarkService = WatermarkService();
  final _signatureService = SignatureService();
  final _pageNumbersService = PageNumbersService();

  // Editor state
  EditorTool? _activeTool;
  final _history = EditorHistory();

  // InteractiveViewer
  final _transformationController = TransformationController();

  // Filter / adjustment state
  FilterType _currentFilter = FilterType.original;
  double _brightness = 0, _contrast = 0, _saturation = 0, _sharpness = 0;

  // Watermark state
  WatermarkSettings _watermarkSettings = const WatermarkSettings();

  // Page numbers state
  String _pnPosition = 'bottomRight';
  double _pnFontSize = 24;
  Color _pnColor = const Color(0xFF646464);
  int _pnStartNumber = 1;

  // Signature drag-to-position state
  Uint8List? _pendingSigBytes;
  Offset _sigOffset = const Offset(100, 100);
  bool _sigPlacing = false;
  double _sigScale = 1.0;
  double _sigStartScale = 1.0;
  Offset _sigStartOffset = Offset.zero;

  // UI state
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null) {
      _openFile(widget.initialPath!);
    } else {
      _pickFile();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final path = result.files.single.path;
    if (path == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _fileName = result.files.single.name;
    await _openFile(path);
  }

  Future<void> _openFile(String path) async {
    setState(() => _isLoading = true);

    final ext = path.split('.').last.toLowerCase();
    _isPdf = ext == 'pdf';

    try {
      if (_isPdf) {
        final renderResult = await _pdfService.renderAllPages(path);
        _pageImages = renderResult.pageImages;
        _pageOrder = List.generate(renderResult.pageCount, (i) => i);
        _currentPage = 0;
      } else {
        final bytes = await _imageService.decodeImageBytes(path);
        _pageImages = [bytes];
        _pageOrder = [0];
        _currentPage = 0;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open file: $e'), backgroundColor: AppColors.error),
      );
      Navigator.of(context).pop();
      return;
    }

    _pushHistory();
    setState(() => _isLoading = false);
  }

  // ---- History ----

  void _pushHistory() {
    _history.pushState(EditorState(
      pages: _pageImages.map((b) => b).toList(),
      currentPage: _currentPage,
    ));
  }

  void _undo() {
    final state = _history.undo();
    if (state == null) return;
    setState(() {
      _pageImages = state.pages;
      _currentPage = state.currentPage;
      _activeTool = null;
      _sigPlacing = false;
      _pendingSigBytes = null;
    });
  }

  void _redo() {
    final state = _history.redo();
    if (state == null) return;
    setState(() {
      _pageImages = state.pages;
      _currentPage = state.currentPage;
      _activeTool = null;
      _sigPlacing = false;
      _pendingSigBytes = null;
    });
  }

  // ---- Tool selection ----

  void _selectTool(EditorTool tool) {
    if (_activeTool == tool) {
      setState(() => _activeTool = null);
      return;
    }
    if (tool == EditorTool.rotate ||
        tool == EditorTool.flip) {
      return;
    }
    _transformationController.value = Matrix4.identity();
    setState(() {
      _activeTool = tool;
      _sigPlacing = false;
      _pendingSigBytes = null;
    });
  }

  // ---- Page helpers ----

  Uint8List? get _currentBytes =>
      _currentPage < _pageImages.length ? _pageImages[_currentPage] : null;

  void _replaceCurrentPage(Uint8List bytes) {
    if (_currentPage >= _pageImages.length) return;
    setState(() {
      _pageImages[_currentPage] = bytes;
    });
  }

  // ---- Crop (native uCrop) ----

  Future<void> _cropCurrentPage() async {
    if (_currentBytes == null) return;
    setState(() => _isLoading = true);

    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final inputPath = '${tempDir.path}/nextdoc_crop_input_$timestamp.jpg';
      await File(inputPath).writeAsBytes(_currentBytes!);

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: inputPath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            statusBarLight: false,
            navBarLight: false,
            activeControlsWidgetColor: const Color(0xFF8B5CF6),
            cropFrameColor: const Color(0xFF8B5CF6),
            cropFrameStrokeWidth: 3,
            cropGridColor: Colors.white54,
            cropGridStrokeWidth: 1,
            dimmedLayerColor: const Color(0x80000000),
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            showCropGrid: true,
            hideBottomControls: false,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      try { await File(inputPath).delete(); } catch (_) {}

      if (croppedFile != null) {
        final croppedBytes = await croppedFile.readAsBytes();
        _replaceCurrentPage(croppedBytes);
        _pushHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Image cropped'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFF8B5CF6),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Crop failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- Rotate / Flip (instant) ----

  void _rotateLeft() {
    if (_currentBytes == null) return;
    final result = _imageService.rotateImage(_currentBytes!, degrees: 270);
    if (result == null) return;
    _replaceCurrentPage(result);
    _pushHistory();
  }

  void _rotateRight() {
    if (_currentBytes == null) return;
    final result = _imageService.rotateImage(_currentBytes!, degrees: 90);
    if (result == null) return;
    _replaceCurrentPage(result);
    _pushHistory();
  }

  void _flipH() {
    if (_currentBytes == null) return;
    final result = _imageService.flipHorizontal(_currentBytes!);
    if (result == null) return;
    _replaceCurrentPage(result);
    _pushHistory();
  }

  void _flipV() {
    if (_currentBytes == null) return;
    final result = _imageService.flipVertical(_currentBytes!);
    if (result == null) return;
    _replaceCurrentPage(result);
    _pushHistory();
  }

  // ---- Filter ----

  void _applyFilter(FilterType type) {
    if (_currentBytes == null) return;
    Uint8List? result;
    switch (type) {
      case FilterType.original:
        result = _currentBytes;
      case FilterType.grayscale:
        result = _filtersService.applyGrayscale(_currentBytes!);
      case FilterType.blackAndWhite:
        result = _filtersService.applyBlackAndWhite(_currentBytes!);
      case FilterType.sepia:
        result = _filtersService.applySepia(_currentBytes!);
      case FilterType.highContrast:
        result = _filtersService.applyHighContrast(_currentBytes!);
    }
    if (result == null) return;
    _currentFilter = type;
    _replaceCurrentPage(result);
    _pushHistory();
  }

  // ---- Adjustments ----

  void _applyBrightness(double v) {
    if (_currentBytes == null) return;
    setState(() => _brightness = v);
    final result = _adjustmentsService.adjustBrightness(_currentBytes!, v);
    if (result != null) _replaceCurrentPage(result);
  }

  void _applyContrast(double v) {
    if (_currentBytes == null) return;
    setState(() => _contrast = v);
    final result = _adjustmentsService.adjustContrast(_currentBytes!, v);
    if (result != null) _replaceCurrentPage(result);
  }

  void _applySaturation(double v) {
    if (_currentBytes == null) return;
    setState(() => _saturation = v);
    final result = _adjustmentsService.adjustSaturation(_currentBytes!, v);
    if (result != null) _replaceCurrentPage(result);
  }

  void _applySharpness(double v) {
    if (_currentBytes == null) return;
    setState(() => _sharpness = v);
    final result = _adjustmentsService.adjustSharpness(_currentBytes!, v);
    if (result != null) _replaceCurrentPage(result);
  }

  // ---- Watermark ----

  void _applyWatermark() {
    if (_currentBytes == null || _watermarkSettings.text.isEmpty) return;
    final result = _watermarkService.applyTextWatermark(
      sourceBytes: _currentBytes!,
      text: _watermarkSettings.text,
      opacity: _watermarkSettings.opacity,
      rotation: _watermarkSettings.rotation,
      position: _watermarkSettings.position,
      fontSize: _watermarkSettings.fontSize,
      colorR: _watermarkSettings.colorR,
      colorG: _watermarkSettings.colorG,
      colorB: _watermarkSettings.colorB,
    );
    if (result == null) return;
    _replaceCurrentPage(result);
    _pushHistory();
  }

  // ---- Signature (drag-to-position flow) ----

  void _onSignatureCreated(Uint8List? bytes) {
    _pendingSigBytes = bytes;
  }

  void _onSignaturePanelApply() {
    if (_pendingSigBytes == null) return;

    setState(() {
      _sigPlacing = true;
      _activeTool = null;
      _sigOffset = const Offset(100, 100);
      _sigScale = 1.0;
    });
  }

  void _applySignature() {
    if (_pendingSigBytes == null || _currentBytes == null) return;

    final decoded = img.decodeImage(_currentBytes!);
    if (decoded == null) return;

    final offsetX = _sigOffset.dx.round().clamp(0, decoded.width);
    final offsetY = _sigOffset.dy.round().clamp(0, decoded.height);

    final result = _signatureService.applySignature(
      sourceBytes: _currentBytes!,
      signatureBytes: _pendingSigBytes!,
      offsetX: offsetX,
      offsetY: offsetY,
      scale: _sigScale,
    );
    if (result == null) return;
    _replaceCurrentPage(result);
    _pushHistory();

    setState(() {
      _sigPlacing = false;
      _pendingSigBytes = null;
    });
  }

  void _cancelSignaturePlacement() {
    setState(() {
      _sigPlacing = false;
      _pendingSigBytes = null;
    });
  }

  // ---- Page Numbers ----

  void _applyPageNumbers() {
    final updated = <Uint8List>[];
    for (int i = 0; i < _pageImages.length; i++) {
      final result = _pageNumbersService.addPageNumber(
        sourceBytes: _pageImages[i],
        pageNumber: i,
        startNumber: _pnStartNumber,
        position: _pnPosition,
        fontSize: _pnFontSize,
        colorR: (_pnColor.r * 255).round().clamp(0, 255),
        colorG: (_pnColor.g * 255).round().clamp(0, 255),
        colorB: (_pnColor.b * 255).round().clamp(0, 255),
      );
      updated.add(result ?? _pageImages[i]);
    }
    setState(() => _pageImages = updated);
    _pushHistory();
  }

  // ---- Pages (PDF only) ----

  void _deletePage(int pageIdx) {
    setState(() {
      _pageOrder.remove(pageIdx);
      if (!_pageOrder.contains(_currentPage)) {
        _currentPage = _pageOrder.isNotEmpty ? _pageOrder.first : 0;
      }
      if (_currentPage >= _pageImages.length) {
        _currentPage = _pageImages.length - 1;
      }
    });
  }

  void _duplicatePage(int pageIdx) {
    if (pageIdx >= _pageImages.length) return;
    final bytes = _pageImages[pageIdx];
    setState(() {
      _pageImages.add(Uint8List.fromList(bytes));
      _pageOrder.add(_pageImages.length - 1);
    });
  }

  void _selectPage(int pageIdx) {
    setState(() => _currentPage = pageIdx);
  }

  void _reorderPages(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    setState(() {
      final item = _pageOrder.removeAt(oldIndex);
      _pageOrder.insert(newIndex, item);
    });
  }

  // ---- Save ----

  Future<void> _save() async {
    if (_pageImages.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      String finalPath;
      if (_isPdf) {
        final outPath = await _pdfService.rebuildPdf(
          pageImages: _pageOrder.map((i) => _pageImages[i]).toList(),
          outputFileName: _fileName,
        );
        finalPath = await FileStorageService().copyToDownloads(
          sourcePath: outPath,
          fileName: _fileName,
          toolFolder: 'Editor_Studio',
        );
      } else {
        final baseName = _fileName.replaceAll('.${_fileName.split('.').last}', '');
        final outputName = '${baseName}_edited.jpg';
        final tempDir = await FileStorageService.createTempDir('Editor_Studio');
        final tempPath = '${tempDir.path}/$outputName';
        await File(tempPath).writeAsBytes(_pageImages[0]);
        finalPath = await FileStorageService().copyToDownloads(
          sourcePath: tempPath,
          fileName: outputName,
          toolFolder: 'Editor_Studio',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $finalPath'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surface = isLight ? AppColors.lightSurface1 : AppColors.darkSurface1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(isLight),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(child: _buildPreviewArea(isLight)),
                if (_activeTool != null && _activeTool != EditorTool.signature)
                  _buildToolPanel(isLight, surface),
                if (_activeTool == EditorTool.signature && !_sigPlacing)
                  _buildToolPanel(isLight, surface),
                if (_sigPlacing)
                  _buildPlaceSignatureBar(),
                _buildToolbar(isLight, surface),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isLight) {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fileName,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          if (_isPdf && _pageOrder.length > 1)
            Text(
              'Page ${_currentPage + 1} of ${_pageOrder.length}',
              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.undo_rounded, color: _history.canUndo ? Colors.white : Colors.white24),
          onPressed: _history.canUndo ? _undo : null,
          tooltip: 'Undo',
        ),
        IconButton(
          icon: Icon(Icons.redo_rounded, color: _history.canRedo ? Colors.white : Colors.white24),
          onPressed: _history.canRedo ? _redo : null,
          tooltip: 'Redo',
        ),
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save', style: TextStyle(color: Color(0xFF8B5CF6))),
        ),
      ],
    );
  }

  Widget _buildPreviewArea(bool isLight) {
    if (_currentBytes == null) return const SizedBox();

    final decoded = img.decodeImage(_currentBytes!);
    final imageW = decoded?.width.toDouble() ?? 1;
    final imageH = decoded?.height.toDouble() ?? 1;

    // Calculate signature display size
    Size sigSize = const Size(150, 75);
    if (_pendingSigBytes != null) {
      final sig = img.decodeImage(_pendingSigBytes!);
      if (sig != null) {
        final aspect = sig.width / sig.height;
        sigSize = Size(150, 150 / aspect);
      }
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (_sigPlacing) {
          return Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                panEnabled: true,
                scaleEnabled: true,
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: SizedBox(
                    width: imageW,
                    height: imageH,
                    child: Stack(
                      children: [
                        Image.memory(_currentBytes!, fit: BoxFit.contain),
                        Positioned(
                          left: _sigOffset.dx,
                          top: _sigOffset.dy,
                          child: GestureDetector(
                            onScaleStart: (d) {
                              _sigStartScale = _sigScale;
                              _sigStartOffset = _sigOffset;
                            },
                            onScaleUpdate: (d) {
                              setState(() {
                                if (d.pointerCount > 1) {
                                  _sigScale = (_sigStartScale * d.scale)
                                      .clamp(0.3, 3.0);
                                }
                                final scaledW = sigSize.width * _sigScale;
                                final scaledH = sigSize.height * _sigScale;
                                _sigOffset = Offset(
                                  (_sigStartOffset.dx + d.focalPointDelta.dx)
                                      .clamp(0, imageW - scaledW),
                                  (_sigStartOffset.dy + d.focalPointDelta.dy)
                                      .clamp(0, imageH - scaledH),
                                );
                              });
                            },
                            onScaleEnd: (_) {},
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.iconEditorStudio, width: 2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Transform.scale(
                                scale: _sigScale,
                                alignment: Alignment.center,
                                child: Image.memory(
                                  _pendingSigBytes!,
                                  width: sigSize.width,
                                  height: sigSize.height,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return InteractiveViewer(
          transformationController: _transformationController,
          panEnabled: true,
          scaleEnabled: true,
          minScale: 1,
          maxScale: 5,
          child: Center(
            child: Image.memory(
              _currentBytes!,
              width: imageW,
              height: imageH,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolPanel(bool isLight, Color surface) {
    final tool = _activeTool!;
    final screenH = MediaQuery.of(context).size.height;
    final maxPanelH = (screenH - kToolbarHeight - MediaQuery.of(context).padding.top - 44 - MediaQuery.of(context).padding.bottom - 12) * 0.42;

    double prefH;
    Widget panel;
    switch (tool) {
      case EditorTool.crop:
        prefH = 0;
        panel = const SizedBox();
      case EditorTool.pages:
        prefH = 190;
        panel = _isPdf
            ? _buildPagesPanel(isLight)
            : const SizedBox();
      case EditorTool.filters:
        prefH = 120;
        panel = FiltersPanel(
          currentFilter: _currentFilter,
          onFilterChanged: _applyFilter,
          previewBytes: _currentBytes,
        );
      case EditorTool.adjustments:
        prefH = 210;
        panel = AdjustmentsPanel(
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
          sharpness: _sharpness,
          onBrightnessChanged: (v) {
            _brightness = v;
            _applyBrightness(v);
          },
          onContrastChanged: (v) {
            _contrast = v;
            _applyContrast(v);
          },
          onSaturationChanged: (v) {
            _saturation = v;
            _applySaturation(v);
          },
          onSharpnessChanged: (v) {
            _sharpness = v;
            _applySharpness(v);
          },
        );
      case EditorTool.watermark:
        prefH = 310;
        panel = WatermarkPanel(
          settings: _watermarkSettings,
          onChanged: (s) { _watermarkSettings = s; },
          onApply: _applyWatermark,
        );
      case EditorTool.signature:
        prefH = 270;
        panel = SignaturePanel(
          onApply: _onSignaturePanelApply,
          onSignatureChanged: _onSignatureCreated,
        );
      case EditorTool.pageNumbers:
        prefH = 210;
        panel = PageNumbersPanel(
          position: _pnPosition,
          fontSize: _pnFontSize,
          color: _pnColor,
          startNumber: _pnStartNumber,
          onPositionChanged: (p) => setState(() => _pnPosition = p),
          onFontSizeChanged: (s) => setState(() => _pnFontSize = s),
          onColorChanged: (c) => setState(() => _pnColor = c),
          onStartNumberChanged: (n) => setState(() => _pnStartNumber = n),
          onApply: _applyPageNumbers,
        );
      case EditorTool.rotate:
      case EditorTool.flip:
        prefH = 0;
        panel = const SizedBox();
    }

    if (prefH == 0) return const SizedBox();

    final height = prefH.clamp(80.0, maxPanelH);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface2 : const Color(0xFF1A1A1E),
        border: Border(
          top: BorderSide(
            color: (isLight ? AppColors.lightBorder : const Color(0xFF2A2A2E)).withAlpha(80),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            panel,
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => setState(() => _activeTool = null),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded, size: 13, color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceSignatureBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2E), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Drag signature to position',
                style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: _cancelSignaturePlacement,
              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white60),
              label: const Text('Cancel', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _applySignature,
              icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              label: const Text('Place', style: TextStyle(color: Colors.white, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconEditorStudio,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagesPanel(bool isLight) {
    return PagesPanel(
      pageImages: _pageImages,
      pageOrder: _pageOrder,
      currentPage: _currentPage,
      onPageSelected: _selectPage,
      onPageDeleted: _deletePage,
      onPageDuplicated: _duplicatePage,
      onReorder: _reorderPages,
    );
  }

  Widget _buildToolbar(bool isLight, Color surface) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2E), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 44,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _toolBtn(Icons.crop_rounded, 'Crop', null, onTap: _cropCurrentPage),
                _toolBtn(Icons.rotate_left_rounded, 'RotL', null, onTap: _rotateLeft),
                _toolBtn(Icons.rotate_right_rounded, 'RotR', null, onTap: _rotateRight),
                _toolBtn(Icons.flip_rounded, 'FlipH', null, onTap: _flipH),
                _toolBtn(Icons.flip_to_back_rounded, 'FlipV', null, onTap: _flipV),
                if (_isPdf) _toolBtn(Icons.auto_stories_rounded, 'Pages', EditorTool.pages),
                _toolBtn(Icons.text_fields_rounded, 'WM', EditorTool.watermark),
                _toolBtn(Icons.draw_rounded, 'Sig', EditorTool.signature),
                _toolBtn(Icons.numbers_rounded, '#', EditorTool.pageNumbers),
                _toolBtn(Icons.filter_vintage_rounded, 'Filters', EditorTool.filters),
                _toolBtn(Icons.tune_rounded, 'Adj', EditorTool.adjustments),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, EditorTool? tool, {VoidCallback? onTap}) {
    final active = tool != null && _activeTool == tool;
    return GestureDetector(
      onTap: onTap ?? (tool != null ? () => _selectTool(tool) : null),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.iconEditorStudio.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: active
              ? Border.all(color: AppColors.iconEditorStudio.withAlpha(80))
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? AppColors.iconEditorStudio : Colors.white70),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: active ? AppColors.iconEditorStudio : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
