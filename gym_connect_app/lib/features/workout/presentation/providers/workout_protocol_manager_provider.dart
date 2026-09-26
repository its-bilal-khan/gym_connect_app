import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/workout_repository.dart';
import '../../domain/models/workout_models.dart';
import 'workout_notifier.dart';

class WorkoutProtocolManagerState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final String selectedBodyType;
  final int selectedDayNumber;
  final FullWeeklyProtocolResult? currentProtocol;
  final List<WorkoutRoutineDay> workingDays;
  final List<Exercise> exerciseCatalog;
  final bool isDirty;
  final String? targetTenantId;
  final bool isPlatformMasterMode;
  final bool canEdit;
  final DateTime? lastSavedAt;

  const WorkoutProtocolManagerState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.selectedBodyType = 'mesomorph',
    this.selectedDayNumber = 1,
    this.currentProtocol,
    this.workingDays = const [],
    this.exerciseCatalog = const [],
    this.isDirty = false,
    this.targetTenantId,
    this.isPlatformMasterMode = false,
    this.canEdit = false,
    this.lastSavedAt,
  });

  bool get isCustomOverride => currentProtocol?.isCustomTenantOverride ?? false;

  WorkoutRoutineDay? get activeDay {
    if (workingDays.isEmpty) return null;
    return workingDays.firstWhere(
      (d) => d.dayNumber == selectedDayNumber,
      orElse: () => workingDays.first,
    );
  }

  WorkoutProtocolManagerState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    String? selectedBodyType,
    int? selectedDayNumber,
    FullWeeklyProtocolResult? currentProtocol,
    List<WorkoutRoutineDay>? workingDays,
    List<Exercise>? exerciseCatalog,
    bool? isDirty,
    String? targetTenantId,
    bool? isPlatformMasterMode,
    bool? canEdit,
    DateTime? lastSavedAt,
  }) {
    return WorkoutProtocolManagerState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      selectedBodyType: selectedBodyType ?? this.selectedBodyType,
      selectedDayNumber: selectedDayNumber ?? this.selectedDayNumber,
      currentProtocol: currentProtocol ?? this.currentProtocol,
      workingDays: workingDays ?? this.workingDays,
      exerciseCatalog: exerciseCatalog ?? this.exerciseCatalog,
      isDirty: isDirty ?? this.isDirty,
      targetTenantId: targetTenantId ?? this.targetTenantId,
      isPlatformMasterMode: isPlatformMasterMode ?? this.isPlatformMasterMode,
      canEdit: canEdit ?? this.canEdit,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }
}

class WorkoutProtocolManagerNotifier extends Notifier<WorkoutProtocolManagerState> {
  Timer? _autoSaveTimer;

  @override
  WorkoutProtocolManagerState build() {
    ref.onDispose(() {
      _autoSaveTimer?.cancel();
    });
    return const WorkoutProtocolManagerState();
  }

  WorkoutRepository get _repository => ref.read(workoutRepositoryProvider);

  bool get _isAuthorizedUser {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return false;
    return auth.activeRole == UserRole.superAdmin || auth.activeRole == UserRole.owner;
  }

