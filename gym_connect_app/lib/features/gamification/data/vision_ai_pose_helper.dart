import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'joint_angle_calculator.dart';
import 'rep_counter_state_machine.dart';

class VisionAiPoseHelper {
  static InputImage? buildInputImage(CameraImage image, CameraDescription camera) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
          (Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888);

      if (image.planes.isEmpty) return null;

      final Uint8List bytes;
      if (image.planes.length == 1) {
        bytes = image.planes.first.bytes;
      } else {
        final allBytes = WriteBuffer();
        for (final plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static double extractAngle(Pose pose, ExerciseMovementType movementType) {
    switch (movementType) {
      case ExerciseMovementType.squat:
        final lA = pose.landmarks[PoseLandmarkType.leftHip];
        final lB = pose.landmarks[PoseLandmarkType.leftKnee];
        final lC = pose.landmarks[PoseLandmarkType.leftAnkle];
        if (lA != null && lB != null && lC != null && lB.likelihood > 0.35) {
          return JointAngleCalculator.calculateAngle(
            PosePoint(x: lA.x, y: lA.y),
            PosePoint(x: lB.x, y: lB.y),
            PosePoint(x: lC.x, y: lC.y),
          );
        }
        final rA = pose.landmarks[PoseLandmarkType.rightHip];
        final rB = pose.landmarks[PoseLandmarkType.rightKnee];
        final rC = pose.landmarks[PoseLandmarkType.rightAnkle];
        if (rA != null && rB != null && rC != null && rB.likelihood > 0.35) {
          return JointAngleCalculator.calculateAngle(
            PosePoint(x: rA.x, y: rA.y),
            PosePoint(x: rB.x, y: rB.y),
            PosePoint(x: rC.x, y: rC.y),
          );
        }
        break;

      case ExerciseMovementType.pushup:
      case ExerciseMovementType.bicepCurl:
      case ExerciseMovementType.pullup:
      case ExerciseMovementType.generic:
        final lA = pose.landmarks[PoseLandmarkType.leftShoulder];
        final lB = pose.landmarks[PoseLandmarkType.leftElbow];
        final lC = pose.landmarks[PoseLandmarkType.leftWrist];
        if (lA != null && lB != null && lC != null && lB.likelihood > 0.35) {
          return JointAngleCalculator.calculateAngle(
            PosePoint(x: lA.x, y: lA.y),
            PosePoint(x: lB.x, y: lB.y),
            PosePoint(x: lC.x, y: lC.y),
          );
        }
        final rA = pose.landmarks[PoseLandmarkType.rightShoulder];
        final rB = pose.landmarks[PoseLandmarkType.rightElbow];
        final rC = pose.landmarks[PoseLandmarkType.rightWrist];
        if (rA != null && rB != null && rC != null && rB.likelihood > 0.35) {
          return JointAngleCalculator.calculateAngle(
            PosePoint(x: rA.x, y: rA.y),
            PosePoint(x: rB.x, y: rB.y),
            PosePoint(x: rC.x, y: rC.y),
          );
        }
        break;
    }
    return 180.0;
  }
}
