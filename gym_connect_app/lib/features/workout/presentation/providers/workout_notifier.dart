import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/workout_repository.dart';
import '../../domain/models/workout_models.dart';
import 'rest_timer_notifier.dart';

class WorkoutSessionState {
  final WorkoutRoutineDay? routineDay;
  final int activeExerciseIndex;
  final Map<String, List<WorkoutSetRecord>> setsByExercise;
  final bool isSessionActive;
  final bool isCompleted;
  final String activeBodyType;

  const WorkoutSessionState({
    this.routineDay,
    this.activeExerciseIndex = 0,
    this.setsByExercise = const {},
    this.isSessionActive = false,
    this.isCompleted = false,
    this.activeBodyType = 'mesomorph',
  });

  double get progressPercentage {
    int total = 0;
    int done = 0;
    for (final sets in setsByExercise.values) {
      total += sets.length;
      done += sets.where((s) => s.isCompleted).length;
    }
    return total > 0 ? (done / total) : 0.0;
  }

  WorkoutSessionState copyWith({
    WorkoutRoutineDay? routineDay,
    int? activeExerciseIndex,
    Map<String, List<WorkoutSetRecord>>? setsByExercise,
    bool? isSessionActive,
    bool? isCompleted,
    String? activeBodyType,
  }) {
    return WorkoutSessionState(
      routineDay: routineDay ?? this.routineDay,
      activeExerciseIndex: activeExerciseIndex ?? this.activeExerciseIndex,
      setsByExercise: setsByExercise ?? this.setsByExercise,
      isSessionActive: isSessionActive ?? this.isSessionActive,
      isCompleted: isCompleted ?? this.isCompleted,
      activeBodyType: activeBodyType ?? this.activeBodyType,
    );
  }
}

final workoutNotifierProvider = NotifierProvider<WorkoutNotifier, WorkoutSessionState>(WorkoutNotifier.new);

class WorkoutNotifier extends Notifier<WorkoutSessionState> {
  late WorkoutRepository _repo;

  @override
  WorkoutSessionState build() {
    _repo = ref.read(workoutRepositoryProvider);
    final initialRoutine = _repo.getDefaultRoutineSync(dayNumber: 1, bodyType: 'mesomorph');
    final map = _buildSetsMap(initialRoutine);

    return WorkoutSessionState(
      routineDay: initialRoutine,
      activeExerciseIndex: 0,
      setsByExercise: map,
      activeBodyType: 'mesomorph',
    );
  }

  Map<String, List<WorkoutSetRecord>> _buildSetsMap(WorkoutRoutineDay routine) {
    final map = <String, List<WorkoutSetRecord>>{};
    for (final de in routine.exercises) {
      map[de.id] = List.generate(
        de.targetSets,
        (i) => WorkoutSetRecord(
          setNumber: i + 1,
          targetReps: int.tryParse(de.targetRepsRange.split('-').first) ?? 10,
          actualReps: int.tryParse(de.targetRepsRange.split('-').first) ?? 10,
          weightKg: 20.0 + (i * 2.5),
        ),
      );
    }
    return map;
  }

  Future<void> loadTodayRoutine({int day = 1, String? bodyType}) async {
    final type = bodyType ?? state.activeBodyType;
    final routine = await _repo.getTodayRoutine(dayNumber: day, bodyType: type);
    final map = _buildSetsMap(routine);

    state = WorkoutSessionState(
      routineDay: routine,
      activeExerciseIndex: 0,
      setsByExercise: map,
      activeBodyType: type,
    );
  }

  void startWorkout() {
    HapticFeedback.selectionClick();
    state = state.copyWith(isSessionActive: true);
  }

  void selectExercise(int index) {
    HapticFeedback.selectionClick();
    state = state.copyWith(activeExerciseIndex: index);
  }

  void toggleSet(String exerciseDayId, int setIndex) {
    final currentSets = List<WorkoutSetRecord>.from(state.setsByExercise[exerciseDayId] ?? []);
    if (setIndex >= currentSets.length) return;

    final targetSet = currentSets[setIndex];
    final updatedCompleted = !targetSet.isCompleted;

    currentSets[setIndex] = targetSet.copyWith(isCompleted: updatedCompleted);

    final newMap = Map<String, List<WorkoutSetRecord>>.from(state.setsByExercise);
    newMap[exerciseDayId] = currentSets;

    state = state.copyWith(setsByExercise: newMap);

    if (updatedCompleted) {
      HapticFeedback.mediumImpact(); // Satisfying dopamine loop feedback
      final exercise = state.routineDay?.exercises.firstWhere((e) => e.id == exerciseDayId);
      ref.read(restTimerProvider.notifier).startTimer(seconds: exercise?.restSeconds ?? 60);
    }
  }

  void updateSetWeight(String exerciseDayId, int setIndex, double weight) {
    final currentSets = List<WorkoutSetRecord>.from(state.setsByExercise[exerciseDayId] ?? []);
    if (setIndex < currentSets.length) {
      currentSets[setIndex] = currentSets[setIndex].copyWith(weightKg: weight);
      final newMap = Map<String, List<WorkoutSetRecord>>.from(state.setsByExercise);
      newMap[exerciseDayId] = currentSets;
      state = state.copyWith(setsByExercise: newMap);
    }
  }

  void updateSetReps(String exerciseDayId, int setIndex, int reps) {
    final currentSets = List<WorkoutSetRecord>.from(state.setsByExercise[exerciseDayId] ?? []);
    if (setIndex < currentSets.length) {
      currentSets[setIndex] = currentSets[setIndex].copyWith(actualReps: reps);
      final newMap = Map<String, List<WorkoutSetRecord>>.from(state.setsByExercise);
      newMap[exerciseDayId] = currentSets;
      state = state.copyWith(setsByExercise: newMap);
    }
  }

  void finishWorkout() {
    HapticFeedback.heavyImpact();
    state = state.copyWith(isCompleted: true, isSessionActive: false);
  }
}
