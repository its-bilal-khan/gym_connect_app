import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/gamification_provider.dart';
import 'providers/workout_notifier.dart';
import 'widgets/active_workout_app_bar.dart';
import 'widgets/confetti_celebration_dialog.dart';
import 'widgets/exercise_pip_player.dart';
import 'widgets/exercise_tab_bar.dart';
import 'widgets/rest_timer_overlay.dart';
import 'widgets/set_tracker_tile.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  void _confirmFinish(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('FINISH WORKOUT?', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text('All sets and volume will be logged to your fitness history and streak count.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('RESUME', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workoutNotifierProvider);
    final routine = session.routineDay;
    if (routine == null || routine.exercises.isEmpty) {
      return const Scaffold(body: SafeArea(child: Center(child: CircularProgressIndicator())));
    }

    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final currentExercise = routine.exercises[session.activeExerciseIndex];
    final sets = session.setsByExercise[currentExercise.id] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ActiveWorkoutAppBar(
        title: routine.title,
        progress: session.progressPercentage,
        onFinish: () => _confirmFinish(context, ref),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 110 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExerciseTabBar(
                    exercises: routine.exercises,
                    activeIndex: session.activeExerciseIndex,
                    onSelect: (i) => ref.read(workoutNotifierProvider.notifier).selectExercise(i),
                    accentColor: accent,
                  ),
                  const SizedBox(height: 14),
                  ExercisePipPlayer(exercise: currentExercise.exercise),
                  const SizedBox(height: 16),
                  Text('SETS & REPS TRACKER', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  ...List.generate(sets.length, (idx) {
                    return SetTrackerTile(
                      record: sets[idx],
                      onToggle: () => ref.read(workoutNotifierProvider.notifier).toggleSet(currentExercise.id, idx),
                      onWeightChanged: (w) => ref.read(workoutNotifierProvider.notifier).updateSetWeight(currentExercise.id, idx, w),
                      onRepsChanged: (r) => ref.read(workoutNotifierProvider.notifier).updateSetReps(currentExercise.id, idx, r),
                    );
                  }),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12 + bottomInset,
              child: const RestTimerOverlay(),
            ),
          ],
        ),
      ),
    );
  }
}
