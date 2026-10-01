import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'metric_counter_tile.dart';

class AiWorkoutMetricInputs extends StatelessWidget {
  final double currentWeight;
  final double currentHeight;
  final int age;
  final int maxAllowedAiAge;
  final List<String> selectedInjuries;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<String> onToggleInjury;

  const AiWorkoutMetricInputs({
    super.key,
    required this.currentWeight,
    required this.currentHeight,
    required this.age,
    this.maxAllowedAiAge = 55,
    required this.selectedInjuries,
    required this.onWeightChanged,
    required this.onHeightChanged,
    required this.onAgeChanged,
    required this.onToggleInjury,
  });

  static const _availableInjuries = ['lower_back', 'knee', 'shoulder', 'wrist'];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final heightM = currentHeight / 100;
    final bmi = heightM > 0 ? (currentWeight / (heightM * heightM)) : 22.0;
    final isAgeBlocked = age >= maxAllowedAiAge;
    final isTrackB = !isAgeBlocked && (currentWeight >= 90 || bmi >= 28.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRoutingBadge(isAgeBlocked, isTrackB, bmi, accent),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: MetricCounterTile(title: 'CURRENT WEIGHT', value: '${currentWeight.toStringAsFixed(0)} kg', onDecrement: () => onWeightChanged((currentWeight - 1).clamp(40, 180)), onIncrement: () => onWeightChanged((currentWeight + 1).clamp(40, 180)))),
            const SizedBox(width: 8),
            Expanded(child: MetricCounterTile(title: 'HEIGHT', value: '${currentHeight.toStringAsFixed(0)} cm', onDecrement: () => onHeightChanged((currentHeight - 1).clamp(120, 220)), onIncrement: () => onHeightChanged((currentHeight + 1).clamp(120, 220)))),
            const SizedBox(width: 8),
            Expanded(child: MetricCounterTile(title: 'AGE', value: '$age yrs', onDecrement: () => onAgeChanged((age - 1).clamp(14, 90)), onIncrement: () => onAgeChanged((age + 1).clamp(14, 90)))),
          ],
        ),
        const SizedBox(height: 12),
        Text('MEDICAL INJURIES / CONTRAINDICATIONS', style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _availableInjuries.map((injury) {
            final isSelected = selectedInjuries.contains(injury);
            return FilterChip(
              label: Text(injury.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
              selected: isSelected,
              onSelected: (_) => onToggleInjury(injury),
              selectedColor: Colors.redAccent.withValues(alpha: 0.25),
              checkmarkColor: Colors.redAccent,
              labelStyle: TextStyle(color: isSelected ? Colors.redAccent : AppColors.textSecondary),
              backgroundColor: AppColors.background,
              side: BorderSide(color: isSelected ? Colors.redAccent : AppColors.border),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRoutingBadge(bool isAgeBlocked, bool isTrackB, double bmi, Color accent) {
    if (isAgeBlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5))),
        child: Row(
          children: [
            const Icon(Icons.health_and_safety_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LIABILITY RESTRICTION (AGE $maxAllowedAiAge+)', style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  Text('In-person trainer evaluation required for age $maxAllowedAiAge+. Automated AI workouts blocked for safety.', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final color = isTrackB ? Colors.amber : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: isTrackB ? 0.5 : 0.4))),
      child: Row(
        children: [
          Icon(isTrackB ? Icons.healing_rounded : Icons.bolt_rounded, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isTrackB ? 'TRACK B ROUTING (LOW-IMPACT RETENTION)' : 'TRACK A ROUTING (DYNAMIC OVERLOAD)', style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                Text(isTrackB ? 'Silent BMI: ${bmi.toStringAsFixed(1)} | High-impact jumps & spinal loads purged.' : 'Silent BMI: ${bmi.toStringAsFixed(1)} | Progressive compound overload enabled.', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
