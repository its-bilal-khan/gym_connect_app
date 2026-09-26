import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    String userId = '';
    try {
      userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    } catch (_) {}

    return repo.fetchFitnessProfile(userId);
  }

  Future<void> updateBodyType(String bodyType, {String? goal}) async {
    final current = state.asData?.value ??
        UserFitnessProfile(
          userId: Supabase.instance.client.auth.currentUser?.id ?? '',
          bodyType: 'mesomorph',
        );

    final updated = current.copyWith(
      bodyType: bodyType,
      fitnessGoal: goal ?? current.fitnessGoal,
      updatedAt: DateTime.now(),
    );

    // Optimistically update Riverpod state so UI responds with zero lag
    state = AsyncData(updated);

    // Persist to Supabase and FlutterSecureStorage
    final repo = ref.read(fitnessProfileRepositoryProvider);
    await repo.saveFitnessProfile(updated);

    // Automatically trigger workout engine to reload today's routine matching the new body type
    await ref.read(workoutNotifierProvider.notifier).loadTodayRoutine(
      day: ref.read(workoutNotifierProvider).routineDay?.dayNumber ?? 1,
      bodyType: bodyType,
    );
  }
}
