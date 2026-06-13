import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/typography.dart';

final class AdjustmentsPanel extends StatefulWidget {
  final double brightness;
  final double contrast;
  final double saturation;
  final double sharpness;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onSaturationChanged;
  final ValueChanged<double> onSharpnessChanged;

  const AdjustmentsPanel({
    super.key,
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.sharpness = 0,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onSaturationChanged,
    required this.onSharpnessChanged,
  });

  @override
  State<AdjustmentsPanel> createState() => _AdjustmentsPanelState();
}

final class _AdjustmentsPanelState extends State<AdjustmentsPanel> {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Adjustments', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _slider(
            'Brightness',
            widget.brightness,
            widget.onBrightnessChanged,
            Icons.brightness_6_rounded,
            isLight,
          ),
          _slider(
            'Contrast',
            widget.contrast,
            widget.onContrastChanged,
            Icons.contrast_rounded,
            isLight,
          ),
          _slider(
            'Saturation',
            widget.saturation,
            widget.onSaturationChanged,
            Icons.palette_rounded,
            isLight,
          ),
          _slider(
            'Sharpness',
            widget.sharpness,
            widget.onSharpnessChanged,
            Icons.blur_on_rounded,
            isLight,
          ),
        ],
        ),
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    ValueChanged<double> onChanged,
    IconData icon,
    bool isLight,
  ) {
    final textColor = isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.iconEditorStudio),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 72,
            child: Text(label, style: AppTextStyles.caption.copyWith(color: textColor)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.iconEditorStudio,
                inactiveTrackColor: (isLight ? Colors.black : Colors.white).withAlpha(20),
                thumbColor: AppColors.iconEditorStudio,
                overlayColor: AppColors.iconEditorStudio.withAlpha(25),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                min: -1,
                max: 1,
                value: value.clamp(-1.0, 1.0),
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              value.toStringAsFixed(1),
              style: AppTextStyles.caption.copyWith(color: textColor),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
