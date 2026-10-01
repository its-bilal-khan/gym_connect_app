import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'joint_angle_calculator.dart';
import 'rep_counter_state_machine.dart';

class VisionAiPoseHelper {
  static InputImage? buildInputImage(CameraImage image, CameraDescription camera) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static double extractAngle(Pose pose, ExerciseMovementType movementType) {
    switch (movementType) {
      case ExerciseMovementType.squat:
        final a = pose.landmarks[PoseLandmarkType.leftHip];
        final b = pose.landmarks[PoseLandmarkType.leftKnee];
        final c = pose.landmarks[PoseLandmarkType.leftAnkle];
        if (a != null && b != null && c != null) {
          return JointAngleCalculator.calculateAngle(
            PosePoint(x: a.x, y: a.y),
            PosePoint(x: b.x, y: b.y),
            PosePoint(x: c.x, y: c.y),
          );
        }
        break;

      case ExerciseMovementType.pushup:
      case ExerciseMovementType.bicepCurl:
      case ExerciseMovementType.pullup:
      case ExerciseMovementType.generic:
        final a = pose.landmarks[PoseLandmarkType.leftShoulder];
        final b = pose.landmarks[PoseLandmarkType.leftElbow];
        final c = pose.landmarks[PoseLandmarkType.leftWrist];
        if (a != null && b != null && c != null) {
          return JointAngleCalculator.calculateAngle(
            PosePoint(x: a.x, y: a.y),
            PosePoint(x: b.x, y: b.y),
            PosePoint(x: c.x, y: c.y),
          );
        }
        break;
    }
    return 180.0;
  }
}
