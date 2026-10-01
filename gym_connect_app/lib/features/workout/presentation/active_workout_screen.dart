import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/workout_notifier.dart';
import 'widgets/active_workout_app_bar.dart';
import 'widgets/exercise_swap_trigger_button.dart';
import 'widgets/workout_media_viewport.dart';
import 'widgets/exercise_tab_bar.dart';
import 'widgets/rest_timer_overlay.dart';
import 'widgets/set_tracker_tile.dart';
import 'widgets/workout_finish_dialog.dart';
import '../../gamification/presentation/widgets/ai_rep_counter_sheet.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

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
        onFinish: () => WorkoutFinishDialog.show(context, ref),
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
                  WorkoutMediaViewport(
                    exercise: currentExercise.exercise,
                    targetReps: int.tryParse(currentExercise.targetRepsRange.split('-').last.trim()) ?? 12,
                    onRepCountChanged: (reps) {
                      final activeSetIdx = sets.indexWhere((s) => !s.isCompleted);
                      if (activeSetIdx != -1) {
                        ref.read(workoutNotifierProvider.notifier).updateSetReps(currentExercise.id, activeSetIdx, reps);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('SETS & REPS TRACKER',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.oswald(
                                fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => AiRepCounterSheet.show(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: accent.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(8),
                            color: accent.withValues(alpha: 0.1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam_rounded, size: 14, color: accent),
                              const SizedBox(width: 4),
                              Text('AI COUNTER', style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ExerciseSwapTriggerButton(
                        dayExerciseId: currentExercise.id,
                        exerciseName: currentExercise.exercise.name,
                        targetMuscle: currentExercise.exercise.targetMuscle,
                      ),
                    ],
                  ),
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
