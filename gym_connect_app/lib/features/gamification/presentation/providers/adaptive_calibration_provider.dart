import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/gamification_repository.dart';

class AdaptiveCalibrationState {
  final int currentStepTarget;
  final int baseStepTarget;
  final int consecutiveMisses;
  final bool isCalibrationRecommended;
  final int recommendedStepTarget;
  final bool isCalibrating;

  const AdaptiveCalibrationState({
    this.currentStepTarget = 10000,
    this.baseStepTarget = 10000,
    this.consecutiveMisses = 0,
    this.isCalibrationRecommended = false,
    this.recommendedStepTarget = 6000,
    this.isCalibrating = false,
  });

  AdaptiveCalibrationState copyWith({
    int? currentStepTarget,
    int? baseStepTarget,
    int? consecutiveMisses,
    bool? isCalibrationRecommended,
    int? recommendedStepTarget,
    bool? isCalibrating,
  }) {
    return AdaptiveCalibrationState(
      currentStepTarget: currentStepTarget ?? this.currentStepTarget,
      baseStepTarget: baseStepTarget ?? this.baseStepTarget,
      consecutiveMisses: consecutiveMisses ?? this.consecutiveMisses,
      isCalibrationRecommended: isCalibrationRecommended ?? this.isCalibrationRecommended,
      recommendedStepTarget: recommendedStepTarget ?? this.recommendedStepTarget,
      isCalibrating: isCalibrating ?? this.isCalibrating,
    );
  }
}

final adaptiveCalibrationProvider =
    NotifierProvider<AdaptiveCalibrationNotifier, AdaptiveCalibrationState>(
        AdaptiveCalibrationNotifier.new);

class AdaptiveCalibrationNotifier extends Notifier<AdaptiveCalibrationState> {
  late final GamificationRepository _repository;

  @override
  AdaptiveCalibrationState build() {
    _repository = ref.watch(gamificationRepositoryProvider);
    Future.microtask(() => checkCalibrationStatus());
    return const AdaptiveCalibrationState();
  }

  Future<void> checkCalibrationStatus() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await client
          .from('user_fitness_profiles')
          .select('current_step_target, base_step_target, consecutive_target_misses')
          .eq('user_id', userId)
          .maybeSingle();

      if (res != null) {
        final current = (res['current_step_target'] as num?)?.toInt() ?? 10000;
        final base = (res['base_step_target'] as num?)?.toInt() ?? 10000;
        final misses = (res['consecutive_target_misses'] as num?)?.toInt() ?? 0;
        final recommended = (current - 2000).clamp(5000, 20000);

        state = AdaptiveCalibrationState(
          currentStepTarget: current,
          baseStepTarget: base,
          consecutiveMisses: misses,
          isCalibrationRecommended: misses >= 3,
          recommendedStepTarget: recommended,
        );
      }
    } catch (_) {}
  }

  Future<void> acceptCalibrationTarget(int target) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isCalibrating: true);
    try {
      await _repository.autoCalibrateStepTarget(userId: userId, newTarget: target);
      state = state.copyWith(
        currentStepTarget: target,
        consecutiveMisses: 0,
        isCalibrationRecommended: false,
        isCalibrating: false,
      );
    } catch (_) {
      state = state.copyWith(isCalibrating: false);
    }
  }
}
