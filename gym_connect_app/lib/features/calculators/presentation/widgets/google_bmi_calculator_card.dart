import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/calculator_models.dart';
import '../../domain/bmi_models.dart';
import 'bmi_header_badge.dart';
import 'bmi_gauge_widget.dart';
import 'bmi_legend_widget.dart';
import 'bmi_slider_controls.dart';

/// Complete Google Search styled BMI Calculator Card.
class GoogleBmiCalculatorCard extends StatefulWidget {
  final double initialWeightKg;
  final double initialHeightCm;
  final UnitSystem initialUnitSystem;

  const GoogleBmiCalculatorCard({
    super.key,
    this.initialWeightKg = 81.6, // ~180 lbs default like Google screenshot
    this.initialHeightCm = 167.6, // ~5'6" default like Google screenshot
    this.initialUnitSystem = UnitSystem.imperial,
  });

  @override
  State<GoogleBmiCalculatorCard> createState() => _GoogleBmiCalculatorCardState();
}

class _GoogleBmiCalculatorCardState extends State<GoogleBmiCalculatorCard> {
  late UnitSystem _unitSystem;
  late double _weightKg;
  late double _heightCm;
  late double _weightLbs;
  late double _heightInches;
  late double _currentBmi;

  @override
  void initState() {
    super.initState();
    _unitSystem = widget.initialUnitSystem;
    _weightKg = widget.initialWeightKg;
    _heightCm = widget.initialHeightCm;
    _weightLbs = BmiCalculatorEngine.kgToLbs(_weightKg);
    _heightInches = BmiCalculatorEngine.cmToInches(_heightCm);
    _recalculate();
  }

  void _recalculate() {
    if (_unitSystem == UnitSystem.metric) {
      _currentBmi = BmiCalculatorEngine.calculateMetric(
        weightKg: _weightKg,
        heightCm: _heightCm,
      );
    } else {
      _currentBmi = BmiCalculatorEngine.calculateImperial(
        weightLbs: _weightLbs,
        heightInches: _heightInches,
      );
    }
  }

  void _handleUnitChange(UnitSystem target) {
    setState(() {
      _unitSystem = target;
      if (target == UnitSystem.imperial) {
        _weightLbs = BmiCalculatorEngine.kgToLbs(_weightKg);
        _heightInches = BmiCalculatorEngine.cmToInches(_heightCm);
      } else {
        _weightKg = BmiCalculatorEngine.lbsToKg(_weightLbs);
        _heightCm = BmiCalculatorEngine.inchesToCm(_heightInches);
      }
      _recalculate();
    });
  }

  void _handleHeightChange(double val) {
    setState(() {
      if (_unitSystem == UnitSystem.metric) {
        _heightCm = val;
        _heightInches = BmiCalculatorEngine.cmToInches(val);
      } else {
        _heightInches = val;
        _heightCm = BmiCalculatorEngine.inchesToCm(val);
      }
      _recalculate();
    });
  }

  void _handleWeightChange(double val) {
    setState(() {
      if (_unitSystem == UnitSystem.metric) {
        _weightKg = val;
        _weightLbs = BmiCalculatorEngine.kgToLbs(val);
      } else {
        _weightLbs = val;
        _weightKg = BmiCalculatorEngine.lbsToKg(val);
      }
      _recalculate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BmiHeaderBadge(bmi: _currentBmi),
          const SizedBox(height: 12),
          const BmiLegendWidget(),
          const SizedBox(height: 16),
          BmiGaugeWidget(bmi: _currentBmi),
          const SizedBox(height: 20),
          BmiSliderControls(
            unitSystem: _unitSystem,
            weightKg: _weightKg,
            heightCm: _heightCm,
            weightLbs: _weightLbs,
            heightInches: _heightInches,
            onUnitSystemChanged: _handleUnitChange,
            onHeightChanged: _handleHeightChange,
            onWeightChanged: _handleWeightChange,
          ),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Google-standard clinical categories. Standard healthy BMI range: 18.5 – 24.9.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
