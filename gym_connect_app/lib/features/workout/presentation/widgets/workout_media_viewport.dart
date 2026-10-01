import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_connect_app/features/gamification/data/rep_counter_state_machine.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/vision_ai_config_provider.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/vision_ai_camera_view.dart';
import '../../domain/models/workout_models.dart';
import 'ai_trainer_entry_button.dart';
import 'exercise_pip_player.dart';

class WorkoutMediaViewport extends ConsumerStatefulWidget {
  final Exercise exercise;
  final int targetReps;
  final void Function(int newRepCount)? onRepCountChanged;

  const WorkoutMediaViewport({
    super.key,
    required this.exercise,
    this.targetReps = 12,
    this.onRepCountChanged,
  });

  @override
  ConsumerState<WorkoutMediaViewport> createState() => _WorkoutMediaViewportState();
}

class _WorkoutMediaViewportState extends ConsumerState<WorkoutMediaViewport> {
  bool _isLiveAiActive = false;

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

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(visionAiConfigProvider);

    if (_isLiveAiActive && config.isLiveTrainerEnabled) {
      return VisionAiCameraView(
        movementType: _resolveMovementType(widget.exercise.name),
        targetReps: widget.targetReps,
        onRepCountChanged: widget.onRepCountChanged,
        placement: widget.exercise.optimalCameraPlacement,
        onStop: () => setState(() => _isLiveAiActive = false),
      );
    }

    return Stack(
      children: [
        ExercisePipPlayer(exercise: widget.exercise),
        if (config.isLiveTrainerEnabled)
          Positioned(
            top: 10,
            right: 10,
            child: AiTrainerEntryButton(
              onPressed: () => setState(() => _isLiveAiActive = true),
            ),
          ),
      ],
    );
  }
}
