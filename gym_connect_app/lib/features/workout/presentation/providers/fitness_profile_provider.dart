import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../super_admin/data/system_feature_toggle_repository.dart';
import '../../data/ai_workout_repository.dart';
import '../../data/fitness_profile_repository.dart';
import '../../domain/models/fitness_profile_model.dart';
import 'workout_notifier.dart';

final fitnessProfileProvider = AsyncNotifierProvider<FitnessProfileNotifier, UserFitnessProfile>(
  FitnessProfileNotifier.new,
);

class FitnessProfileNotifier extends AsyncNotifier<UserFitnessProfile> {
  @override
  Future<UserFitnessProfile> build() async {
    final repo = ref.read(fitnessProfileRepositoryProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return repo.fetchFitnessProfile(userId);
  }

  Future<void> updateBodyType(String bodyType, {String? goal}) async {
    final current = state.asData?.value ?? UserFitnessProfile(userId: Supabase.instance.client.auth.currentUser?.id ?? '');
    final updated = current.copyWith(bodyType: bodyType, fitnessGoal: goal ?? current.fitnessGoal, updatedAt: DateTime.now());
    state = AsyncData(updated);
    await ref.read(fitnessProfileRepositoryProvider).saveFitnessProfile(updated);
    await ref.read(workoutNotifierProvider.notifier).loadTodayRoutine(
      day: ref.read(workoutNotifierProvider).routineDay?.dayNumber ?? 1,
      bodyType: bodyType,
    );
  }

  /// Step 4.1: Rapid setup with dynamic maxAllowedAiAge liability check and Track A/B routing
  Future<void> saveRapidOnboarding({
    required double weightKg,
    required String goal,
    required int age,
    int maxAllowedAiAge = 55,
  }) async {
    final int effectiveMaxAge = maxAllowedAiAge;
    final current = state.asData?.value ?? UserFitnessProfile(userId: Supabase.instance.client.auth.currentUser?.id ?? '');

    // Liability protection: Members >= maxAllowedAiAge are completely blocked from AI workouts
    if (age >= effectiveMaxAge) {
      final updated = current.copyWith(currentWeightKg: weightKg, age: age, fitnessGoal: goal, updatedAt: DateTime.now());
      state = AsyncData(updated);
      await ref.read(fitnessProfileRepositoryProvider).saveFitnessProfile(updated);
      return;
    }

    final assignedTrack = weightKg >= 90.0 ? 'track_b' : 'track_a';
    final targetBodyType = goal == 'lean_slim' ? 'ectomorph' : (goal == 'v_shape' ? 'v_shape' : 'heavyweight');
    final updated = current.copyWith(
      currentWeightKg: weightKg,
      age: age,
      fitnessGoal: goal,
      bodyType: targetBodyType,
      assignedWorkoutTrack: assignedTrack,
      profileCompleted: true,
      updatedAt: DateTime.now(),
    );

    state = AsyncData(updated);
    await ref.read(fitnessProfileRepositoryProvider).saveFitnessProfile(updated);

    try {
      await ref.read(aiWorkoutRepositoryProvider).generateWorkout(
        userId: updated.userId,
        bodyType: targetBodyType,
        age: age,
        currentWeightKg: weightKg,
        heightCm: updated.heightCm ?? 175.0,
      );
    } catch (_) {}

    await ref.read(workoutNotifierProvider.notifier).loadTodayRoutine(day: 1, bodyType: targetBodyType);
  }

  /// Step 4.2: Gamified 50-Points Profile Quest completion & injury screening
  Future<void> completeProfileQuest({
    required double heightCm,
    required List<String> injuries,
    double? chestCm,
    double? waistCm,
    double? armCm,
  }) async {
    final current = state.asData?.value ?? UserFitnessProfile(userId: Supabase.instance.client.auth.currentUser?.id ?? '');
    final updated = current.copyWith(heightCm: heightCm, medicalInjuries: injuries, profileCompleted: true, updatedAt: DateTime.now());

    state = AsyncData(updated);
    await ref.read(fitnessProfileRepositoryProvider).saveFitnessProfile(updated);

    try {
      final client = Supabase.instance.client;
      if (current.userId.isNotEmpty) {
        await client.rpc('rpc_submit_daily_activity', params: {
          'p_user_id': current.userId,
          'p_tenant_id': client.auth.currentUser?.userMetadata?['tenant_id'] ?? '00000000-0000-0000-0000-000000000000',
          'p_device_id': 'quest_bonus',
          'p_workout_assigned_sets': 0,
          'p_workout_completed_sets': 0,
          'p_step_target': 10000,
          'p_step_actual': 0,
        });
      }
    } catch (_) {}

    // Strict liability check: Only auto-generate workout if age is below maxAllowedAiAge
    final maxAge = ref.read(maxAllowedAiAgeProvider);
    if ((updated.age ?? 0) < maxAge) {
      try {
        await ref.read(aiWorkoutRepositoryProvider).generateWorkout(
          userId: updated.userId,
          bodyType: updated.bodyType,
          age: updated.age ?? 25,
          currentWeightKg: updated.currentWeightKg ?? 75.0,
          heightCm: heightCm,
          medicalInjuries: injuries,
        );
      } catch (_) {}
    }
  }
}
