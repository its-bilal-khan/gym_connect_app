import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../super_admin/presentation/desktop/widgets/add_edit_exercise_video_dialog.dart';
import '../../../domain/models/workout_models.dart';
import '../../widgets/exercise_video_preview_thumbnail.dart';

class DayExerciseEditorCard extends StatelessWidget {
  final int index;
  final WorkoutDayExercise exerciseItem;
  final VoidCallback onRemove;
  final void Function(int targetSets, String reps, int restSeconds, String? notes) onUpdate;
  final void Function(Exercise updatedExercise)? onExerciseUpdated;
  final bool isGrid;
  final bool canEdit;

  const DayExerciseEditorCard({
    super.key,
    required this.index,
    required this.exerciseItem,
    required this.onRemove,
    required this.onUpdate,
    this.onExerciseUpdated,
    this.isGrid = false,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = exerciseItem.exercise.videoUrl != null &&
        exerciseItem.exercise.videoUrl!.trim().isNotEmpty;

    if (isGrid) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseItem.exercise.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exerciseItem.exercise.targetMuscle.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              exerciseItem.exercise.equipment,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          hasVideo
                              ? Icons.edit_note_rounded
                              : Icons.add_link_rounded,
                          color: hasVideo
                              ? Colors.white54
                              : AppColors.primary,
                          size: 18,
                        ),
                        tooltip: hasVideo ? 'Edit Video URL' : 'Attach Video',
                        onPressed: () async {
                          final updated = await AddEditExerciseVideoDialog.show(
                            context,
                            exercise: exerciseItem.exercise,
                          );
                          if (updated != null) {
                            onExerciseUpdated?.call(updated);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 18),
                        tooltip: 'Remove',
                        onPressed: onRemove,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Visible video preview in Grid View!
            if (hasVideo)
              ExerciseVideoPreviewThumbnail(
                exercise: exerciseItem.exercise,
                height: 105,
                width: double.infinity,
                borderRadius: BorderRadius.circular(10),
              )
            else if (canEdit)
              InkWell(
                onTap: () async {
                  final updated = await AddEditExerciseVideoDialog.show(
                    context,
                    exercise: exerciseItem.exercise,
                  );
                  if (updated != null) {
                    onExerciseUpdated?.call(updated);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 105,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_call_rounded,
                            size: 24, color: AppColors.primary.withValues(alpha: 0.7)),
                        const SizedBox(height: 4),
                        Text(
                          'Attach Form Video / Demo',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 105,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    'No Video Attached',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildSetsControl(),
                _buildRepsControl(),
                _buildRestSecondsControl(),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#${index + 1}',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              // Visible video preview in List View!
              if (hasVideo) ...[
                ExerciseVideoPreviewThumbnail(
                  exercise: exerciseItem.exercise,
                  width: 105,
                  height: 64,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseItem.exercise.name,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exerciseItem.exercise.targetMuscle.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          exerciseItem.exercise.equipment,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canEdit) ...[
                IconButton(
                  icon: Icon(
                    hasVideo
                        ? Icons.edit_note_rounded
                        : Icons.add_link_rounded,
                    color: hasVideo
                        ? Colors.white54
                        : AppColors.primary,
                    size: 20,
                  ),
                  tooltip: hasVideo ? 'Edit Video URL' : 'Attach / Edit Video URL',
                  onPressed: () async {
                    final updated = await AddEditExerciseVideoDialog.show(
                      context,
                      exercise: exerciseItem.exercise,
                    );
                    if (updated != null) {
                      onExerciseUpdated?.call(updated);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 20),
                  tooltip: 'Remove exercise',
                  onPressed: onRemove,
                ),
              ],
            ],
          ),
          const Divider(color: AppColors.border, height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildSetsControl(),
              _buildRepsControl(),
              _buildRestSecondsControl(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetsControl() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Sets: ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.white70),
          onPressed: canEdit && exerciseItem.targetSets > 1
              ? () => onUpdate(
                    exerciseItem.targetSets - 1,
                    exerciseItem.targetRepsRange,
                    exerciseItem.restSeconds,
                    exerciseItem.notes,
                  )
              : null,
        ),
        Text(
          '${exerciseItem.targetSets}',
          style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white70),
          onPressed: canEdit && exerciseItem.targetSets < 10
              ? () => onUpdate(
                    exerciseItem.targetSets + 1,
                    exerciseItem.targetRepsRange,
                    exerciseItem.restSeconds,
                    exerciseItem.notes,
                  )
              : null,
        ),
      ],
    );
  }

  Widget _buildRepsControl() {
    final repOptions = ['6-8', '8-10', '8-12', '10-12', '12-15', '15-20', 'Failure'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Reps: ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        DropdownButton<String>(
          isDense: true,
          value: repOptions.contains(exerciseItem.targetRepsRange) ? exerciseItem.targetRepsRange : '8-12',
          dropdownColor: AppColors.surface,
          underline: const SizedBox(),
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          items: repOptions
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: canEdit
              ? (val) {
                  if (val != null) {
                    onUpdate(exerciseItem.targetSets, val, exerciseItem.restSeconds, exerciseItem.notes);
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildRestSecondsControl() {
    final restOptions = [30, 45, 60, 90, 120, 180];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rest: ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        DropdownButton<int>(
          isDense: true,
          value: restOptions.contains(exerciseItem.restSeconds) ? exerciseItem.restSeconds : 60,
          dropdownColor: AppColors.surface,
          underline: const SizedBox(),
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
          items: restOptions
              .map((s) => DropdownMenuItem(value: s, child: Text('${s}s')))
              .toList(),
          onChanged: canEdit
              ? (val) {
                  if (val != null) {
                    onUpdate(exerciseItem.targetSets, exerciseItem.targetRepsRange, val, exerciseItem.notes);
                  }
                }
              : null,
        ),
      ],
    );
  }
}
