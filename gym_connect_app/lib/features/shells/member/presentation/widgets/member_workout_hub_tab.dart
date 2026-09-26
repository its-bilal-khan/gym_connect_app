import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/domain/models/user_role.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../workout/domain/models/workout_models.dart';
import '../../../../workout/presentation/active_workout_screen.dart';
import '../../../../workout/presentation/providers/workout_notifier.dart';
import '../../../../workout/presentation/widgets/attach_exercise_video_sheet.dart';
import '../../../../workout/presentation/widgets/fullscreen_video_dialog.dart';
import '../../../../workout/presentation/widgets/ninety_day_calendar_widget.dart';

import '../../../../workout/presentation/providers/body_types_catalog_provider.dart';
import '../../../../workout/presentation/widgets/body_type_shape_gallery_dialog.dart';

class MemberWorkoutHubTab extends ConsumerWidget {
  const MemberWorkoutHubTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutNotifierProvider);
    final catalogAsync = ref.watch(bodyTypesCatalogProvider);
    final authState = ref.watch(authNotifierProvider);
    final canEdit = (authState is AuthAuthenticated) &&
        (authState.activeRole == UserRole.superAdmin || authState.activeRole == UserRole.owner);
    final routine = workoutState.routineDay;
    final dayNum = routine?.dayNumber ?? 1;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    final currentInfo = catalogAsync.asData?.value.firstWhere(
      (b) => b.key == workoutState.activeBodyType,
      orElse: () => BodyTypeInfo(
        key: workoutState.activeBodyType,
        title: workoutState.activeBodyType.toUpperCase(),
        subtitle: 'Protocol Split',
        description: '',
        targetPhysique: 'Outcome: Sculpted Physique Blueprint',
        defaultImageAsset: 'assets/images/${workoutState.activeBodyType}.jpg',
      ),
    );

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
                      Row(
                        children: [
                          Text(
                            'DAY $dayNum OF 90',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: currentInfo != null
                                ? () => BodyTypeShapeGalleryDialog.show(context, info: currentInfo)
                                : null,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: accent.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_library_rounded, size: 10, color: accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${workoutState.activeBodyType.toUpperCase()} • TARGET SHAPES',
                                    style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
              ...routine.exercises.map((wde) => _buildExerciseCard(context, wde, accent, canEdit)),
            ],
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, WorkoutDayExercise wde, Color accent, bool canEdit) {
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ex.videoUrl != null && ex.videoUrl!.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 28),
                  tooltip: 'Watch Form Video',
                  onPressed: () => FullscreenVideoDialog.show(context, ex),
                ),
              if (canEdit)
                IconButton(
                  icon: Icon(
                    ex.videoUrl != null && ex.videoUrl!.isNotEmpty
                        ? Icons.edit_note_rounded
                        : Icons.add_link_rounded,
                    color: ex.videoUrl != null && ex.videoUrl!.isNotEmpty
                        ? Colors.white54
                        : AppColors.primary,
                    size: 22,
                  ),
                  tooltip: ex.videoUrl != null && ex.videoUrl!.isNotEmpty
                      ? 'Edit / Update Video URL'
                      : 'Attach Exercise Video URL',
                  onPressed: () => AttachExerciseVideoSheet.show(context, ex),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
