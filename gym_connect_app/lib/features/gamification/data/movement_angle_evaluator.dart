import '../domain/models/vision_ai_config.dart';
import 'rep_counter_state_machine.dart';

class MovementEvaluation {
  final RepStage nextStage;
  final bool isRepCompleted;
  final bool isInBadPostureRange;
  final String coachingPrompt;
  final String statusText;

  const MovementEvaluation({
    required this.nextStage,
    required this.isRepCompleted,
    required this.isInBadPostureRange,
    required this.coachingPrompt,
    required this.statusText,
  });
}

/// Helper calculating biomechanical angle thresholds using dynamic VisionAiConfig.
class MovementAngleEvaluator {
  static MovementEvaluation evaluate({
    required ExerciseMovementType type,
    required double angle,
    required RepStage currentStage,
    required VisionAiConfig config,
  }) {
    switch (type) {
      case ExerciseMovementType.squat:
        final badRange = (angle >= (config.squatDepthAngle + 5.0) && angle <= 135.0);
        if (angle < config.squatDepthAngle) {
          return MovementEvaluation(
            nextStage: RepStage.contracting,
            isRepCompleted: false,
            isInBadPostureRange: badRange,
            coachingPrompt: 'Go lower',
            statusText: 'Deep Squat ⬇️',
          );
        } else if (currentStage == RepStage.contracting && angle > 165.0) {
          return MovementEvaluation(
            nextStage: RepStage.ready,
            isRepCompleted: true,
            isInBadPostureRange: false,
            coachingPrompt: 'Go lower',
            statusText: 'Rep Complete! ⬆️',
          );
        }
        return MovementEvaluation(
          nextStage: currentStage,
          isRepCompleted: false,
          isInBadPostureRange: badRange,
          coachingPrompt: 'Go lower',
          statusText: currentStage == RepStage.contracting ? 'Rising...' : 'Stand Tall',
        );

      case ExerciseMovementType.pushup:
        final badRange = (angle >= (config.pushupDepthAngle + 5.0) && angle <= 135.0);
        if (angle < config.pushupDepthAngle) {
          return MovementEvaluation(
            nextStage: RepStage.contracting,
            isRepCompleted: false,
            isInBadPostureRange: badRange,
            coachingPrompt: 'Chest to floor',
            statusText: 'Chest Down ⬇️',
          );
        } else if (currentStage == RepStage.contracting && angle > 160.0) {
          return MovementEvaluation(
            nextStage: RepStage.ready,
            isRepCompleted: true,
            isInBadPostureRange: false,
            coachingPrompt: 'Chest to floor',
            statusText: 'Rep Complete! ⬆️',
          );
        }
        return MovementEvaluation(
          nextStage: currentStage,
          isRepCompleted: false,
          isInBadPostureRange: badRange,
          coachingPrompt: 'Chest to floor',
          statusText: currentStage == RepStage.contracting ? 'Pushing Up...' : 'Plank Position',
        );

      case ExerciseMovementType.bicepCurl:
        final badRange = (angle >= 55.0 && angle <= 115.0);
        if (angle < 45.0) {
          return MovementEvaluation(
            nextStage: RepStage.contracting,
            isRepCompleted: false,
            isInBadPostureRange: badRange,
            coachingPrompt: 'Full squeeze',
            statusText: 'Squeeze Peak ⬆️',
          );
        } else if (currentStage == RepStage.contracting && angle > 150.0) {
          return MovementEvaluation(
            nextStage: RepStage.ready,
            isRepCompleted: true,
            isInBadPostureRange: false,
            coachingPrompt: 'Full squeeze',
            statusText: 'Rep Complete! ⬇️',
          );
        }
        return MovementEvaluation(
          nextStage: currentStage,
          isRepCompleted: false,
          isInBadPostureRange: badRange,
          coachingPrompt: 'Full squeeze',
          statusText: currentStage == RepStage.contracting ? 'Lowering...' : 'Arms Extended',
        );

      case ExerciseMovementType.pullup:
        if (angle < 65.0) {
          return const MovementEvaluation(
            nextStage: RepStage.contracting,
            isRepCompleted: false,
            isInBadPostureRange: false,
            coachingPrompt: 'Chin over bar',
            statusText: 'Chin Over Bar ⬆️',
          );
        } else if (currentStage == RepStage.contracting && angle > 155.0) {
          return const MovementEvaluation(
            nextStage: RepStage.ready,
            isRepCompleted: true,
            isInBadPostureRange: false,
            coachingPrompt: 'Chin over bar',
            statusText: 'Rep Complete! ⬇️',
          );
        }
        return MovementEvaluation(
          nextStage: currentStage,
          isRepCompleted: false,
          isInBadPostureRange: false,
          coachingPrompt: 'Chin over bar',
          statusText: currentStage == RepStage.contracting ? 'Dropping...' : 'Dead Hang',
        );

      case ExerciseMovementType.generic:
        if (angle < 80.0) {
          return const MovementEvaluation(
            nextStage: RepStage.contracting,
            isRepCompleted: false,
            isInBadPostureRange: false,
            coachingPrompt: 'Keep form',
            statusText: 'Flexion',
          );
        } else if (currentStage == RepStage.contracting && angle > 150.0) {
          return const MovementEvaluation(
            nextStage: RepStage.ready,
            isRepCompleted: true,
            isInBadPostureRange: false,
            coachingPrompt: 'Keep form',
            statusText: 'Extension Complete',
          );
        }
        return MovementEvaluation(
          nextStage: currentStage,
          isRepCompleted: false,
          isInBadPostureRange: false,
          coachingPrompt: 'Keep form',
          statusText: 'Active',
        );
    }
  }
}
