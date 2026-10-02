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
  final String? missedRepReason;

  const RepDetectionResult({
    required this.repCount,
    required this.stage,
    required this.isNewRep,
    required this.currentAngle,
    required this.statusText,
    this.isBadPosture = false,
    this.feedbackMessage,
    this.missedRepReason,
  });
}
