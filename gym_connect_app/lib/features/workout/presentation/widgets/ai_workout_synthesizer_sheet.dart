import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../super_admin/data/system_feature_toggle_repository.dart';
import '../../../super_admin/domain/models/system_feature_flags.dart';
import '../providers/ai_workout_provider.dart';
import '../providers/fitness_profile_provider.dart';
import 'ai_workout_metric_inputs.dart';
import 'ai_workout_sheet_header.dart';
import 'trainer_consultation_safety_dialog.dart';

class AiWorkoutSynthesizerSheet extends ConsumerStatefulWidget {
  const AiWorkoutSynthesizerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const AiWorkoutSynthesizerSheet(),
    );
  }

  @override
  ConsumerState<AiWorkoutSynthesizerSheet> createState() => _AiWorkoutSynthesizerSheetState();
}

class _AiWorkoutSynthesizerSheetState extends ConsumerState<AiWorkoutSynthesizerSheet> {
  double _weight = 75.0;
  double _height = 175.0;
  int _age = 26;
  final List<String> _injuries = [];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(fitnessProfileProvider).asData?.value;
    if (profile != null) {
      if (profile.currentWeightKg != null) _weight = profile.currentWeightKg!;
      if (profile.heightCm != null) _height = profile.heightCm!;
      if (profile.age != null) _age = profile.age!;
      _injuries.addAll(profile.medicalInjuries);
    }
  }

  void _toggleInjury(String injury) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_injuries.contains(injury)) {
        _injuries.remove(injury);
      } else {
        _injuries.add(injury);
      }
    });
  }

  Future<void> _assignRoutine(int maxAge) async {
    HapticFeedback.mediumImpact();
    if (_age >= maxAge) {
      TrainerConsultationSafetyDialog.show(context, maxAllowedAiAge: maxAge);
      return;
    }

    final profile = ref.read(fitnessProfileProvider).asData?.value;
    final res = await ref.read(aiWorkoutProvider.notifier).generateWorkout(
          bodyType: profile?.bodyType ?? 'mesomorph',
          currentWeightKg: _weight,
          heightCm: _height,
          age: _age,
          medicalInjuries: _injuries,
        );

    if (mounted) {
      if (res.success) {
        Navigator.of(context).pop();
        final swapMsg = res.swappedExercisesCount > 0 ? ' (${res.swappedExercisesCount} safe substitutions applied)' : '';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${res.routineTitle} active! Assigned ${res.assignedTrack.toUpperCase()}$swapMsg'),
          backgroundColor: AppColors.surface,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.error ?? 'Assignment failed. Please check master templates.'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiWorkoutProvider);
    final flags = ref.watch(currentTenantFeatureFlagsProvider).asData?.value ?? const SystemFeatureFlags();
    final maxAge = ref.watch(maxAllowedAiAgeProvider);
    final isAgeBlocked = _age >= maxAge;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.80,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AiWorkoutSheetHeader(),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: AiWorkoutMetricInputs(
                  currentWeight: _weight,
                  currentHeight: _height,
                  age: _age,
                  maxAllowedAiAge: maxAge,
                  selectedInjuries: _injuries,
                  onWeightChanged: (w) => setState(() => _weight = w),
                  onHeightChanged: (h) => setState(() => _height = h),
                  onAgeChanged: (a) => setState(() => _age = a),
                  onToggleInjury: _toggleInjury,
                ),
              ),
            ),
            if (!flags.aiWorkouts) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('AI Workouts disabled by Super Admin or Gym Management', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ],
            PrimaryButton(
              text: !flags.aiWorkouts
                  ? 'MODULE DISABLED'
                  : (isAgeBlocked
                      ? 'CONSULT PHYSICAL TRAINER'
                      : (aiState.isGenerating ? 'ASSIGNING PROTOCOL...' : 'ASSIGN 90-DAY MASTER PROTOCOL')),
              icon: !flags.aiWorkouts
                  ? Icons.lock_rounded
                  : (isAgeBlocked ? Icons.health_and_safety_rounded : Icons.checklist_rtl_rounded),
              onPressed: (!flags.aiWorkouts || aiState.isGenerating)
                  ? null
                  : (isAgeBlocked
                      ? () => TrainerConsultationSafetyDialog.show(context, maxAllowedAiAge: maxAge)
                      : () => _assignRoutine(maxAge)),
            ),
          ],
        ),
      ),
    );
  }
}
