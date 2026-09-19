import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/services/bmi_calorie_engine.dart';
import '../providers/workout_notifier.dart';
import 'body_type_selector_list.dart';
import 'calorie_calculator_sheet.dart';
import 'fitness_metrics_row.dart';
import 'protocol_switch_dialog.dart';

class GoalOnboardingDialog extends ConsumerStatefulWidget {
  const GoalOnboardingDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const GoalOnboardingDialog(),
    );
  }

  @override
  ConsumerState<GoalOnboardingDialog> createState() => _GoalOnboardingDialogState();
}

class _GoalOnboardingDialogState extends ConsumerState<GoalOnboardingDialog> {
  String _selectedBodyType = 'mesomorph';
  final String _initialBodyType = 'mesomorph';
  final String _selectedGoal = 'muscle_gain';
  Gender _gender = Gender.male;
  double _ageYears = 24.0, _heightCm = 175.0, _currentWeightKg = 74.0, _targetWeightKg = 80.0;
  bool _isSaving = false;

  NutritionCalculationResult get _nutri => BmiCalorieEngine.calculate(
    weightKg: _currentWeightKg, heightCm: _heightCm, ageYears: _ageYears.toInt(), gender: _gender, goal: _selectedGoal,
  );

  void _onSaveTapped() {
    if (_selectedBodyType != _initialBodyType) {
      ProtocolSwitchDialog.show(context, selectedBodyType: _selectedBodyType, onConfirm: _persistGoal);
    } else {
      _persistGoal();
    }
  }

  Future<void> _persistGoal() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    final nutri = _nutri;
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client.from('user_fitness_profiles').upsert({
          'user_id': userId,
          'body_type': _selectedBodyType,
          'fitness_goal': _selectedGoal,
          'height_cm': _heightCm,
          'current_weight_kg': _currentWeightKg,
          'target_weight_kg': _targetWeightKg,
          'ai_recommendations': {
            'age': _ageYears.toInt(), 'gender': _gender.name,
            'bmi': nutri.bmi, 'bmi_category': nutri.bmiCategory,
            'target_calories': nutri.targetCalories,
            'target_protein_g': nutri.proteinGrams,
            'target_water_liters': nutri.waterLiters,
          },
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('GoalOnboardingDialog: save error: $e');
    }

    ref.read(workoutNotifierProvider.notifier).loadTodayRoutine(day: 1);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('AI Protocol active: ${_selectedBodyType.toUpperCase()} split loaded!'),
        backgroundColor: AppColors.surface,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutri = _nutri;
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 10),
            Text('GENETICS & TARGET PHYSIQUE', style: GoogleFonts.oswald(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('Select natural build and calibrate nutrition fuel targets.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            FitnessMetricsRow(
              gender: _gender, age: _ageYears, height: _heightCm, currentWeight: _currentWeightKg, targetWeight: _targetWeightKg,
              onGenderChanged: (v) => setState(() => _gender = v),
              onAgeChanged: (v) => setState(() => _ageYears = v),
              onHeightChanged: (v) => setState(() => _heightCm = v),
              onCurrentWeightChanged: (v) => setState(() => _currentWeightKg = v),
              onTargetWeightChanged: (v) => setState(() => _targetWeightKg = v),
            ),
            const SizedBox(height: 8),
            _macroPill(nutri, accent),
            const SizedBox(height: 8),
            Expanded(child: BodyTypeSelectorList(selectedBodyType: _selectedBodyType, onSelect: (b) => setState(() => _selectedBodyType = b))),
            const SizedBox(height: 10),
            PrimaryButton(text: _isSaving ? 'CALIBRATING...' : 'SAVE & TUNE AI TRAINER', icon: Icons.auto_awesome_rounded, onPressed: _isSaving ? null : _onSaveTapped),
          ],
        ),
      ),
    );
  }

  Widget _macroPill(NutritionCalculationResult n, Color accent) {
    return GestureDetector(
      onTap: () => CalorieCalculatorSheet.show(context, weight: _currentWeightKg, height: _heightCm, age: _ageYears.toInt(), gender: _gender, goal: _selectedGoal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Icon(Icons.bolt_rounded, size: 14, color: accent),
            const SizedBox(width: 6),
            Expanded(child: Text('BMI ${n.bmi} • ${n.targetCalories} kcal • ${n.proteinGrams}g Protein', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
            Text('CALCULATOR', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: accent)),
            Icon(Icons.chevron_right_rounded, size: 14, color: accent),
          ],
        ),
      ),
    );
  }
}
