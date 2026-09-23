import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/step_tracker_service.dart';

class StepTrackingData {
  final int steps;
  final double distanceKm;
  final int caloriesBurned;
  final int dailyGoal;
  final bool isTrackingLive;
  final bool isWaitingForSensor;
  final bool isPaused;
  final String? sensorError;
  final bool isHealthConnectMissing;
  final String? badgeText;

  const StepTrackingData({
    this.steps = 0,
    this.distanceKm = 0.0,
    this.caloriesBurned = 0,
    this.dailyGoal = 10000,
    this.isTrackingLive = false,
    this.isWaitingForSensor = true,
    this.isPaused = false,
    this.sensorError,
    this.isHealthConnectMissing = false,
    this.badgeText,
  });

  StepTrackingData copyWith({
    int? steps,
    double? distanceKm,
    int? caloriesBurned,
    int? dailyGoal,
    bool? isTrackingLive,
    bool? isWaitingForSensor,
    bool? isPaused,
    String? sensorError,
    bool? isHealthConnectMissing,
    String? badgeText,
  }) {
    return StepTrackingData(
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      isTrackingLive: isTrackingLive ?? this.isTrackingLive,
      isWaitingForSensor: isWaitingForSensor ?? this.isWaitingForSensor,
      isPaused: isPaused ?? this.isPaused,
      sensorError: sensorError ?? this.sensorError,
      isHealthConnectMissing: isHealthConnectMissing ?? this.isHealthConnectMissing,
      badgeText: badgeText ?? this.badgeText,
    );
  }

  double get goalProgress => dailyGoal > 0 ? (steps / dailyGoal).clamp(0.0, 1.0) : 0.0;
}

final stepTrackerProvider = NotifierProvider<StepTrackerNotifier, StepTrackingData>(StepTrackerNotifier.new);

class StepTrackerNotifier extends Notifier<StepTrackingData> with WidgetsBindingObserver {
  StreamSubscription<int>? _subscription;
  Timer? _pollingTimer;
  int _baselineSteps = 0;
  late final StepTrackerService _service;

