import '../domain/models/vision_ai_config.dart';
import 'movement_angle_evaluator.dart';

enum ExerciseMovementType { squat, pushup, bicepCurl, pullup, generic }

enum RepStage { ready, contracting, extended }

class RepDetectionResult {
  final int repCount;
  final RepStage stage;
  final bool isNewRep;
  final double currentAngle;
  final String statusText;
  final bool isBadPosture;
  final String? feedbackMessage;

  const RepDetectionResult({
    required this.repCount,
    required this.stage,
    required this.isNewRep,
    required this.currentAngle,
    required this.statusText,
    this.isBadPosture = false,
    this.feedbackMessage,
  });
}

/// Biomechanics finite-state machine evaluating joint angles for automated rep counting and posture coaching.
class RepCounterStateMachine {
  final ExerciseMovementType movementType;
  final int targetReps;
  final void Function(int newRepCount)? onRepCompleted;
  final void Function(String voicePrompt)? onVoiceFeedback;
  VisionAiConfig config;

  int _repCount = 0;
  RepStage _stage = RepStage.ready;
  double _peakAngle = 0.0;
  DateTime? _badPostureStartedAt;
  bool _isBadPosture = false;
  String? _currentFeedback;

  RepCounterStateMachine({
    this.movementType = ExerciseMovementType.squat,
    this.targetReps = 12,
    this.config = const VisionAiConfig(),
    this.onRepCompleted,
    this.onVoiceFeedback,
  });

  int get repCount => _repCount;
  RepStage get stage => _stage;
  double get peakAngle => _peakAngle;
  bool get isTargetReached => _repCount >= targetReps;
  bool get isBadPosture => _isBadPosture;
  String? get currentFeedback => _currentFeedback;

  void updateConfig(VisionAiConfig newConfig) {
    config = newConfig;
  }

  void reset() {
    _repCount = 0;
    _stage = RepStage.ready;
    _peakAngle = 0.0;
    _badPostureStartedAt = null;
    _isBadPosture = false;
    _currentFeedback = null;
  }

  void _checkBadPostureDuration(bool inBadRange, String coachingPrompt) {
    if (inBadRange) {
      _badPostureStartedAt ??= DateTime.now();
      final elapsed = DateTime.now().difference(_badPostureStartedAt!).inMilliseconds;
      if (elapsed >= config.badPostureTriggerMs) {
        _isBadPosture = true;
        _currentFeedback = coachingPrompt;
        onVoiceFeedback?.call(coachingPrompt);
      }
    } else {
      _badPostureStartedAt = null;
      _isBadPosture = false;
      _currentFeedback = null;
    }
  }

  /// Processes current instantaneous or smoothed joint angle using dynamic config thresholds.
  RepDetectionResult processAngle(double angle) {
    _peakAngle = angle;
    final eval = MovementAngleEvaluator.evaluate(
      type: movementType,
      angle: angle,
      currentStage: _stage,
      config: config,
    );

    _stage = eval.nextStage;
    _checkBadPostureDuration(eval.isInBadPostureRange, eval.coachingPrompt);

    bool isNewRep = false;
    if (eval.isRepCompleted) {
      _repCount++;
      isNewRep = true;
      onRepCompleted?.call(_repCount);
    }

    return RepDetectionResult(
      repCount: _repCount,
      stage: _stage,
      isNewRep: isNewRep,
      currentAngle: angle,
      statusText: _isBadPosture ? (_currentFeedback ?? 'Improve Form') : eval.statusText,
      isBadPosture: _isBadPosture,
      feedbackMessage: _currentFeedback,
    );
  }
}