  void _triggerAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 900), () {
      saveProtocol(isAutoSave: true);
    });
  }

  Future<void> initialize({
    required String? userTenantId,
    String bodyType = 'mesomorph',
    bool forcePlatformMaster = false,
  }) async {
    final canEdit = _isAuthorizedUser;
    state = state.copyWith(
      isLoading: true,
      canEdit: canEdit,
      selectedBodyType: bodyType.toLowerCase().trim(),
      targetTenantId: forcePlatformMaster ? null : userTenantId,
      isPlatformMasterMode: forcePlatformMaster || (userTenantId == null || userTenantId.isEmpty),
    );

    try {
      final catalogFuture = _repository.fetchExerciseCatalog();
      final effectiveTenantId = state.isPlatformMasterMode ? null : state.targetTenantId;
      final protocolFuture = _repository.fetchFullWeeklyProtocol(
        bodyType: state.selectedBodyType,
        tenantId: effectiveTenantId,
      );

      final results = await Future.wait([catalogFuture, protocolFuture]);
      final catalog = results[0] as List<Exercise>;
      final protocol = results[1] as FullWeeklyProtocolResult;

      state = state.copyWith(
        isLoading: false,
        canEdit: canEdit,
        exerciseCatalog: catalog,
        currentProtocol: protocol,
        workingDays: List.of(protocol.days),
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        canEdit: canEdit,
        errorMessage: 'Failed to load workout protocols: $e',
      );
    }
  }

  Future<void> selectBodyType(String bodyType) async {
    if (state.selectedBodyType == bodyType.toLowerCase().trim()) return;
    await initialize(
      userTenantId: state.targetTenantId,
      bodyType: bodyType,
      forcePlatformMaster: state.isPlatformMasterMode,
    );
  }

  void selectDay(int dayNumber) {
    if (state.selectedDayNumber == dayNumber) return;
    state = state.copyWith(selectedDayNumber: dayNumber);
  }

  void toggleRestDay(int dayNumber, bool isRest) => setDayRestStatus(dayNumber, isRest);

  void setDayRestStatus(int dayNumber, bool isRest) {
    if (!_isAuthorizedUser) {
      state = state.copyWith(errorMessage: 'Access Denied: Only Super Admin & Gym Owner can edit protocols.');
      return;
    }

    final updatedDays = state.workingDays.map((d) {
      if (d.dayNumber == dayNumber) {
        return d.copyWith(
          isRestDay: isRest,
          exercises: isRest ? [] : d.exercises,
        );
      }
      return d;
    }).toList();

    state = state.copyWith(
      workingDays: updatedDays,
      isDirty: true,
    );

    _triggerAutoSave();
  }

  void updateDayMetadata(int dayNumber, {required String title, required List<String> muscleGroups}) {
    if (!_isAuthorizedUser) {
      state = state.copyWith(errorMessage: 'Access Denied: Only Super Admin & Gym Owner can edit protocols.');
      return;
    }

    final updatedDays = state.workingDays.map((d) {
      if (d.dayNumber == dayNumber) {
        return d.copyWith(
          title: title,
          muscleGroups: muscleGroups,
        );
      }
      return d;
    }).toList();

    state = state.copyWith(
      workingDays: updatedDays,
      isDirty: true,
    );

    _triggerAutoSave();
  }

  void addExerciseToDay(
    int dayNumber,
    Exercise exercise, {
    int targetSets = 4,
    String targetRepsRange = '8-12',
    int restSeconds = 60,
    String? notes,
  }) {
    if (!_isAuthorizedUser) {
      state = state.copyWith(errorMessage: 'Access Denied: Only Super Admin & Gym Owner can add exercises.');
      return;
    }

    final updatedDays = state.workingDays.map((d) {
      if (d.dayNumber == dayNumber) {
        final newExercise = WorkoutDayExercise(
          id: 'wde-new-${DateTime.now().millisecondsSinceEpoch}-${d.exercises.length + 1}',
          exercise: exercise,
          orderIndex: d.exercises.length + 1,
          targetSets: targetSets,
          targetRepsRange: targetRepsRange,
          restSeconds: restSeconds,
          notes: notes,
        );
        return d.copyWith(
          isRestDay: false,
          exercises: [...d.exercises, newExercise],
        );
      }
      return d;
    }).toList();

    state = state.copyWith(
      workingDays: updatedDays,
      isDirty: true,
    );

    _triggerAutoSave();
  }

  void removeExerciseFromDay(int dayNumber, int exerciseIndex) {
    if (!_isAuthorizedUser) {
      state = state.copyWith(errorMessage: 'Access Denied: Only Super Admin & Gym Owner can remove exercises.');
      return;
    }

    final updatedDays = state.workingDays.map((d) {
      if (d.dayNumber == dayNumber) {
        final currentExercises = List<WorkoutDayExercise>.of(d.exercises);
        if (exerciseIndex >= 0 && exerciseIndex < currentExercises.length) {
          currentExercises.removeAt(exerciseIndex);
          final reindexed = <WorkoutDayExercise>[];
          for (int i = 0; i < currentExercises.length; i++) {
            reindexed.add(currentExercises[i].copyWith(orderIndex: i + 1));
          }
          return d.copyWith(exercises: reindexed);
        }
      }
      return d;
    }).toList();

    state = state.copyWith(
      workingDays: updatedDays,
      isDirty: true,
    );

    _triggerAutoSave();
  }

  void reorderExercise(int dayNumber, int oldIndex, int newIndex) {
    if (!_isAuthorizedUser) {
      state = state.copyWith(errorMessage: 'Access Denied: Only Super Admin & Gym Owner can reorder exercises.');
      return;
    }

    final updatedDays = state.workingDays.map((d) {
      if (d.dayNumber == dayNumber) {
        final list = List<WorkoutDayExercise>.of(d.exercises);
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = list.removeAt(oldIndex);
        list.insert(newIndex, item);

        final reindexed = <WorkoutDayExercise>[];
        for (int i = 0; i < list.length; i++) {
          reindexed.add(list[i].copyWith(orderIndex: i + 1));
        }
        return d.copyWith(exercises: reindexed);
      }
      return d;
    }).toList();

    state = state.copyWith(
      workingDays: updatedDays,
      isDirty: true,
    );

    _triggerAutoSave();
  }

  void updateExerciseParameters(
    int dayNumber,
    int exerciseIndex, {
    int? targetSets,
    String? targetRepsRange,
    int? restSeconds,
    String? notes,
  }) {
    if (!_isAuthorizedUser) {
      state = state.copyWith(errorMessage: 'Access Denied: Only Super Admin & Gym Owner can edit exercise parameters.');
      return;
    }

    final updatedDays = state.workingDays.map((d) {
      if (d.dayNumber == dayNumber) {
        final currentExercises = List<WorkoutDayExercise>.of(d.exercises);
        if (exerciseIndex >= 0 && exerciseIndex < currentExercises.length) {
          final target = currentExercises[exerciseIndex];
          currentExercises[exerciseIndex] = target.copyWith(
            targetSets: targetSets,
            targetRepsRange: targetRepsRange,
            restSeconds: restSeconds,
            notes: notes,
          );
          return d.copyWith(exercises: currentExercises);
        }
      }
      return d;
    }).toList();

    state = state.copyWith(
      workingDays: updatedDays,
      isDirty: true,
    );

    _triggerAutoSave();
  }

  void updateExerciseInProtocol(Exercise updatedExercise) {
    if (!_isAuthorizedUser) {
      state = state.copyWith(errorMessage: 'Access Denied: Only Super Admin & Gym Owner can update exercise catalog.');
      return;
    }

    final cleanUpdatedName = updatedExercise.name.toLowerCase().trim();
    final updatedDays = state.workingDays.map((d) {
      final updatedExercises = d.exercises.map((item) {
        if (item.exercise.id == updatedExercise.id ||
            item.exercise.name.toLowerCase().trim() == cleanUpdatedName) {
          return item.copyWith(
            exercise: updatedExercise.copyWith(
              id: item.exercise.id,
            ),
          );
        }
        return item;
      }).toList();
      return d.copyWith(exercises: updatedExercises);
    }).toList();

    final updatedCatalog = state.exerciseCatalog.map((ex) {
      if (ex.id == updatedExercise.id ||
          ex.name.toLowerCase().trim() == cleanUpdatedName) {
        return updatedExercise;
      }
      return ex;
    }).toList();

    state = state.copyWith(
      workingDays: updatedDays,
      exerciseCatalog: updatedCatalog,
      isDirty: true,
    );

    _triggerAutoSave();
  }

  Future<bool> saveProtocol({bool isAutoSave = false}) async {
    _autoSaveTimer?.cancel();
    if (!_isAuthorizedUser) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Access Denied: Only Super Admin & Gym Owner can save protocols.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final effectiveTenantId = state.isPlatformMasterMode ? null : state.targetTenantId;
      await _repository.saveCustomWeeklyProtocol(
        bodyType: state.selectedBodyType,
        tenantId: effectiveTenantId,
        days: state.workingDays,
        protocolTitle: state.isPlatformMasterMode
            ? '${state.selectedBodyType.toUpperCase()} Global Master Protocol'
            : '${state.selectedBodyType.toUpperCase()} Custom Gym Protocol',
        protocolDescription: state.isPlatformMasterMode
            ? 'Platform master protocol automatically active for all standard gym tenants.'
            : 'Custom overridden protocol specifically tailored for this facility.',
      );

      final updatedProtocol = await _repository.fetchFullWeeklyProtocol(
        bodyType: state.selectedBodyType,
        tenantId: effectiveTenantId,
      );

      state = state.copyWith(
        isSaving: false,
        currentProtocol: updatedProtocol,
        workingDays: List.of(updatedProtocol.days),
        isDirty: false,
        lastSavedAt: DateTime.now(),
        successMessage: isAutoSave
            ? 'Auto-saved to cloud ✓'
            : (state.isPlatformMasterMode
                ? 'Universal Master Protocol saved successfully for all default gyms!'
                : 'Gym Workout Protocol saved successfully! Your members now see this routine.'),
      );

      try {
        ref.read(workoutNotifierProvider.notifier).loadTodayRoutine(
          day: state.selectedDayNumber,
          bodyType: state.selectedBodyType,
        );
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('WorkoutProtocolManager: saveWorkoutProtocol caught error: $e');
      final isRlsError = e.toString().contains('42501') || e.toString().contains('row-level security');
      final errorMsg = isRlsError
          ? 'Supabase RLS (42501): Please run updated 20260926040000_fix_workout_protocols_rls_policies.sql (Public Access) in Supabase SQL editor.'
          : 'Failed to save protocol: $e';
      state = state.copyWith(
        isSaving: false,
        errorMessage: errorMsg,
      );
      return false;
    }
  }

  Future<bool> resetToDefault() async {
    if (!_isAuthorizedUser) {
      state = state.copyWith(errorMessage: 'Access Denied: Only Super Admin & Gym Owner can reset protocols.');
      return false;
    }

    if (state.targetTenantId == null || state.targetTenantId!.isEmpty) {
      state = state.copyWith(errorMessage: 'Platform master cannot be reset via tenant override.');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      await _repository.resetToPlatformDefault(
        bodyType: state.selectedBodyType,
        tenantId: state.targetTenantId!,
      );

      final masterProtocol = await _repository.fetchFullWeeklyProtocol(
        bodyType: state.selectedBodyType,
        tenantId: state.targetTenantId,
      );

      state = state.copyWith(
        isSaving: false,
        currentProtocol: masterProtocol,
        workingDays: List.of(masterProtocol.days),
        isDirty: false,
        lastSavedAt: DateTime.now(),
        successMessage: 'Custom gym protocol reset! Routine has reverted to the Platform Master Default.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to reset protocol: $e',
      );
      return false;
    }
  }
}

final workoutProtocolManagerProvider = NotifierProvider.autoDispose<
    WorkoutProtocolManagerNotifier, WorkoutProtocolManagerState>(() {
  return WorkoutProtocolManagerNotifier();
});
