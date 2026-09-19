import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  final int secondsRemaining;
  final int totalSeconds;
  final bool isRunning;
  final bool isFinished;

  const RestTimerState({
    this.secondsRemaining = 0,
    this.totalSeconds = 60,
    this.isRunning = false,
    this.isFinished = false,
  });

  double get progress => totalSeconds > 0 ? (secondsRemaining / totalSeconds) : 0.0;
}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(RestTimerNotifier.new);

class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _ticker;

  @override
  RestTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const RestTimerState();
  }

  void startTimer({int seconds = 60}) {
    _ticker?.cancel();
    HapticFeedback.selectionClick();
    state = RestTimerState(
      secondsRemaining: seconds,
      totalSeconds: seconds,
      isRunning: true,
      isFinished: false,
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining > 1) {
        state = RestTimerState(
          secondsRemaining: state.secondsRemaining - 1,
          totalSeconds: state.totalSeconds,
          isRunning: true,
          isFinished: false,
        );
      } else {
        _ticker?.cancel();
        HapticFeedback.heavyImpact(); // Critical trigger at zero
        state = RestTimerState(
          secondsRemaining: 0,
          totalSeconds: state.totalSeconds,
          isRunning: false,
          isFinished: true,
        );
      }
    });
  }

  void addSeconds(int seconds) {
    HapticFeedback.selectionClick();
    final updated = state.secondsRemaining + seconds;
    state = RestTimerState(
      secondsRemaining: updated,
      totalSeconds: state.totalSeconds + seconds,
      isRunning: state.isRunning,
      isFinished: false,
    );
  }

  void cancelTimer() {
    _ticker?.cancel();
    state = const RestTimerState();
  }
}
