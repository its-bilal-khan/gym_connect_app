import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/workout_notifier.dart';
import 'body_type_selector_list.dart';
import 'calorie_calculator_sheet.dart';
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
  bool _isSaving = false;

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
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client.from('user_fitness_profiles').upsert({
          'user_id': userId,
          'body_type': _selectedBodyType,
          'fitness_goal': _selectedGoal,
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
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Text('GENETICS & TARGET PHYSIQUE', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('Choose your natural genetics foundation to tune AI workout routines.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => CalorieCalculatorSheet.show(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(Icons.calculate_rounded, color: accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CALCULATE DAILY CALORIES & MACROS', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('Tune BMR, TDEE, protein & hydration targets', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: BodyTypeSelectorList(
                selectedBodyType: _selectedBodyType,
                onSelect: (b) => setState(() => _selectedBodyType = b),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              text: _isSaving ? 'CALIBRATING...' : 'SAVE & TUNE AI TRAINER',
              icon: Icons.auto_awesome_rounded,
              onPressed: _isSaving ? null : _onSaveTapped,
            ),
          ],
        ),
      ),
    );
  }
}
