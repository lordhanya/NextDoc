import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/typography.dart';

final class PageNumbersPanel extends StatefulWidget {
  final String position;
  final double fontSize;
  final Color color;
  final int startNumber;
  final ValueChanged<String> onPositionChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<int> onStartNumberChanged;
  final VoidCallback onApply;

  const PageNumbersPanel({
    super.key,
    this.position = 'bottomRight',
    this.fontSize = 24,
    this.color = const Color(0xFF646464),
    this.startNumber = 1,
    required this.onPositionChanged,
    required this.onFontSizeChanged,
    required this.onColorChanged,
    required this.onStartNumberChanged,
    required this.onApply,
  });

  @override
  State<PageNumbersPanel> createState() => _PageNumbersPanelState();
}

final class _PageNumbersPanelState extends State<PageNumbersPanel> {
  late int _startNumber;

  @override
  void initState() {
    super.initState();
    _startNumber = widget.startNumber;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mutedColor = isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Page Numbers', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _label('Position', mutedColor),
              const SizedBox(width: AppSpacing.sm),
              _posBtn('TL', 'topLeft'),
              const SizedBox(width: 4),
              _posBtn('TR', 'topRight'),
              const SizedBox(width: 4),
              _posBtn('BL', 'bottomLeft'),
              const SizedBox(width: 4),
              _posBtn('BR', 'bottomRight'),
              const SizedBox(width: 4),
              _posBtn('C', 'center'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _label('Start #', mutedColor),
              SizedBox(
                width: 60,
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: '$_startNumber'),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
                    fontSize: 13,
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null) {
                      _startNumber = n;
                      widget.onStartNumberChanged(n);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              _label('Font', mutedColor),
              _sizeChip('18', isLight),
              const SizedBox(width: 4),
              _sizeChip('24', isLight),
              const SizedBox(width: 4),
              _sizeChip('32', isLight),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _label('Color', mutedColor),
              _colorDot(const Color(0xFF646464)),
              const SizedBox(width: 4),
              _colorDot(Colors.black),
              const SizedBox(width: 4),
              _colorDot(Colors.white),
              const SizedBox(width: 4),
              _colorDot(AppColors.iconEditorStudio),
              const SizedBox(width: 4),
              _colorDot(Colors.red.withAlpha(180)),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.iconEditorStudio,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text, Color color) {
    return SizedBox(
      width: 48,
      child: Text(text, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }

  Widget _posBtn(String label, String pos) {
    final selected = widget.position == pos;
    return GestureDetector(
      onTap: () => widget.onPositionChanged(pos),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.iconEditorStudio : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(
            color: selected
                ? AppColors.iconEditorStudio
                : (Theme.of(context).brightness == Brightness.light ? Colors.black26 : Colors.white24),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: selected
                ? Colors.white
                : (Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white70),
          ),
        ),
      ),
    );
  }

  Widget _sizeChip(String label, bool isLight) {
    final selected = widget.fontSize.toInt().toString() == label;
    return GestureDetector(
      onTap: () => widget.onFontSizeChanged(double.parse(label)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _colorDot(Color color) {
    final selected = widget.color.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => widget.onColorChanged(color),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.iconEditorStudio : Colors.grey.withAlpha(80),
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}
