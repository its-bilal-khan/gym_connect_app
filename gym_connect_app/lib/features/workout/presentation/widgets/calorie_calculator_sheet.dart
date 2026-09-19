import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/services/bmi_calorie_engine.dart';
import 'calorie_tier_table.dart';
import 'fitness_metrics_row.dart';

class CalorieCalculatorSheet extends StatefulWidget {
  final double initialWeight, initialHeight;
  final int initialAge;
  final Gender initialGender;
  final String goal;
  final ValueChanged<NutritionCalculationResult>? onApply;

  const CalorieCalculatorSheet({
    super.key,
    this.initialWeight = 74,
    this.initialHeight = 175,
    this.initialAge = 24,
    this.initialGender = Gender.male,
    this.goal = 'muscle_gain',
    this.onApply,
  });

  static Future<void> show(BuildContext context, {double weight = 74, double height = 175, int age = 24, Gender gender = Gender.male, String goal = 'muscle_gain', ValueChanged<NutritionCalculationResult>? onApply}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => CalorieCalculatorSheet(initialWeight: weight, initialHeight: height, initialAge: age, initialGender: gender, goal: goal, onApply: onApply),
    );
  }

  @override
  State<CalorieCalculatorSheet> createState() => _CalorieCalculatorSheetState();
}

class _CalorieCalculatorSheetState extends State<CalorieCalculatorSheet> {
  late Gender _gender = widget.initialGender;
  late double _weight = widget.initialWeight, _height = widget.initialHeight, _age = widget.initialAge.toDouble();
  ActivityLevel _activity = ActivityLevel.moderate;
  int? _selectedTierCalories;

  NutritionCalculationResult get _res => BmiCalorieEngine.calculate(
    weightKg: _weight, heightCm: _height, ageYears: _age.toInt(), gender: _gender, activityLevel: _activity, goal: widget.goal,
  );

  @override
  Widget build(BuildContext context) {
    final res = _res;
    final accent = Theme.of(context).colorScheme.primary;
    final activeCalories = _selectedTierCalories ?? res.targetCalories;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CLINICAL CALORIE CALCULATOR', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  FitnessMetricsRow(
                    gender: _gender, age: _age, height: _height, currentWeight: _weight, targetWeight: _weight,
                    onGenderChanged: (v) => setState(() { _gender = v; _selectedTierCalories = null; }),
                    onAgeChanged: (v) => setState(() { _age = v; _selectedTierCalories = null; }),
                    onHeightChanged: (v) => setState(() { _height = v; _selectedTierCalories = null; }),
                    onCurrentWeightChanged: (v) => setState(() { _weight = v; _selectedTierCalories = null; }),
                    onTargetWeightChanged: (_) {},
                  ),
                  const SizedBox(height: 10),
                  Text('WEEKLY ACTIVITY LEVEL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: ActivityLevel.values.map((lvl) => ChoiceChip(
                      label: Text(lvl.label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _activity == lvl ? accent : AppColors.textSecondary)),
                      selected: _activity == lvl,
                      backgroundColor: AppColors.background,
                      selectedColor: accent.withValues(alpha: 0.15),
                      onSelected: (_) => setState(() { _activity = lvl; _selectedTierCalories = null; }),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  CalorieTierTable(
                    lossTiers: res.lossTiers,
                    gainTiers: res.gainTiers,
                    selectedCalories: activeCalories,
                    onSelectTier: (t) => setState(() => _selectedTierCalories = t.calories),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metric('BMI', '${res.bmi}', res.bmiCategory, accent),
                        _metric('PROTEIN', '${res.proteinGrams}g', 'Daily Target', Colors.cyanAccent),
                        _metric('HYDRATION', '${res.waterLiters}L', 'Water intake', Colors.lightBlueAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(text: 'SET $activeCalories KCAL DAILY TARGET', icon: Icons.check_circle_rounded, onPressed: () {
              final finalRes = NutritionCalculationResult(
                bmi: res.bmi, bmiCategory: res.bmiCategory, maintenanceCalories: res.maintenanceCalories,
                targetCalories: activeCalories, proteinGrams: res.proteinGrams, waterLiters: res.waterLiters,
                lossTiers: res.lossTiers, gainTiers: res.gainTiers,
              );
              widget.onApply?.call(finalRes);
              Navigator.of(context).pop();
            }),
          ],
        ),
      ),
    );
  }

  Widget _metric(String title, String val, String subtitle, Color color) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary), maxLines: 1),
      ],
    );
  }
}
