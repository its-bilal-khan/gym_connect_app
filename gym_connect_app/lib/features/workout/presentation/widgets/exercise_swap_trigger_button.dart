import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/ai_workout_provider.dart';
import 'exercise_swap_sheet.dart';

class ExerciseSwapTriggerButton extends ConsumerWidget {
  final String dayExerciseId;
  final String exerciseName;
  final String targetMuscle;

  const ExerciseSwapTriggerButton({
    super.key,
    required this.dayExerciseId,
    required this.exerciseName,
    required this.targetMuscle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        await ref.read(aiWorkoutProvider.notifier).loadSwapCandidates(targetMuscle: targetMuscle);
        if (context.mounted) {
          ExerciseSwapSheet.show(
            context,
            dayExerciseId: dayExerciseId,
            currentExerciseName: exerciseName,
            targetMuscle: targetMuscle,
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('SWAP', style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
