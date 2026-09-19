import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/services/bmi_calorie_engine.dart';
import 'weight_stepper_widget.dart';

class FitnessMetricsRow extends StatelessWidget {
  final Gender gender;
  final double age;
  final double height;
  final double currentWeight;
  final double targetWeight;
  final ValueChanged<Gender> onGenderChanged;
  final ValueChanged<double> onAgeChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onCurrentWeightChanged;
  final ValueChanged<double> onTargetWeightChanged;

  const FitnessMetricsRow({
    super.key,
    required this.gender,
    required this.age,
    required this.height,
    required this.currentWeight,
    required this.targetWeight,
    required this.onGenderChanged,
    required this.onAgeChanged,
    required this.onHeightChanged,
    required this.onCurrentWeightChanged,
    required this.onTargetWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('BIOLOGICAL GENDER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const Spacer(),
            _genderPill('MALE', Gender.male, accent),
            const SizedBox(width: 8),
            _genderPill('FEMALE', Gender.female, accent),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: WeightStepperWidget(label: 'AGE', value: age, unit: 'YRS', min: 14, max: 90, onChanged: onAgeChanged)),
            const SizedBox(width: 8),
            Expanded(child: WeightStepperWidget(label: 'HEIGHT', value: height, unit: 'CM', min: 120, max: 240, onChanged: onHeightChanged)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: WeightStepperWidget(label: 'CURRENT WT', value: currentWeight, unit: 'KG', min: 30, max: 200, onChanged: onCurrentWeightChanged)),
            const SizedBox(width: 8),
            Expanded(child: WeightStepperWidget(label: 'TARGET WT', value: targetWeight, unit: 'KG', min: 30, max: 200, onChanged: onTargetWeightChanged)),
          ],
        ),
      ],
    );
  }

  Widget _genderPill(String title, Gender val, Color accent) {
    final isSel = gender == val;
    return GestureDetector(
      onTap: () => onGenderChanged(val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? accent.withValues(alpha: 0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSel ? accent : AppColors.border),
        ),
        child: Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? accent : AppColors.textSecondary)),
      ),
    );
  }
}
