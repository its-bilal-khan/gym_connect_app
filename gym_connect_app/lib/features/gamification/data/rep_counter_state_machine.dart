import '../domain/models/vision_ai_config.dart';
import 'movement_angle_evaluator.dart';
import 'rep_detection_models.dart';
export 'rep_detection_models.dart';

/// Biomechanics finite-state machine evaluating joint angles, rep completion, and missed reps.
class RepCounterStateMachine {
  ExerciseMovementType movementType;
  final int targetReps;
  final void Function(int newRepCount)? onRepCompleted;
  final void Function(String voicePrompt)? onVoiceFeedback;
  final void Function(String missedReason)? onRepMissed;
  VisionAiConfig config;

  int _repCount = 0;
  RepStage _stage = RepStage.ready;
  double _peakAngle = 0.0;
  DateTime? _badPostureStartedAt;
  bool _isBadPosture = false;
  String? _currentFeedback;

  bool _repAttemptInProgress = false;
  double _minAngleThisAttempt = 180.0;
  bool _badPostureInAttempt = false;
  String? _lastMissedReason;
  DateTime? _missedUntil;

  RepCounterStateMachine({
    this.movementType = ExerciseMovementType.squat,
    this.targetReps = 12,
    this.config = const VisionAiConfig(),
    this.onRepCompleted,
    this.onVoiceFeedback,
    this.onRepMissed,
  });

  void forceMovementType(ExerciseMovementType type) {
    movementType = type;
    reset();
  }

  int get repCount => _repCount;
  RepStage get stage => _stage;
  double get peakAngle => _peakAngle;
  bool get isTargetReached => _repCount >= targetReps;
  bool get isBadPosture => _isBadPosture;
  String? get currentFeedback => _currentFeedback;
  String? get activeMissedRepReason =>
      (_missedUntil != null && DateTime.now().isBefore(_missedUntil!)) ? _lastMissedReason : null;

  void updateConfig(VisionAiConfig newConfig) => config = newConfig;

  void reset() {
    _repCount = 0;
    _stage = RepStage.ready;
    _peakAngle = 0.0;
    _badPostureStartedAt = null;
    _isBadPosture = false;
    _currentFeedback = null;
    _repAttemptInProgress = false;
    _minAngleThisAttempt = 180.0;
    _badPostureInAttempt = false;
    _lastMissedReason = null;
    _missedUntil = null;
  }

  void _checkBadPostureDuration(bool inBadRange, String coachingPrompt) {
    if (inBadRange) {
      _badPostureStartedAt ??= DateTime.now();
      final elapsed = DateTime.now().difference(_badPostureStartedAt!).inMilliseconds;
      if (elapsed >= config.badPostureTriggerMs) {
        _isBadPosture = true;
        _badPostureInAttempt = true;
        _currentFeedback = coachingPrompt;
        onVoiceFeedback?.call(coachingPrompt);
      }
    } else {
      _badPostureStartedAt = null;
      _isBadPosture = false;
      _currentFeedback = null;
    }
  }

  void _evaluateMissedRep(double angle) {
    final target = (movementType == ExerciseMovementType.squat)
        ? config.squatDepthAngle
        : (movementType == ExerciseMovementType.pushup)
            ? config.pushupDepthAngle
            : (movementType == ExerciseMovementType.bicepCurl) ? 55.0 : 65.0;

    final isReturn = (movementType == ExerciseMovementType.bicepCurl) ? angle > 140.0 : angle > 160.0;
    final isInitiation = (movementType == ExerciseMovementType.bicepCurl) ? angle < 125.0 : angle < 145.0;

    if (isInitiation) {
      _repAttemptInProgress = true;
      if (angle < _minAngleThisAttempt) _minAngleThisAttempt = angle;
    } else if (_repAttemptInProgress && isReturn) {
      if (_minAngleThisAttempt > target) {
        final reason = _badPostureInAttempt
            ? 'Missed: Back not straight!'
            : (movementType == ExerciseMovementType.pushup) ? 'Missed: Chest to floor!' : 'Missed: Did not go low enough!';
        _lastMissedReason = reason;
        _missedUntil = DateTime.now().add(const Duration(seconds: 2));
        onRepMissed?.call(reason);
        onVoiceFeedback?.call(reason);
      }
      _repAttemptInProgress = false;
      _minAngleThisAttempt = 180.0;
      _badPostureInAttempt = false;
    }
  }

  RepDetectionResult processAngle(double angle) {
    _peakAngle = angle;
    final eval = MovementAngleEvaluator.evaluate(type: movementType, angle: angle, currentStage: _stage, config: config);
    _stage = eval.nextStage;
    _checkBadPostureDuration(eval.isInBadPostureRange, eval.coachingPrompt);
    _evaluateMissedRep(angle);

    bool isNewRep = false;
    if (eval.isRepCompleted) {
      _repCount++;
      isNewRep = true;
      _repAttemptInProgress = false;
      _minAngleThisAttempt = 180.0;
      _badPostureInAttempt = false;
      onRepCompleted?.call(_repCount);
    }

    return RepDetectionResult(
      repCount: _repCount,
      stage: _stage,
      isNewRep: isNewRep,
      currentAngle: angle,
      statusText: activeMissedRepReason ?? (_isBadPosture ? (_currentFeedback ?? 'Improve Form') : eval.statusText),
      isBadPosture: _isBadPosture,
      feedbackMessage: activeMissedRepReason ?? _currentFeedback,
      missedRepReason: activeMissedRepReason,
    );
  }
}
