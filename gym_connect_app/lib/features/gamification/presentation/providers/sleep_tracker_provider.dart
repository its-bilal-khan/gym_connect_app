import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sleep_tracker_service.dart';
import 'daily_gamification_provider.dart';

class SleepTrackerState {
  final double hoursLogged;
  final int asleepMinutes;
  final SleepSource source;
  final int pointsAwarded;
  final bool isSensorVerified;
  final bool isSyncing;
  final String? error;

  const SleepTrackerState({
    this.hoursLogged = 0.0,
    this.asleepMinutes = 0,
    this.source = SleepSource.none,
    this.pointsAwarded = 0,
    this.isSensorVerified = false,
    this.isSyncing = false,
    this.error,
  });

  SleepTrackerState copyWith({
    double? hoursLogged,
    int? asleepMinutes,
    SleepSource? source,
    int? pointsAwarded,
    bool? isSensorVerified,
    bool? isSyncing,
    String? error,
  }) {
    return SleepTrackerState(
      hoursLogged: hoursLogged ?? this.hoursLogged,
      asleepMinutes: asleepMinutes ?? this.asleepMinutes,
      source: source ?? this.source,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      isSensorVerified: isSensorVerified ?? this.isSensorVerified,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
    );
  }
}

final sleepTrackerProvider =
    NotifierProvider<SleepTrackerNotifier, SleepTrackerState>(SleepTrackerNotifier.new);

class SleepTrackerNotifier extends Notifier<SleepTrackerState> {
  SleepTrackerService get _service => ref.read(sleepTrackerServiceProvider);

  @override
  SleepTrackerState build() {
    Future.microtask(() => _loadFromExistingLog());
    return const SleepTrackerState();
  }

  void _loadFromExistingLog() {
    final dailyState = ref.read(dailyGamificationProvider);
    final log = dailyState.todayLog;
    if (log != null && log.sleepLoggedHours > 0) {
      final src = log.sleepSource == 'healthkit'
          ? SleepSource.healthKit
          : (log.sleepSource == 'health_connect'
              ? SleepSource.healthConnect
              : (log.sleepSource == 'manual' ? SleepSource.manual : SleepSource.none));
      final pts = SleepDataResult.calculatePoints(log.sleepLoggedHours, src);
      state = SleepTrackerState(
        hoursLogged: log.sleepLoggedHours,
        asleepMinutes: log.sleepAsleepMinutes,
        source: src,
        pointsAwarded: pts,
        isSensorVerified: src == SleepSource.healthKit || src == SleepSource.healthConnect,
      );
    }
  }

  Future<void> syncSensorSleep({String? tenantId}) async {
    state = state.copyWith(isSyncing: true, error: null);
    try {
      final result = await _service.fetchSensorSleep();
      state = SleepTrackerState(
        hoursLogged: result.hours,
        asleepMinutes: result.asleepMinutes,
        source: result.source,
        pointsAwarded: result.pointsAwarded,
        isSensorVerified: result.isSensorVerified,
        isSyncing: false,
      );

      if (tenantId != null && result.hours > 0) {
        await _saveSleepToBackend(tenantId, result);
      }
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString());
    }
  }

  Future<void> logManualSleep(double hours, {String? tenantId}) async {
    state = state.copyWith(isSyncing: true, error: null);
    try {
      final result = _service.logManualSleep(hours);
      state = SleepTrackerState(
        hoursLogged: result.hours,
        asleepMinutes: result.asleepMinutes,
        source: result.source,
        pointsAwarded: result.pointsAwarded,
        isSensorVerified: false,
        isSyncing: false,
      );

      if (tenantId != null) {
        await _saveSleepToBackend(tenantId, result);
      }
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString());
    }
  }

  Future<void> _saveSleepToBackend(String tenantId, SleepDataResult result) async {
    final srcStr = result.source == SleepSource.healthKit
        ? 'healthkit'
        : (result.source == SleepSource.healthConnect ? 'health_connect' : 'manual');

    await ref.read(dailyGamificationProvider.notifier).submitDailyTasks(
          tenantId: tenantId,
          sleepHours: result.hours,
          sleepSource: srcStr,
          sleepAsleepMinutes: result.asleepMinutes,
        );
  }
}
