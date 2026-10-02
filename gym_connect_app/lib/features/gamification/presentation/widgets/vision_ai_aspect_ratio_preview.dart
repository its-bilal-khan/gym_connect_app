import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_painter.dart';

/// Renders CameraPreview and PosePainter in an undistorted, aspect-ratio-locked FittedBox.
class VisionAiAspectRatioPreview extends StatelessWidget {
  final CameraController controller;
  final Pose? pose;
  final Size? imageSize;
  final InputImageRotation rotation;
  final bool isBadPosture;
  final bool isFrontCamera;

  const VisionAiAspectRatioPreview({
    super.key,
    required this.controller,
    required this.pose,
    required this.imageSize,
    required this.rotation,
    required this.isBadPosture,
    required this.isFrontCamera,
  });

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    double cameraAspectRatio = controller.value.aspectRatio;
    if (previewSize != null && previewSize.height > 0) {
      final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
      final rawRatio = previewSize.width / previewSize.height;
      cameraAspectRatio = isPortrait ? (1 / rawRatio) : rawRatio;
    } else if (cameraAspectRatio > 1 && MediaQuery.of(context).orientation == Orientation.portrait) {
      cameraAspectRatio = 1 / cameraAspectRatio;
    }

    const previewW = 1000.0;
    final previewH = previewW / cameraAspectRatio;

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewW,
            height: previewH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                CustomPaint(
                  painter: PosePainter(
                    pose: pose,
                    imageSize: imageSize,
                    rotation: rotation,
                    isBadPosture: isBadPosture,
                    correctColor: Theme.of(context).colorScheme.primary,
                    wrongColor: Colors.redAccent,
                    isFrontCamera: isFrontCamera,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
