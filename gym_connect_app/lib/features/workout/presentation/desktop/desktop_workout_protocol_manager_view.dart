import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/presentation/auth_gate.dart';
import '../../domain/models/workout_models.dart';
import '../providers/protocol_studio_view_mode_provider.dart';
import '../providers/workout_protocol_manager_provider.dart';
import 'widgets/body_type_selector_bar.dart';
import 'widgets/day_exercise_editor_card.dart';
import 'widgets/day_overview_toolbar.dart';
import 'widgets/exercise_catalog_picker_dialog.dart';
import 'widgets/protocol_studio_header.dart';
import 'widgets/weekly_day_split_picker.dart';

class DesktopWorkoutProtocolManagerView extends ConsumerStatefulWidget {
  final UserProfile profile;

  const DesktopWorkoutProtocolManagerView({super.key, required this.profile});

  static void open(BuildContext context, {required UserProfile profile}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          body: DesktopWorkoutProtocolManagerView(profile: profile),
        ),
      ),
    );
  }

  @override
  ConsumerState<DesktopWorkoutProtocolManagerView> createState() =>
      _DesktopWorkoutProtocolManagerViewState();
}

class _DesktopWorkoutProtocolManagerViewState
    extends ConsumerState<DesktopWorkoutProtocolManagerView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(workoutProtocolManagerProvider.notifier).initialize(
            userTenantId: widget.profile.tenantId,
          );
    });
  }

  void _onAddExercise(BuildContext context) async {
    final notifier = ref.read(workoutProtocolManagerProvider.notifier);
    final state = ref.read(workoutProtocolManagerProvider);
    if (!state.canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Super Admin & Gym Owner can add exercises.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final selected = await ExerciseCatalogPickerDialog.show(
      context,
      catalog: state.exerciseCatalog,
    );
    if (selected != null) {
      notifier.addExerciseToDay(state.selectedDayNumber, selected);
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutProtocolManagerProvider);
    final notifier = ref.read(workoutProtocolManagerProvider.notifier);
    final isGridView = ref.watch(protocolStudioGridViewProvider);

    ref.listen<WorkoutProtocolManagerState>(workoutProtocolManagerProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
        );
      }
    });

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () => _handleBack(context),
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return _buildMobileGuardView();
            }

            if (state.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final activeDay = state.activeDay;

            return Column(
              children: [
                ProtocolStudioHeader(
                  isCustomOverride: state.isCustomOverride,
                  isPlatformMasterMode: state.isPlatformMasterMode,
                  isDirty: state.isDirty,
                  isSaving: state.isSaving,
                  tenantId: widget.profile.tenantId,
                  onResetToDefault: () => notifier.resetToDefault(),
                  onSave: () => notifier.saveProtocol(),
                  onBack: () => _handleBack(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BodyTypeSelectorBar(
                          selectedBodyType: state.selectedBodyType,
                          onSelect: (type) => notifier.selectBodyType(type),
                        ),
                        const SizedBox(height: 20),
                        WeeklyDaySplitPicker(
                          days: state.workingDays,
                          selectedDayNumber: state.selectedDayNumber,
                          onSelectDay: (day) => notifier.selectDay(day),
                        ),
                        const SizedBox(height: 20),
                        if (activeDay != null) ...[
                          DayOverviewToolbar(
                            day: activeDay,
                            canEdit: state.canEdit,
                            onToggleRestDay: (val) => notifier.toggleRestDay(state.selectedDayNumber, val),
                            onAddExercise: () => _onAddExercise(context),
                            isGridView: isGridView,
                            onToggleGridView: (val) => ref.read(protocolStudioGridViewProvider.notifier).setGridView(val),
                          ),
                          const SizedBox(height: 16),
                          _buildExerciseSection(activeDay, notifier, state.canEdit, isGridView),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildExerciseSection(
      WorkoutRoutineDay activeDay,
      WorkoutProtocolManagerNotifier notifier,
      bool canEdit,
      bool isGridView) {
    if (activeDay.isRestDay) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bedtime_rounded, color: AppColors.warning, size: 40),
            const SizedBox(height: 12),
            Text(
              'Scheduled Rest & Muscle Hypertrophy Recovery Day',
              style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Members are advised to prioritize protein synthesis, hydration, and mobility.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (activeDay.exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.fitness_center_rounded, color: AppColors.textSecondary, size: 36),
            const SizedBox(height: 12),
            Text('No exercises added to this day yet', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            if (canEdit) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _onAddExercise(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Exercise Now'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              ),
            ],
          ],
        ),
      );
    }

    if (isGridView) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 460,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 260,
        ),
        itemCount: activeDay.exercises.length,
        itemBuilder: (context, i) {
          final item = activeDay.exercises[i];
          return DayExerciseEditorCard(
            key: ValueKey('grid-${item.id}'),
            index: i,
            exerciseItem: item,
            isGrid: true,
            canEdit: canEdit,
            onRemove: () =>
                notifier.removeExerciseFromDay(activeDay.dayNumber, i),
            onUpdate: (sets, reps, rest, notes) =>
                notifier.updateExerciseParameters(
              activeDay.dayNumber,
              i,
              targetSets: sets,
              targetRepsRange: reps,
              restSeconds: rest,
              notes: notes,
            ),
            onExerciseUpdated: (updatedEx) =>
                notifier.updateExerciseInProtocol(updatedEx),
          );
        },
      );
    }

    return Column(
      children: List.generate(activeDay.exercises.length, (i) {
        final item = activeDay.exercises[i];
        return DayExerciseEditorCard(
          key: ValueKey('list-${item.id}'),
          index: i,
          exerciseItem: item,
          isGrid: false,
          canEdit: canEdit,
          onRemove: () => notifier.removeExerciseFromDay(activeDay.dayNumber, i),
          onUpdate: (sets, reps, rest, notes) => notifier.updateExerciseParameters(
            activeDay.dayNumber,
            i,
            targetSets: sets,
            targetRepsRange: reps,
            restSeconds: rest,
            notes: notes,
          ),
          onExerciseUpdated: (updatedEx) =>
              notifier.updateExerciseInProtocol(updatedEx),
        );
      }),
    );
  }

  Widget _buildMobileGuardView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.desktop_windows_rounded, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'DESKTOP POS ONLY',
                style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'The Workout Protocol Studio is exclusively available on desktop view (800px+ width) to ensure maximum precision and prevent mobile app bloat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
