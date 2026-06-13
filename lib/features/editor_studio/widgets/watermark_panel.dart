import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/typography.dart';

final class WatermarkSettings {
  final String text;
  final double opacity;
  final int rotation;
  final String position;
  final double fontSize;
  final int colorR;
  final int colorG;
  final int colorB;

  const WatermarkSettings({
    this.text = '',
    this.opacity = 0.3,
    this.rotation = 0,
    this.position = 'center',
    this.fontSize = 48,
    this.colorR = 180,
    this.colorG = 180,
    this.colorB = 180,
  });
}

final class WatermarkPanel extends StatefulWidget {
  final WatermarkSettings settings;
  final ValueChanged<WatermarkSettings> onChanged;
  final VoidCallback onApply;

  const WatermarkPanel({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onApply,
  });

  @override
  State<WatermarkPanel> createState() => _WatermarkPanelState();
}

final class _WatermarkPanelState extends State<WatermarkPanel> {
  late TextEditingController _textController;
  late TextEditingController _fontSizeController;
  late double _opacity;
  late int _rotation;
  late String _position;
  late double _fontSize;
  late int _colorR;
  late int _colorG;
  late int _colorB;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.settings.text);
    _fontSizeController = TextEditingController(text: widget.settings.fontSize.toInt().toString());
    _opacity = widget.settings.opacity;
    _rotation = widget.settings.rotation;
    _position = widget.settings.position;
    _fontSize = widget.settings.fontSize;
    _colorR = widget.settings.colorR;
    _colorG = widget.settings.colorG;
    _colorB = widget.settings.colorB;
  }

  @override
  void didUpdateWidget(WatermarkPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings.text != oldWidget.settings.text) {
      _textController.text = widget.settings.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _fontSizeController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(WatermarkSettings(
      text: _textController.text,
      opacity: _opacity,
      rotation: _rotation,
      position: _position,
      fontSize: _fontSize,
      colorR: _colorR,
      colorG: _colorG,
      colorB: _colorB,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
    final mutedColor = isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted;
    final bgColor = isLight ? AppColors.lightSurface1 : AppColors.darkSurface1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Watermark', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Enter watermark text',
                hintStyle: TextStyle(color: mutedColor.withAlpha(120)),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: mutedColor.withAlpha(60)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: TextStyle(color: textColor),
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _label('Opacity', mutedColor),
                ),
                Expanded(
                  flex: 2,
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.iconEditorStudio,
                      thumbColor: AppColors.iconEditorStudio,
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      min: 0.05,
                      max: 1,
                      value: _opacity,
                      onChanged: (v) => setState(() { _opacity = v; _emit(); }),
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    (_opacity * 100).toInt().toString(),
                    style: AppTextStyles.caption.copyWith(color: mutedColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _label('Font Size', mutedColor),
                const SizedBox(width: AppSpacing.md),
                _fontSizeBtn(Icons.remove_rounded, () {
                  if (_fontSize > 8) {
                    setState(() { _fontSize -= 2; _emit(); });
                    _fontSizeController.text = _fontSize.toInt().toString();
                  }
                }),
                const SizedBox(width: 6),
                SizedBox(
                  width: 52,
                  child: TextField(
                    controller: _fontSizeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: textColor),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        borderSide: BorderSide(color: mutedColor.withAlpha(60)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        borderSide: BorderSide(color: mutedColor.withAlpha(60)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        borderSide: const BorderSide(color: AppColors.iconEditorStudio),
                      ),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null && parsed >= 8 && parsed <= 200) {
                        setState(() { _fontSize = parsed; _emit(); });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                _fontSizeBtn(Icons.add_rounded, () {
                  setState(() { _fontSize += 2; _emit(); });
                  _fontSizeController.text = _fontSize.toInt().toString();
                }),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _label('Position', mutedColor),
                const SizedBox(width: AppSpacing.sm),
                _posChip('TL', 'topLeft', isLight),
                const SizedBox(width: 4),
                _posChip('TC', 'topCenter', isLight),
                const SizedBox(width: 4),
                _posChip('TR', 'topRight', isLight),
                const SizedBox(width: 4),
                _posChip('C', 'center', isLight),
                const SizedBox(width: 4),
                _posChip('BL', 'bottomLeft', isLight),
                const SizedBox(width: 4),
                _posChip('BC', 'bottomCenter', isLight),
                const SizedBox(width: 4),
                _posChip('BR', 'bottomRight', isLight),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _label('Color', mutedColor),
                const SizedBox(width: AppSpacing.sm),
                ..._buildColorChips(isLight),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _textController.text.isNotEmpty ? widget.onApply : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.iconEditorStudio,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Apply Watermark'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color color) {
    return SizedBox(
      width: 60,
      child: Text(text, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }

  Widget _fontSizeBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.iconEditorStudio.withAlpha(30),
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(color: AppColors.iconEditorStudio.withAlpha(80)),
        ),
        child: Icon(icon, size: 16, color: AppColors.iconEditorStudio),
      ),
    );
  }

  static const List<Color> _presetColors = [
    Color(0xFFB4B4B4), // grey
    Color(0xFF000000), // black
    Color(0xFFFFFFFF), // white
    Color(0xFFEF4444), // red
    Color(0xFF3B82F6), // blue
    Color(0xFF22C55E), // green
    Color(0xFFA855F7), // purple
    Color(0xFFF97316), // orange
  ];

  List<Widget> _buildColorChips(bool isLight) {
    return _presetColors.map((c) {
      final sr = (c.r * 255).round();
      final sg = (c.g * 255).round();
      final sb = (c.b * 255).round();
      final selected = _colorR == sr && _colorG == sg && _colorB == sb;
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: GestureDetector(
          onTap: () => setState(() { _colorR = sr; _colorG = sg; _colorB = sb; _emit(); }),
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.iconEditorStudio : (isLight ? Colors.black26 : Colors.white38),
                width: selected ? 2.5 : 1,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: 14,
                    color: c.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
                : null,
          ),
        ),
      );
    }).toList();
  }

  Widget _posChip(String label, String pos, bool isLight) {
    final selected = _position == pos;
    return GestureDetector(
      onTap: () => setState(() { _position = pos; _emit(); }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.iconEditorStudio : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(
            color: selected ? AppColors.iconEditorStudio : (isLight ? Colors.black26 : Colors.white24),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: selected ? Colors.white : (isLight ? Colors.black87 : Colors.white70),
          ),
        ),
      ),
    );
  }
}
