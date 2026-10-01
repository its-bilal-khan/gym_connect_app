import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../workout/domain/models/workout_models.dart';
import 'ai_camera_placement_prompt.dart';
import 'human_alignment_silhouette.dart';
import 'pose_painter.dart';
import 'vision_ai_hud_overlay.dart';

class VisionAiCameraPreviewStack extends StatefulWidget {
  final CameraController controller;
  final Pose? pose;
  final Size? imageSize;
  final bool isBadPosture;
  final bool isFrontCamera;
  final int repCount;
  final int targetReps;
  final double currentAngle;
  final String statusText;
  final VoidCallback onStop;
  final VoidCallback onToggleCamera;
  final OptimalCameraPlacement? placement;

  const VisionAiCameraPreviewStack({
    super.key,
    required this.controller,
    required this.pose,
    required this.imageSize,
    required this.isBadPosture,
    required this.isFrontCamera,
    required this.repCount,
    required this.targetReps,
    required this.currentAngle,
    required this.statusText,
    required this.onStop,
    required this.onToggleCamera,
    this.placement,
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

    return Container(
      height: 260,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(widget.controller),
          const HumanAlignmentSilhouette(),
          CustomPaint(
            painter: PosePainter(
              pose: widget.pose,
              imageSize: widget.imageSize,
              isBadPosture: widget.isBadPosture,
              correctColor: Theme.of(context).colorScheme.primary,
              wrongColor: Colors.redAccent,
              isFrontCamera: widget.isFrontCamera,
            ),
          ),
          VisionAiHudOverlay(
            repCount: widget.repCount,
            targetReps: widget.targetReps,
            currentAngle: widget.currentAngle,
            statusText: widget.statusText,
            isBadPosture: widget.isBadPosture,
            onStop: widget.onStop,
            onToggleCamera: widget.onToggleCamera,
          ),
          if (showPrompt)
            Positioned(
              top: 48,
              left: 0,
              right: 0,
              child: AiCameraPlacementPrompt(
                placement: widget.placement!,
                onDismiss: () => setState(() => _isPromptDismissed = true),
              ),
            ),
        ],
      ),
    );
  }
}
