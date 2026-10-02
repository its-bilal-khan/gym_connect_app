import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_connect_app/features/gamification/data/rep_counter_state_machine.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/vision_ai_config_provider.dart';
import 'package:gym_connect_app/features/gamification/presentation/screens/vision_ai_live_trainer_screen.dart';
import '../../domain/models/workout_models.dart';
import '../providers/workout_notifier.dart';
import 'ai_trainer_entry_button.dart';
import 'exercise_pip_player.dart';

class WorkoutMediaViewport extends ConsumerWidget {
  final Exercise exercise;
  final int targetReps;
  final int currentSet;
  final int totalSets;
  final void Function(int newRepCount)? onRepCountChanged;

  const WorkoutMediaViewport({
    super.key,
    required this.exercise,
    this.targetReps = 12,
    this.currentSet = 1,
    this.totalSets = 3,
    this.onRepCountChanged,
  });

  ExerciseMovementType _resolveMovementType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('squat') || lower.contains('leg press') || lower.contains('lunge')) {
      return ExerciseMovementType.squat;
    }
    if (lower.contains('pushup') || lower.contains('push up') || lower.contains('bench') || lower.contains('chest press')) {
      return ExerciseMovementType.pushup;
    }
    if (lower.contains('curl') || lower.contains('bicep')) {
      return ExerciseMovementType.bicepCurl;
    }
    if (lower.contains('pullup') || lower.contains('pull up') || lower.contains('lat pulldown')) {
      return ExerciseMovementType.pullup;
    }
    return ExerciseMovementType.generic;
  }

  Future<void> _openLiveTrainer(BuildContext context, WidgetRef ref) async {
    final reps = await VisionAiLiveTrainerScreen.show(
      context,
      movementType: _resolveMovementType(exercise.name),
      targetReps: targetReps,
      currentSet: currentSet,
      totalSets: totalSets,
      exerciseName: exercise.name,
      placement: exercise.optimalCameraPlacement,
      onRepCountChanged: onRepCountChanged,
    );
    if (reps != null && reps > 0) {
      ref.read(workoutNotifierProvider.notifier).setRecordedMicroClipPath(exercise.videoUrl);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(visionAiConfigProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExercisePipPlayer(exercise: exercise),
        if (config.isLiveTrainerEnabled) ...[
          const SizedBox(height: 10),
          Center(
            child: AiTrainerEntryButton(
              onPressed: () => _openLiveTrainer(context, ref),
            ),
          ),
        ],
      ],
    );
  }
}
