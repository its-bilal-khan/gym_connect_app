import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/gamification_repository.dart';
import '../../domain/models/models.dart';

class DailyGamificationState {
  final DailyGamificationLog? todayLog;
  final int currentStreak;
  final int monthlyPoints;
  final double streakMultiplier;
  final bool isEliteQualified;
  final bool isLoading;
  final String? error;

  const DailyGamificationState({
    this.todayLog,
    this.currentStreak = 0,
    this.monthlyPoints = 0,
    this.streakMultiplier = 1.0,
    this.isEliteQualified = false,
    this.isLoading = false,
    this.error,
  });

  DailyGamificationState copyWith({
    DailyGamificationLog? todayLog,
    int? currentStreak,
    int? monthlyPoints,
    double? streakMultiplier,
    bool? isEliteQualified,
    bool? isLoading,
    String? error,
  }) {
    return DailyGamificationState(
      todayLog: todayLog ?? this.todayLog,
      currentStreak: currentStreak ?? this.currentStreak,
      monthlyPoints: monthlyPoints ?? this.monthlyPoints,
      streakMultiplier: streakMultiplier ?? this.streakMultiplier,
      isEliteQualified: isEliteQualified ?? this.isEliteQualified,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final dailyGamificationProvider =
    NotifierProvider<DailyGamificationNotifier, DailyGamificationState>(
        DailyGamificationNotifier.new);

class DailyGamificationNotifier extends Notifier<DailyGamificationState> {
  late final GamificationRepository _repository;

  @override
  DailyGamificationState build() {
    _repository = ref.watch(gamificationRepositoryProvider);
    Future.microtask(() => loadTodayState());
    return const DailyGamificationState(isLoading: true);
  }

  Future<void> loadTodayState() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final log = await _repository.getDailyLog(userId);
      final stats = await _repository.getMemberGamificationStats(userId);

      state = state.copyWith(
        todayLog: log,
        currentStreak: (stats?['current_streak_days'] as num?)?.toInt() ?? 0,
        monthlyPoints: (stats?['monthly_points'] as num?)?.toInt() ?? 0,
        streakMultiplier: (stats?['streak_multiplier'] as num?)?.toDouble() ?? 1.0,
        isEliteQualified: stats?['is_elite_qualified'] as bool? ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> submitDailyTasks({
    required String tenantId,
    String? deviceId,
    int completedSets = 0,
    int assignedSets = 0,
    int stepActual = 0,
    int stepTarget = 10000,
    String stepSource = 'live_pedometer',
    String dietType = 'none',
    String? dietProofUrl,
    double sleepHours = 0.0,
    String sleepSource = 'none',
    int sleepAsleepMinutes = 0,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repository.submitDailyActivity(
        userId: userId,
        tenantId: tenantId,
        deviceId: deviceId,
        workoutAssignedSets: assignedSets,
        workoutCompletedSets: completedSets,
        stepActual: stepActual,
        stepTarget: stepTarget,
        stepSource: stepSource,
        dietLoggedType: dietType,
        dietProofUrl: dietProofUrl,
        sleepLoggedHours: sleepHours,
        sleepSource: sleepSource,
        sleepAsleepMinutes: sleepAsleepMinutes,
      );

      await loadTodayState();
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }
}