  @override
  StepTrackingData build() {
    _service = ref.read(stepTrackerServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _subscription?.cancel();
      _pollingTimer?.cancel();
    });
    Future.microtask(() => initLiveTracking());
    return const StepTrackingData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App being closed or backgrounded: persist state and hardware baseline
      _service.saveBackgroundCheckpoint(this.state.steps, isPaused: this.state.isPaused).ignore();
    } else if (state == AppLifecycleState.resumed) {
      // App re-opened after being closed: reconcile steps walked in background immediately
      if (!this.state.isPaused) {
        refreshDailySteps();
      }
    }
  }

  Future<void> initLiveTracking() async {
    final authResult = await _service.requestHealthAuthorization();
    if (!ref.mounted) return;

    if (authResult == HealthAuthResult.healthConnectNotInstalled) {
      state = state.copyWith(
        isWaitingForSensor: false,
        isHealthConnectMissing: true,
        sensorError: 'Health Connect required. Tap to install.',
        badgeText: 'INSTALL HEALTH CONNECT',
      );
      return;
    }

    if (authResult == HealthAuthResult.denied) {
      _baselineSteps = await _service.loadTodayBaseline();
      if (!ref.mounted) return;
      state = state.copyWith(
        steps: _baselineSteps,
        distanceKm: _service.calculateDistance(_baselineSteps),
        caloriesBurned: _service.calculateCalories(_baselineSteps),
        isWaitingForSensor: false,
        sensorError: 'Health permission required. Tap to grant.',
        badgeText: 'PERMISSION NEEDED',
      );
      _startPolling();
      return;
    }

    final todaySteps = await _service.fetchDailySteps();
    if (!ref.mounted) return;
    final initialCount = todaySteps ?? await _service.loadTodayBaseline();
    if (!ref.mounted) return;

    _baselineSteps = initialCount;
    updateSteps(
      initialCount,
      isLive: !_service.isPaused,
      isWaiting: false,
      badge: _service.isPaused ? 'TRACKING PAUSED' : 'HEALTH CONNECT LIVE',
    );

    if (!_service.isPaused) {
      _startListeningToLiveStream();
      _startPolling();
    }
  }

  void _startListeningToLiveStream() {
    _subscription?.cancel();
    _subscription = _service.liveStepStream.listen(
      (steps) {
        if (!ref.mounted || state.isPaused) return;
        if (steps > _baselineSteps) {
          _baselineSteps = steps;
        }
        updateSteps(steps, isLive: true, isWaiting: false, badge: 'HEALTH CONNECT LIVE');
      },
      onError: (err) {
        if (!ref.mounted) return;
        state = state.copyWith(sensorError: err.toString());
      },
      cancelOnError: false,
    );
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await _pollSteps();
    });
  }

  Future<void> _pollSteps() async {
    if (!ref.mounted || state.isPaused) return;

    if (!state.isTrackingLive) {
      final hasPerm = await _service.hasStepPermission();
      if (!ref.mounted) return;
      if (hasPerm) {
        final fetched = await _service.fetchDailySteps();
        if (!ref.mounted) return;
        final steps = (fetched != null && fetched > 0) ? fetched : _baselineSteps;
        _baselineSteps = steps;
        updateSteps(steps, isLive: true, isWaiting: false, badge: 'HEALTH CONNECT LIVE');
      }
      return;
    }

    final steps = await _service.fetchDailySteps();
    if (!ref.mounted || steps == null || state.isPaused) return;
    if (steps > state.steps || !state.isTrackingLive) {
      _baselineSteps = steps;
      updateSteps(steps, isLive: true, isWaiting: false, badge: 'HEALTH CONNECT LIVE');
    }
  }

  Future<void> handleCardAction() async {
    if (state.isHealthConnectMissing) {
      await _service.installHealthConnect();
      return;
    }

    // Check if permission is already granted first
    final hasPerm = await _service.hasStepPermission();
    if (!ref.mounted) return;

    if (hasPerm) {
      final fetched = await _service.fetchDailySteps();
      if (!ref.mounted) return;
      final steps = (fetched != null && fetched > 0) ? fetched : (_baselineSteps > 0 ? _baselineSteps : state.steps);
      _baselineSteps = steps;
      updateSteps(steps, isLive: true, isWaiting: false, badge: 'HEALTH CONNECT LIVE');
      _startListeningToLiveStream();
      _startPolling();
      return;
    }

    // Re-trigger authorization request
    final authResult = await _service.requestHealthAuthorization();
    if (!ref.mounted) return;

    if (authResult == HealthAuthResult.authorized) {
      final fetched = await _service.fetchDailySteps();
      if (!ref.mounted) return;
      final steps = (fetched != null && fetched > 0) ? fetched : (_baselineSteps > 0 ? _baselineSteps : state.steps);
      _baselineSteps = steps;
      updateSteps(steps, isLive: true, isWaiting: false, badge: 'HEALTH CONNECT LIVE');
      _startListeningToLiveStream();
      _startPolling();
      return;
    }

    if (authResult == HealthAuthResult.healthConnectNotInstalled) {
      state = state.copyWith(
        isHealthConnectMissing: true,
        isWaitingForSensor: false,
        sensorError: 'Health Connect required. Tap to install.',
        badgeText: 'INSTALL HEALTH CONNECT',
      );
      await _service.installHealthConnect();
      return;
    }

    // Framework rejected or ignored request: open Settings directly
    state = state.copyWith(
      isWaitingForSensor: false,
      sensorError: 'System rejected prompt. Opening Settings to enable Steps...',
      badgeText: 'OPEN SETTINGS',
    );
    await _service.openHealthSettings();
    _startPolling();
  }

  Future<void> refreshDailySteps() async {
    final steps = await _service.fetchDailySteps();
    if (!ref.mounted || steps == null) return;
    if (steps > state.steps) {
      _baselineSteps = steps;
      updateSteps(steps, isLive: true, isWaiting: false, badge: 'HEALTH CONNECT LIVE');
    }
  }

  void addSteps(int count) {
    _baselineSteps += count;
    updateSteps(state.steps + count, isLive: state.isTrackingLive);
  }

  void updateSteps(
    int count, {
    bool isLive = false,
    bool isWaiting = false,
    String? badge,
  }) {
    final km = _service.calculateDistance(count);
    final kcal = _service.calculateCalories(count);

    state = StepTrackingData(
      steps: count,
      distanceKm: km,
      caloriesBurned: kcal,
      dailyGoal: state.dailyGoal,
      isTrackingLive: isLive,
      isWaitingForSensor: isWaiting,
      isPaused: state.isPaused,
      sensorError: null,
      isHealthConnectMissing: false,
      badgeText: badge ?? state.badgeText,
    );

    if (count > 0) {
      _service.saveLocalSteps(count).ignore();
    }
  }

  void pauseTracking() {
    _service.pauseTracking();
    _subscription?.cancel();
    _subscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    state = state.copyWith(
      isPaused: true,
      isTrackingLive: false,
      badgeText: 'TRACKING PAUSED',
    );
  }

  void resumeTracking() {
    _service.resumeTracking();
    state = state.copyWith(
      isPaused: false,
      isTrackingLive: true,
      badgeText: 'HEALTH CONNECT LIVE',
    );
    _startListeningToLiveStream();
    _startPolling();
  }

  void togglePauseResume() {
    if (state.isPaused) {
      resumeTracking();
    } else {
      pauseTracking();
    }
  }
}
