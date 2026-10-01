import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose? pose;
  final Size? imageSize;
  final bool isBadPosture;
  final Color correctColor;
  final Color wrongColor;
  final bool isFrontCamera;

  const PosePainter({
    required this.pose,
    this.imageSize,
    this.isBadPosture = false,
    this.correctColor = const Color(0xFFCCFF00),
    this.wrongColor = Colors.redAccent,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    final activeColor = isBadPosture ? wrongColor : correctColor;

    final linePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final jointOutline = Paint()
      ..color = activeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset? getOffset(PoseLandmarkType type) {
      final landmark = pose!.landmarks[type];
      if (landmark == null || landmark.likelihood < 0.45) return null;

      double x = landmark.x;
      double y = landmark.y;

      if (imageSize != null && imageSize!.width > 0 && imageSize!.height > 0) {
        final scaleX = size.width / imageSize!.width;
        final scaleY = size.height / imageSize!.height;
        x = isFrontCamera ? size.width - (x * scaleX) : (x * scaleX);
        y = y * scaleY;
      }
      return Offset(x, y);
    }

    void drawBone(PoseLandmarkType a, PoseLandmarkType b) {
      final pA = getOffset(a);
      final pB = getOffset(b);
      if (pA != null && pB != null) {
        canvas.drawLine(pA, pB, linePaint);
      }
    }

    void drawJoint(PoseLandmarkType type) {
      final p = getOffset(type);
      if (p != null) {
        canvas.drawCircle(p, 5.0, jointPaint);
        canvas.drawCircle(p, 6.5, jointOutline);
      }
    }

    // Spine & Torso
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawBone(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawBone(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

    // Arms
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawBone(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    drawBone(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawBone(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // Legs
    drawBone(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawBone(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    drawBone(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawBone(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // Joints
    for (final type in [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ]) {
      drawJoint(type);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.isBadPosture != isBadPosture ||
        oldDelegate.correctColor != correctColor ||
        oldDelegate.wrongColor != wrongColor;
  }
}
