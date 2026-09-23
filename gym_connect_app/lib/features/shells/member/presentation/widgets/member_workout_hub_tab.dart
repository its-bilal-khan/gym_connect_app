import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../workout/domain/models/workout_models.dart';
import '../../../../workout/presentation/active_workout_screen.dart';
import '../../../../workout/presentation/providers/workout_notifier.dart';
import '../../../../workout/presentation/widgets/fullscreen_video_dialog.dart';
import '../../../../workout/presentation/widgets/ninety_day_calendar_widget.dart';

class MemberWorkoutHubTab extends ConsumerWidget {
  const MemberWorkoutHubTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutNotifierProvider);
    final routine = workoutState.routineDay;
    final dayNum = routine?.dayNumber ?? 1;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NinetyDayCalendarWidget(
              currentDay: dayNum,
              onDaySelected: (day) => ref.read(workoutNotifierProvider.notifier).loadTodayRoutine(day: day),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAY $dayNum OF 90',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        routine?.title ?? 'Personalized AI Routine',
                        style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                if (routine != null && !routine.isRestDay)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      ref.read(workoutNotifierProvider.notifier).startWorkout();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text('START', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (routine != null && routine.muscleGroups.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: routine.muscleGroups.map((group) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      group.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            if (routine != null && routine.isRestDay)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.self_improvement_rounded, size: 48, color: Colors.cyanAccent),
                    const SizedBox(height: 10),
                    Text(
                      'ACTIVE RECOVERY & REPAIR',
                      style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Muscle fibers undergo protein synthesis on rest days. Stay hydrated, hit your daily protein goal, and aim for 8,000 restorative steps.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              )
            else if (routine != null && routine.exercises.isNotEmpty) ...[
              Text(
                'GROUPED EXERCISES (${routine.exercises.length})',
                style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              ...routine.exercises.map((wde) => _buildExerciseCard(context, wde, accent)),
            ],
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, WorkoutDayExercise wde, Color accent) {
    final ex = wde.exercise;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${wde.orderIndex}',
              style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.name,
                  style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ex.targetMuscle,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${wde.targetSets} Sets × ${wde.targetRepsRange} Reps',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
                    ),
                  ],
                ),
                if (ex.tips.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ex.tips,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (ex.videoUrl != null)
            IconButton(
              icon: const Icon(Icons.play_circle_outline_rounded, color: Colors.white70, size: 26),
              tooltip: 'Form Video Preview',
              onPressed: () => FullscreenVideoDialog.show(context, ex),
            ),
        ],
      ),
    );
  }
}
