import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/gamification_provider.dart';
import '../providers/workout_notifier.dart';
import 'confetti_celebration_dialog.dart';

class WorkoutFinishDialog {
  static void show(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('FINISH WORKOUT?',
            style: GoogleFonts.oswald(
                fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text('All sets and volume will be logged to your fitness history and streak count.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('RESUME',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final session = ref.read(workoutNotifierProvider);
              int totalSets = 0;
              double totalVol = 0;
              for (final sets in session.setsByExercise.values) {
                for (final s in sets.where((item) => item.isCompleted)) {
                  totalSets++;
                  totalVol += (s.weightKg * s.actualReps);
                }
              }
              ref.read(workoutNotifierProvider.notifier).finishWorkout();
              ref.read(gamificationProvider.notifier).awardWorkoutCompletionPoints(points: 100);

              ConfettiCelebrationDialog.show(
                context,
                totalSets: totalSets > 0 ? totalSets : 12,
                totalVolumeKg: totalVol > 0 ? totalVol : 2850.0,
                durationMinutes: 45,
                onClose: () => Navigator.of(context).pop(),
              );
            },
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );
  }
}
