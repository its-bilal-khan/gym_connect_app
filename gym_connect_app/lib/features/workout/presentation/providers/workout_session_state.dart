import '../../domain/models/workout_models.dart';

class WorkoutSessionState {
  final WorkoutRoutineDay? routineDay;
  final int activeExerciseIndex;
  final Map<String, List<WorkoutSetRecord>> setsByExercise;
  final bool isSessionActive;
  final bool isCompleted;
  final String activeBodyType;
  final String? recordedMicroClipPath;

  const WorkoutSessionState({
    this.routineDay,
    this.activeExerciseIndex = 0,
    this.setsByExercise = const {},
    this.isSessionActive = false,
    this.isCompleted = false,
    this.activeBodyType = 'mesomorph',
    this.recordedMicroClipPath,
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
    String? recordedMicroClipPath,
  }) {
    return WorkoutSessionState(
      routineDay: routineDay ?? this.routineDay,
      activeExerciseIndex: activeExerciseIndex ?? this.activeExerciseIndex,
      setsByExercise: setsByExercise ?? this.setsByExercise,
      isSessionActive: isSessionActive ?? this.isSessionActive,
      isCompleted: isCompleted ?? this.isCompleted,
      activeBodyType: activeBodyType ?? this.activeBodyType,
      recordedMicroClipPath: recordedMicroClipPath ?? this.recordedMicroClipPath,
    );
  }
}
