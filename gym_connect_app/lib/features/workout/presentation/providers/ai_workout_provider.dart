import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/ai_workout_repository.dart';
import '../../domain/models/workout_models.dart';
import 'fitness_profile_provider.dart';
import 'workout_notifier.dart';

class AiWorkoutState {
  final bool isGenerating;
  final bool isSwapping;
  final AiWorkoutGenerationResult? lastResult;
  final WorkoutRoutine? activeRoutine;
  final List<ExerciseSwapCandidate> swapCandidates;
  final String? errorMessage;
  final String? successMessage;

  const AiWorkoutState({
    this.isGenerating = false,
    this.isSwapping = false,
    this.lastResult,
    this.activeRoutine,
    this.swapCandidates = const [],
    this.errorMessage,
    this.successMessage,
  });

  AiWorkoutState copyWith({
    bool? isGenerating,
    bool? isSwapping,
    AiWorkoutGenerationResult? lastResult,
    WorkoutRoutine? activeRoutine,
    List<ExerciseSwapCandidate>? swapCandidates,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AiWorkoutState(
      isGenerating: isGenerating ?? this.isGenerating,
      isSwapping: isSwapping ?? this.isSwapping,
      lastResult: lastResult ?? this.lastResult,
      activeRoutine: activeRoutine ?? this.activeRoutine,
      swapCandidates: swapCandidates ?? this.swapCandidates,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

final aiWorkoutProvider =
    NotifierProvider<AiWorkoutNotifier, AiWorkoutState>(AiWorkoutNotifier.new);

class AiWorkoutNotifier extends Notifier<AiWorkoutState> {
  @override
  AiWorkoutState build() {
    Future.microtask(() => loadActiveRoutine());
    return const AiWorkoutState();
  }

  AiWorkoutRepository get _repo => ref.read(aiWorkoutRepositoryProvider);

  /// Load member's active AI-generated routine from Supabase
  Future<void> loadActiveRoutine() async {
    String? userId;
    try {
      userId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {}

    if (userId == null || userId.isEmpty) return;

    final routine = await _repo.getActiveUserRoutine(userId);
    if (routine != null) {
      state = state.copyWith(activeRoutine: routine);
    }
  }

  /// Synthesize new 90-day AI routine with Silent BMI calculation & Track A/B routing
  Future<AiWorkoutGenerationResult> generateWorkout({
    String? goal,
    String? bodyType,
    double? currentWeightKg,
    double? heightCm,
    int? age,
    String? fitnessLevel,
    List<String> medicalInjuries = const [],
    String? overrideTrack,
    int durationDays = 90,
  }) async {
    String userId = '';
    String? tenantId;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      userId = user?.id ?? '';
      tenantId = user?.appMetadata['tenant_id'] as String?;
    } catch (_) {}

    if (userId.isEmpty) {
      const err = 'Cannot generate workout: User not authenticated';
      state = state.copyWith(errorMessage: err);
      return AiWorkoutGenerationResult.failure(err);
    }

    state = state.copyWith(
      isGenerating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final result = await _repo.generateWorkout(
        userId: userId,
        tenantId: tenantId,
        goal: goal,
        bodyType: bodyType,
        currentWeightKg: currentWeightKg,
        heightCm: heightCm,
        age: age,
        fitnessLevel: fitnessLevel,
        medicalInjuries: medicalInjuries,
        overrideTrack: overrideTrack,
        durationDays: durationDays,
      );

      if (result.success) {
        state = state.copyWith(
          isGenerating: false,
          lastResult: result,
          successMessage: 'Master 90-Day ${result.assignedTrack.toUpperCase()} protocol assigned successfully!',
        );

        // Reload active routine & today's routine in workout session
        await loadActiveRoutine();
        await ref.read(workoutNotifierProvider.notifier).loadTodayRoutine(
              day: 1,
              bodyType: bodyType,
            );
        // Refresh fitness profile in Riverpod
        ref.invalidate(fitnessProfileProvider);
      } else {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: result.error ?? 'Failed to generate AI workout',
        );
      }

      return result;
    } catch (e) {
      final msg = 'Workout generation error: $e';
      state = state.copyWith(
        isGenerating: false,
        errorMessage: msg,
      );
      return AiWorkoutGenerationResult.failure(msg);
    }
  }

  /// Query eligible swap candidates for 1-tap swap feature
  Future<void> loadSwapCandidates({
    String? targetMuscle,
    List<String> injuries = const [],
    String track = 'track_a',
  }) async {
    String? tenantId;
    try {
      tenantId = Supabase.instance.client.auth.currentUser?.appMetadata['tenant_id'] as String?;
    } catch (_) {}

    final candidates = await _repo.getEligibleSwapCandidates(
      tenantId: tenantId,
      medicalInjuries: injuries,
      assignedTrack: track,
      targetMuscle: targetMuscle,
    );

    state = state.copyWith(swapCandidates: candidates);
  }

  /// 1-Tap exercise swap (Phase 2 & Phase 4.3 zero-penalty execution)
  Future<bool> executeSwap({
    required String dayExerciseId,
    required String newExerciseId,
  }) async {
    state = state.copyWith(isSwapping: true, clearError: true);
    final success = await _repo.swapWorkoutDayExercise(
      dayExerciseId: dayExerciseId,
      newExerciseId: newExerciseId,
    );

    if (success) {
      state = state.copyWith(
        isSwapping: false,
        successMessage: 'Exercise swapped successfully! Zero penalty applied.',
      );
      // Reload today's routine in active session
      final currentDay = ref.read(workoutNotifierProvider).routineDay?.dayNumber ?? 1;
      await ref.read(workoutNotifierProvider.notifier).loadTodayRoutine(day: currentDay);
    } else {
      state = state.copyWith(
        isSwapping: false,
        errorMessage: 'Could not swap exercise. Please try again.',
      );
    }
    return success;
  }
}
