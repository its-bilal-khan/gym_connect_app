import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../workout/domain/models/workout_models.dart';
import '../../../../workout/presentation/providers/exercise_catalog_provider.dart';
import '../../../../workout/presentation/widgets/exercise_video_preview_thumbnail.dart';
import '../../../../workout/presentation/widgets/fullscreen_video_dialog.dart';
import 'add_edit_exercise_video_dialog.dart';

class ExerciseVideoStudioTab extends ConsumerStatefulWidget {
  const ExerciseVideoStudioTab({super.key});

  @override
  ConsumerState<ExerciseVideoStudioTab> createState() =>
      _ExerciseVideoStudioTabState();
}

class _ExerciseVideoStudioTabState
    extends ConsumerState<ExerciseVideoStudioTab> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(exerciseCatalogNotifierProvider);
    final notifier = ref.read(exerciseCatalogNotifierProvider.notifier);
    final exercises = catalogState.filteredExercises;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsStrip(catalogState),
          const SizedBox(height: 24),
          _buildControlsRow(context, ref, catalogState, notifier),
          const SizedBox(height: 20),
          if (catalogState.isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (exercises.isEmpty)
            _buildEmptyState(context)
          else if (_isGridView)
            _buildExerciseGrid(context, exercises, notifier)
          else
            _buildExerciseList(context, exercises, notifier),
        ],
      ),
    );
  }

  Widget _buildMetricsStrip(ExerciseCatalogState state) {
    final total = state.totalExercises;
    final withVideo = state.withVideoCount;
    final pct = total > 0 ? ((withVideo / total) * 100).toInt() : 0;

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            title: 'TOTAL EXERCISES',
            value: '$total',
            subtitle: 'Master Global Library',
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _metricCard(
            title: 'VIDEOS ATTACHED',
            value: '$withVideo',
            subtitle: '$pct% of library with stream',
            icon: Icons.video_camera_front_rounded,
            color: Colors.cyanAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _metricCard(
            title: 'MUSCLE CATEGORIES',
            value: '7',
            subtitle: 'Full Body Coverage',
            icon: Icons.accessibility_new_rounded,
            color: Colors.amberAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _metricCard(
            title: 'CDN STREAM ENGINE',
            value: 'HLS / MP4',
            subtitle: 'Dual-Angle Mobile Stream',
            icon: Icons.stream_rounded,
            color: Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(
    BuildContext context,
    WidgetRef ref,
    ExerciseCatalogState state,
    ExerciseCatalogNotifier notifier,
  ) {
    const muscles = [
      'All',
      'Chest',
      'Back',
      'Legs',
      'Shoulders',
      'Arms',
      'Core',
      'Full Body',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => notifier.setSearchQuery(val),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by exercise name, target muscle, equipment...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.onlyWithVideos
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: state.onlyWithVideos
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  const Text('Only With Videos'),
                ],
              ),
              selected: state.onlyWithVideos,
              onSelected: (_) => notifier.toggleOnlyWithVideos(),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              side: BorderSide(
                color: state.onlyWithVideos
                    ? AppColors.primary
                    : AppColors.border,
              ),
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: state.onlyWithVideos
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: state.onlyWithVideos
                    ? AppColors.primary
                    : Colors.white,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _toggleIconBtn(
                    icon: Icons.grid_view_rounded,
                    active: _isGridView,
                    tooltip: 'Grid View',
                    onTap: () => setState(() => _isGridView = true),
                  ),
                  const SizedBox(width: 4),
                  _toggleIconBtn(
                    icon: Icons.view_list_rounded,
                    active: !_isGridView,
                    tooltip: 'List View',
                    onTap: () => setState(() => _isGridView = false),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              onPressed: () => AddEditExerciseVideoDialog.show(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('ADD EXERCISE & VIDEO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: muscles.map((m) {
              final isSelected = state.selectedMuscle == m;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(m),
                  selected: isSelected,
                  onSelected: (_) => notifier.setSelectedMuscle(m),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.videocam_off_rounded,
              size: 48, color: Colors.white24),
          const SizedBox(height: 14),
          Text(
            'No Exercises Found',
            style: GoogleFonts.oswald(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Try changing your search keywords, muscle filter, or click Add Exercise & Video to upload.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => AddEditExerciseVideoDialog.show(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add First Exercise Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseGrid(
    BuildContext context,
    List<Exercise> exercises,
    ExerciseCatalogNotifier notifier,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 440,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 330,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final ex = exercises[index];
        return _buildExerciseCard(context, ex, notifier);
      },
    );
  }

  Widget _toggleIconBtn({
    required IconData icon,
    required bool active,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? Colors.black : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    List<Exercise> exercises,
    ExerciseCatalogNotifier notifier,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final ex = exercises[index];
        final hasVideo = ex.videoUrl != null && ex.videoUrl!.isNotEmpty;
        final hasSideVideo =
            ex.sideVideoUrl != null && ex.sideVideoUrl!.isNotEmpty;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasVideo
                  ? AppColors.border
                  : AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              ExerciseVideoPreviewThumbnail(
                exercise: ex,
                width: 90,
                height: 56,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ex.targetMuscle} • ${ex.equipment} • ${ex.difficulty}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasVideo
                          ? Colors.green.withValues(alpha: 0.15)
                          : AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hasVideo ? 'FRONT ACTIVE' : 'NO VIDEO',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasVideo ? Colors.greenAccent : AppColors.warning,
                      ),
                    ),
                  ),
                  if (hasSideVideo) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SIDE ANGLE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  if (hasVideo)
                    IconButton(
                      icon: Icon(Icons.play_circle_fill_rounded,
                          color: AppColors.primary, size: 22),
                      tooltip: 'Play Stream',
                      onPressed: () => FullscreenVideoDialog.show(context, ex),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded,
                        color: Colors.white70, size: 20),
                    tooltip: 'Edit Exercise Video',
                    onPressed: () =>
                        AddEditExerciseVideoDialog.show(context, exercise: ex),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 20),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context, ex, notifier),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise ex,
    ExerciseCatalogNotifier notifier,
  ) {
    final hasVideo = ex.videoUrl != null && ex.videoUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasVideo
              ? AppColors.border
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: GoogleFonts.oswald(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ex.targetMuscle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          '• ${ex.equipment}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: Colors.white54, size: 20),
                color: AppColors.surface,
                onSelected: (val) {
                  if (val == 'edit') {
                    AddEditExerciseVideoDialog.show(context, exercise: ex);
                  } else if (val == 'delete') {
                    _confirmDelete(context, ex, notifier);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded,
                            size: 16, color: Colors.white70),
                        const SizedBox(width: 10),
                        Text('Edit Exercise',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 10),
                        Text('Delete',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ExerciseVideoPreviewThumbnail(
            exercise: ex,
            height: 110,
            width: double.infinity,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              ex.tips,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(color: AppColors.border, height: 12),
          Row(
            children: [
              if (hasVideo)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => FullscreenVideoDialog.show(context, ex),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                    label: const Text('WATCH VIDEO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.oswald(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        AddEditExerciseVideoDialog.show(context, exercise: ex),
                    icon: const Icon(Icons.add_link_rounded, size: 16),
                    label: const Text('ATTACH VIDEO'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: BorderSide(
                          color: AppColors.warning.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.oswald(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded,
                    color: Colors.white70, size: 20),
                tooltip: 'Edit Details / URL',
                onPressed: () =>
                    AddEditExerciseVideoDialog.show(context, exercise: ex),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Exercise ex,
    ExerciseCatalogNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'DELETE EXERCISE?',
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${ex.name}" from the master exercise library?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.deleteExercise(ex.id);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
