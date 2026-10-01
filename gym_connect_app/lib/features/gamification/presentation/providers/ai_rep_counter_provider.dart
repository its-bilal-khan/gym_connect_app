import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/rep_counter_state_machine.dart';
import 'vision_ai_config_provider.dart';

class AiRepCounterState {
  final ExerciseMovementType movementType;
  final int targetReps;
  final int completedReps;
  final double currentAngle;
  final RepStage stage;
  final String statusText;
  final bool isCameraActive;
  final bool isRecordingMicroClip;
  final int clipRecordedSeconds;
  final bool isTargetReached;

  const AiRepCounterState({
    this.movementType = ExerciseMovementType.squat,
    this.targetReps = 12,
    this.completedReps = 0,
    this.currentAngle = 180.0,
    this.stage = RepStage.ready,
    this.statusText = 'Ready',
    this.isCameraActive = false,
    this.isRecordingMicroClip = false,
    this.clipRecordedSeconds = 0,
    this.isTargetReached = false,
  });

  AiRepCounterState copyWith({
    ExerciseMovementType? movementType,
    int? targetReps,
    int? completedReps,
    double? currentAngle,
    RepStage? stage,
    String? statusText,
    bool? isCameraActive,
    bool? isRecordingMicroClip,
    int? clipRecordedSeconds,
    bool? isTargetReached,
  }) {
    return AiRepCounterState(
      movementType: movementType ?? this.movementType,
      targetReps: targetReps ?? this.targetReps,
      completedReps: completedReps ?? this.completedReps,
      currentAngle: currentAngle ?? this.currentAngle,
      stage: stage ?? this.stage,
      statusText: statusText ?? this.statusText,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      isRecordingMicroClip: isRecordingMicroClip ?? this.isRecordingMicroClip,
      clipRecordedSeconds: clipRecordedSeconds ?? this.clipRecordedSeconds,
      isTargetReached: isTargetReached ?? this.isTargetReached,
    );
  }
}

final aiRepCounterProvider =
    NotifierProvider<AiRepCounterNotifier, AiRepCounterState>(AiRepCounterNotifier.new);

class AiRepCounterNotifier extends Notifier<AiRepCounterState> {
  late RepCounterStateMachine _stateMachine;

  @override
  AiRepCounterState build() {
    final config = ref.watch(visionAiConfigProvider);
    _stateMachine = RepCounterStateMachine(
      movementType: ExerciseMovementType.squat,
      targetReps: 12,
      config: config,
      onRepCompleted: _onRepCompleted,
    );
    return const AiRepCounterState();
  }

  void configure({required ExerciseMovementType type, required int targetReps}) {
    final config = ref.read(visionAiConfigProvider);
    _stateMachine = RepCounterStateMachine(
      movementType: type,
      targetReps: targetReps,
      config: config,
      onRepCompleted: _onRepCompleted,
    );
    state = state.copyWith(
      movementType: type,
      targetReps: targetReps,
      completedReps: 0,
      isTargetReached: false,
      statusText: 'Position Camera & Begin',
    );
  }

  void processInstantAngle(double angle) {
    final result = _stateMachine.processAngle(angle);
    state = state.copyWith(
      currentAngle: angle,
      completedReps: result.repCount,
      stage: result.stage,
      statusText: result.statusText,
      isTargetReached: _stateMachine.isTargetReached,
    );
  }

  void _onRepCompleted(int newCount) {
    if (!state.isRecordingMicroClip && newCount == 1) {
      startMicroClipRecording();
    }
  }

  void startCamera() {
    state = state.copyWith(isCameraActive: true);
  }

  void stopCamera() {
    state = state.copyWith(isCameraActive: false, isRecordingMicroClip: false);
  }

  void startMicroClipRecording() {
    state = state.copyWith(isRecordingMicroClip: true, clipRecordedSeconds: 0);
  }

  void incrementClipSeconds() {
    final config = ref.read(visionAiConfigProvider);
    final secs = state.clipRecordedSeconds + 1;
    if (secs >= config.microClipDurationSec) {
      state = state.copyWith(isRecordingMicroClip: false, clipRecordedSeconds: secs);
    } else {
      state = state.copyWith(clipRecordedSeconds: secs);
    }
  }

  void reset() {
    _stateMachine.reset();
    state = state.copyWith(
      completedReps: 0,
      currentAngle: 180.0,
      stage: RepStage.ready,
      statusText: 'Ready',
      isTargetReached: false,
      isRecordingMicroClip: false,
    );
  }
}
