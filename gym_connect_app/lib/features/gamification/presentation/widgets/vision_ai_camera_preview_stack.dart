import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../workout/domain/models/workout_models.dart';
import 'ai_camera_placement_prompt.dart';
import 'human_alignment_silhouette.dart';
import 'vision_ai_aspect_ratio_preview.dart';
import 'vision_ai_hud_overlay.dart';

class VisionAiCameraPreviewStack extends StatefulWidget {
  final CameraController controller;
  final Pose? pose;
  final Size? imageSize;
  final InputImageRotation rotation;
  final bool isBadPosture;
  final bool isFrontCamera;
  final int repCount;
  final int targetReps;
  final double currentAngle;
  final String statusText;
  final VoidCallback onStop;
  final VoidCallback onToggleCamera;
  final OptimalCameraPlacement? placement;
  final int currentSet;
  final int totalSets;
  final int elapsedSeconds;
  final String exerciseName;
  final bool isTestSquatsActive;
  final VoidCallback? onToggleTestSquats;
  final String? missedRepReason;
  final double? height;

  const VisionAiCameraPreviewStack({
    super.key,
    required this.controller,
    required this.pose,
    required this.imageSize,
    this.rotation = InputImageRotation.rotation90deg,
    required this.isBadPosture,
    required this.isFrontCamera,
    required this.repCount,
    required this.targetReps,
    required this.currentAngle,
    required this.statusText,
    required this.onStop,
    required this.onToggleCamera,
    this.placement,
    this.currentSet = 1,
    this.totalSets = 3,
    this.elapsedSeconds = 0,
    this.exerciseName = 'SQUAT',
    this.isTestSquatsActive = false,
    this.onToggleTestSquats,
    this.missedRepReason,
    this.height,
  });

  @override
  State<VisionAiCameraPreviewStack> createState() => _VisionAiCameraPreviewStackState();
}

class _VisionAiCameraPreviewStackState extends State<VisionAiCameraPreviewStack> {
  bool _isPromptDismissed = false;

  @override
  Widget build(BuildContext context) {
    final showPrompt = !_isPromptDismissed &&
        widget.placement != null &&
        widget.placement == OptimalCameraPlacement.machineHolder;

    final child = Stack(
      fit: StackFit.expand,
      children: [
        VisionAiAspectRatioPreview(
          controller: widget.controller,
          pose: widget.pose,
          imageSize: widget.imageSize,
          rotation: widget.rotation,
          isBadPosture: widget.isBadPosture,
          isFrontCamera: widget.isFrontCamera,
        ),
        const HumanAlignmentSilhouette(),
        VisionAiHudOverlay(
          repCount: widget.repCount,
          targetReps: widget.targetReps,
          currentAngle: widget.currentAngle,
          statusText: widget.statusText,
          isBadPosture: widget.isBadPosture,
          onStop: widget.onStop,
          onToggleCamera: widget.onToggleCamera,
          currentSet: widget.currentSet,
          totalSets: widget.totalSets,
          elapsedSeconds: widget.elapsedSeconds,
          exerciseName: widget.exerciseName,
          isTestSquatsActive: widget.isTestSquatsActive,
          onToggleTestSquats: widget.onToggleTestSquats,
          missedRepReason: widget.missedRepReason,
        ),
        if (showPrompt)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: AiCameraPlacementPrompt(
              placement: widget.placement!,
              onDismiss: () => setState(() => _isPromptDismissed = true),
            ),
          ),
      ],
    );

    if (widget.height != null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }

    return Container(color: Colors.black, child: child);
  }
}
