import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/calculator_models.dart';
import '../../domain/bmi_models.dart';

/// Interactive Google-style sliders & unit toggles for BMI calculation.
class BmiSliderControls extends StatelessWidget {
  final UnitSystem unitSystem;
  final double weightKg;
  final double heightCm;
  final double weightLbs;
  final double heightInches;
  final ValueChanged<UnitSystem> onUnitSystemChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;

  const BmiSliderControls({
    super.key,
    required this.unitSystem,
    required this.weightKg,
    required this.heightCm,
    required this.weightLbs,
    required this.heightInches,
    required this.onUnitSystemChanged,
    required this.onHeightChanged,
    required this.onWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;
    final isMetric = unitSystem == UnitSystem.metric;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Measurement system',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        _buildUnitToggle(),
        const SizedBox(height: 18),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildHeightInput(isMetric)),
              const SizedBox(width: 24),
              Expanded(child: _buildWeightInput(isMetric)),
            ],
          )
        else ...[
          _buildHeightInput(isMetric),
          const SizedBox(height: 12),
          _buildWeightInput(isMetric),
        ],
      ],
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _unitButton('Metric', UnitSystem.metric),
          _unitButton('Imperial', UnitSystem.imperial),
        ],
      ),
    );
  }

  Widget _unitButton(String label, UnitSystem target) {
    final isSelected = unitSystem == target;
    return GestureDetector(
      onTap: () => onUnitSystemChanged(target),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeightInput(bool isMetric) {
    final value = isMetric ? heightCm : heightInches;
    final min = isMetric ? 100.0 : 48.0;
    final max = isMetric ? 230.0 : 88.0;
    final display = isMetric
        ? '${heightCm.round()} cm'
        : BmiCalculatorEngine.formatFeetInches(heightInches);

    return _sliderRow(
      label: isMetric ? 'Height (cm)' : 'Height (ft/in)',
      displayValue: display,
      value: value.clamp(min, max),
      min: min,
      max: max,
      onChanged: onHeightChanged,
    );
  }

  Widget _buildWeightInput(bool isMetric) {
    final value = isMetric ? weightKg : weightLbs;
    final min = isMetric ? 30.0 : 66.0;
    final max = isMetric ? 200.0 : 440.0;
    final display = isMetric ? '${weightKg.round()} kg' : '${weightLbs.round()}';

    return _sliderRow(
      label: isMetric ? 'Weight (kg)' : 'Weight (lb)',
      displayValue: display,
      value: value.clamp(min, max),
      min: min,
      max: max,
      onChanged: onWeightChanged,
    );
  }

  Widget _sliderRow({
    required String label,
    required String displayValue,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary)),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.5,
                  activeTrackColor: const Color(0xFF3B82F6),
                  inactiveTrackColor: const Color(0xFF3F3F46),
                  thumbColor: const Color(0xFF3B82F6),
                  overlayColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(value: value, min: min, max: max, onChanged: onChanged),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: Text(
                displayValue,
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
