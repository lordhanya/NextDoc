import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/typography.dart';
import '../services/signature_service.dart';

enum SignatureMode { draw, type, image }

final class SignaturePanel extends StatefulWidget {
  final VoidCallback onApply;
  final ValueChanged<Uint8List?> onSignatureChanged;

  const SignaturePanel({
    super.key,
    required this.onApply,
    required this.onSignatureChanged,
  });

  @override
  State<SignaturePanel> createState() => _SignaturePanelState();
}

final class _SignaturePanelState extends State<SignaturePanel>
    with SingleTickerProviderStateMixin {
  final _signatureService = SignatureService();
  final _strokes = <List<Offset>>[];
  final _undoStack = <List<Offset>>[];
  final _redoStack = <List<Offset>>[];
  List<Offset> _currentStroke = [];
  bool _hasSaved = false;
  final _drawKey = GlobalKey();

  // Type mode
  final _typeController = TextEditingController();

  // Image mode
  Uint8List? _importedBytes;

  // State
  SignatureMode _mode = SignatureMode.draw;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _mode = SignatureMode.values[_tabController.index]);
      }
    });
    _checkSaved();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _checkSaved() async {
    final has = await _signatureService.hasSavedSignature();
    if (mounted) setState(() => _hasSaved = has);
  }

  Future<void> _loadSaved() async {
    final bytes = await _signatureService.loadSavedSignature();
    if (bytes != null) {
      widget.onSignatureChanged(bytes);
      widget.onApply();
    }
  }

  // ---- Draw mode ----

  Uint8List? _renderDrawSignature() {
    if (_strokes.isEmpty) return null;

    final renderBox = _drawKey.currentContext?.findRenderObject() as RenderBox?;
    final canvasW = renderBox?.size.width ?? 300;
    final canvasH = renderBox?.size.height ?? 150;
    const targetW = 300;
    const targetH = 150;
    final scaleX = targetW / canvasW;
    final scaleY = targetH / canvasH;

    final sig = img.Image(width: targetW, height: targetH);
    final black = img.ColorRgba8(0, 0, 0, 255);
    for (int y = 0; y < targetH; y++) {
      for (int x = 0; x < targetW; x++) {
        sig.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
    for (final stroke in _strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        final p1 = Offset(stroke[i].dx * scaleX, stroke[i].dy * scaleY);
        final p2 = Offset(stroke[i + 1].dx * scaleX, stroke[i + 1].dy * scaleY);
        img.drawLine(sig,
            x1: p1.dx.toInt(), y1: p1.dy.toInt(),
            x2: p2.dx.toInt(), y2: p2.dy.toInt(),
            color: black, thickness: 2.5);
      }
    }
    return img.encodePng(sig);
  }

  // ---- Type mode ----

  Uint8List? _renderTypeSignature() {
    final text = _typeController.text.trim();
    if (text.isEmpty) return null;
    const w = 300, h = 150;
    final sig = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        sig.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
    final font = img.arial48;
    final black = img.ColorRgba8(0, 0, 0, 255);
    final textW = text.length * 24;
    final cx = (w - textW) ~/ 2;
    final cy = (h - 48) ~/ 2;
    if (cx >= 0) {
      img.drawString(sig, text, font: font, x: cx, y: cy, color: black);
    }
    return img.encodePng(sig);
  }

  // ---- Image mode ----

  Future<void> _pickImageSignature() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes != null) {
      setState(() => _importedBytes = bytes);
    }
  }

  // ---- Apply ----

  void _saveAndApply() {
    Uint8List? bytes;
    switch (_mode) {
      case SignatureMode.draw:
        bytes = _renderDrawSignature();
      case SignatureMode.type:
        bytes = _renderTypeSignature();
      case SignatureMode.image:
        bytes = _importedBytes;
    }
    if (bytes == null) return;
    _signatureService.saveSignature(bytes);
    widget.onSignatureChanged(bytes);
    widget.onApply();
  }

  void _undoStroke() {
    if (_undoStack.isEmpty) return;
    final stroke = _undoStack.removeLast();
    _redoStack.add(stroke);
    _strokes.removeLast();
    setState(() {});
  }

  void _redoStroke() {
    if (_redoStack.isEmpty) return;
    final stroke = _redoStack.removeLast();
    _undoStack.add(stroke);
    _strokes.add(stroke);
    setState(() {});
  }

  bool get _canApply {
    switch (_mode) {
      case SignatureMode.draw:
        return _strokes.isNotEmpty;
      case SignatureMode.type:
        return _typeController.text.trim().isNotEmpty;
      case SignatureMode.image:
        return _importedBytes != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mutedColor = isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Signature', style: AppTextStyles.titleSmall),
              const Spacer(),
              if (_hasSaved)
                TextButton.icon(
                  onPressed: _loadSaved,
                  icon: const Icon(Icons.history_rounded, size: 14),
                  label: const Text('Saved', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.iconEditorStudio,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 28,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.iconEditorStudio,
              labelColor: AppColors.iconEditorStudio,
              unselectedLabelColor: mutedColor,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Draw'),
                Tab(text: 'Type'),
                Tab(text: 'Image'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 120,
            child: IndexedStack(
              index: _mode.index,
              children: [
                _buildDrawCanvas(),
                _buildTypeMode(mutedColor),
                _buildImageMode(mutedColor),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_mode == SignatureMode.draw) ...[
                IconButton(
                  onPressed: _undoStack.isEmpty ? null : _undoStroke,
                  icon: Icon(Icons.undo_rounded, size: 16,
                      color: _undoStack.isNotEmpty ? AppColors.iconEditorStudio : mutedColor.withAlpha(60)),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Undo stroke',
                ),
                IconButton(
                  onPressed: _redoStack.isEmpty ? null : _redoStroke,
                  icon: Icon(Icons.redo_rounded, size: 16,
                      color: _redoStack.isNotEmpty ? AppColors.iconEditorStudio : mutedColor.withAlpha(60)),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Redo stroke',
                ),
              ],
              TextButton(
                onPressed: () {
                  _strokes.clear();
                  _undoStack.clear();
                  _redoStack.clear();
                  _currentStroke.clear();
                  _typeController.clear();
                  setState(() => _importedBytes = null);
                },
                child: Text('Clear', style: TextStyle(color: mutedColor, fontSize: 12)),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: _canApply ? _saveAndApply : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.iconEditorStudio,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                ),
                child: const Text('Apply', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.grey.withAlpha(80)),
      ),
      child: GestureDetector(
        key: _drawKey,
        onPanStart: (details) {
          setState(() {
            _currentStroke = [details.localPosition];
            _strokes.add(_currentStroke);
          });
        },
        onPanUpdate: (details) {
          setState(() => _currentStroke.add(details.localPosition));
        },
        onPanEnd: (_) {
          if (_currentStroke.length > 1) {
            _undoStack.add(List.from(_currentStroke));
            _redoStack.clear();
          }
          _currentStroke = [];
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md - 1),
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _SignaturePainter(_strokes),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeMode(Color mutedColor) {
    return TextField(
      controller: _typeController,
      maxLines: 3,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontStyle: FontStyle.italic,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: 'Type your signature...',
        hintStyle: TextStyle(color: mutedColor.withAlpha(100), fontSize: 24),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: Colors.grey.withAlpha(80)),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildImageMode(Color mutedColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.grey.withAlpha(80)),
      ),
      child: SizedBox.expand(
        child: _importedBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md - 1),
                    child: Image.memory(_importedBytes!, fit: BoxFit.contain),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _importedBytes = null),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(120),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: _pickImageSignature,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_rounded, size: 32, color: mutedColor.withAlpha(120)),
                    const SizedBox(height: 4),
                    Text('Tap to select image', style: TextStyle(color: mutedColor, fontSize: 12)),
                  ],
                ),
              ),
      ),
    );
  }
}

final class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
