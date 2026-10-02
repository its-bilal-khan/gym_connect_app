import 'package:flutter/material.dart';
import '../../../workout/domain/models/workout_models.dart';
import '../../data/rep_counter_state_machine.dart';
import '../widgets/vision_ai_camera_view.dart';

class VisionAiLiveTrainerScreen extends StatefulWidget {
  final ExerciseMovementType movementType;
  final int targetReps;
  final int currentSet;
  final int totalSets;
  final String exerciseName;
  final OptimalCameraPlacement? placement;
  final void Function(int newRepCount)? onRepCountChanged;

  const VisionAiLiveTrainerScreen({
    super.key,
    required this.movementType,
    this.targetReps = 12,
    this.currentSet = 1,
    this.totalSets = 3,
    required this.exerciseName,
    this.placement,
    this.onRepCountChanged,
  });

  static Future<int?> show(
    BuildContext context, {
    required ExerciseMovementType movementType,
    int targetReps = 12,
    int currentSet = 1,
    int totalSets = 3,
    required String exerciseName,
    OptimalCameraPlacement? placement,
    void Function(int newRepCount)? onRepCountChanged,
  }) {
    return Navigator.of(context).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => VisionAiLiveTrainerScreen(
          movementType: movementType,
          targetReps: targetReps,
          currentSet: currentSet,
          totalSets: totalSets,
          exerciseName: exerciseName,
          placement: placement,
          onRepCountChanged: onRepCountChanged,
        ),
      ),
    );
  }

  @override
  State<VisionAiLiveTrainerScreen> createState() => _VisionAiLiveTrainerScreenState();
}

class _VisionAiLiveTrainerScreenState extends State<VisionAiLiveTrainerScreen> {
  int _lastRepCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: VisionAiCameraView(
        movementType: widget.movementType,
        targetReps: widget.targetReps,
        currentSet: widget.currentSet,
        totalSets: widget.totalSets,
        exerciseName: widget.exerciseName,
        placement: widget.placement,
        onRepCountChanged: (reps) {
          _lastRepCount = reps;
          widget.onRepCountChanged?.call(reps);
        },
        onStop: () => Navigator.of(context).pop(_lastRepCount),
      ),
    );
  }
}
