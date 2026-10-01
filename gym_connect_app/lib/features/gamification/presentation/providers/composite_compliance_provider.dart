import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/gamification_repository.dart';
import 'daily_gamification_provider.dart';

class CompositeComplianceState {
  final double workoutPct;
  final double stepPct;
  final double dietPct;
  final double sleepPct;
  final double compositePct;
  final bool isGateVerified;
  final bool isStreakSaved;
  final int totalPointsToday;
  final double multiplier;
  final bool isLoading;

  const CompositeComplianceState({
    this.workoutPct = 0.0,
    this.stepPct = 0.0,
    this.dietPct = 0.0,
    this.sleepPct = 0.0,
    this.compositePct = 0.0,
    this.isGateVerified = false,
    this.isStreakSaved = false,
    this.totalPointsToday = 0,
    this.multiplier = 1.0,
    this.isLoading = false,
  });

  bool get isThresholdMet => compositePct >= 80.0;
  double get progressFraction => (compositePct / 100.0).clamp(0.0, 1.0);
}

final compositeComplianceProvider =
    NotifierProvider<CompositeComplianceNotifier, CompositeComplianceState>(
        CompositeComplianceNotifier.new);

class CompositeComplianceNotifier extends Notifier<CompositeComplianceState> {
  GamificationRepository get _repository => ref.read(gamificationRepositoryProvider);

  @override
  CompositeComplianceState build() {
    final dailyState = ref.watch(dailyGamificationProvider);
    return _computeState(dailyState);
  }

  CompositeComplianceState _computeState(DailyGamificationState dailyState) {
    final log = dailyState.todayLog;
    if (log == null) {
      return CompositeComplianceState(
        multiplier: dailyState.streakMultiplier,
        isLoading: dailyState.isLoading,
      );
    }

    final workoutPct = log.workoutCompletionPct.clamp(0.0, 100.0);
    final stepPct = log.stepCompletionPct.clamp(0.0, 100.0);

    double dietPct = 0.0;
    if (log.dietLoggedType == 'photo_proof') {
      dietPct = 100.0;
    } else if (log.dietLoggedType == 'self_check') {
      dietPct = 25.0;
    }

    double sleepPct = 0.0;
    if (log.sleepLoggedHours >= 7.0) {
      sleepPct = 100.0;
    } else if (log.sleepLoggedHours >= 5.0) {
      sleepPct = 70.0;
    } else if (log.sleepLoggedHours > 0.0) {
      sleepPct = 30.0;
    }

    final composite = (0.50 * workoutPct) + (0.25 * stepPct) + (0.15 * dietPct) + (0.10 * sleepPct);
    final isSaved = composite >= 80.0 && log.gateCheckinVerified;

    return CompositeComplianceState(
      workoutPct: workoutPct,
      stepPct: stepPct,
      dietPct: dietPct,
      sleepPct: sleepPct,
      compositePct: double.parse(composite.toStringAsFixed(1)),
      isGateVerified: log.gateCheckinVerified,
      isStreakSaved: isSaved,
      totalPointsToday: log.pointsAwarded,
      multiplier: dailyState.streakMultiplier,
      isLoading: dailyState.isLoading,
    );
  }

  Future<void> refreshGateAttendance(String tenantId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final isAttended = await _repository.checkGateAttendance(userId, tenantId);
      final isSaved = state.compositePct >= 80.0 && isAttended;
      state = CompositeComplianceState(
        workoutPct: state.workoutPct,
        stepPct: state.stepPct,
        dietPct: state.dietPct,
        sleepPct: state.sleepPct,
        compositePct: state.compositePct,
        isGateVerified: isAttended,
        isStreakSaved: isSaved,
        totalPointsToday: state.totalPointsToday,
        multiplier: state.multiplier,
        isLoading: false,
      );
    } catch (_) {}
  }
}
