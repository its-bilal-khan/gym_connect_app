import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class VisionAiCameraSession {
  List<CameraDescription> cameras = [];
  int cameraIndex = 0;
  CameraController? controller;
  bool isReady = false;
  bool isProcessing = false;

  Future<void> init(void Function(CameraImage) onFrame, VoidCallback onReady) async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) return;
      int frontIdx = cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      cameraIndex = frontIdx != -1 ? frontIdx : 0;
      await setup(cameraIndex, onFrame, onReady);
    } catch (_) {}
  }

  Future<void> setup(int targetIndex, void Function(CameraImage) onFrame, VoidCallback onReady) async {
    if (cameras.isEmpty) return;
    if (controller != null) {
      final old = controller!;
      controller = null;
      isReady = false;
      try { await old.stopImageStream(); } catch (_) {}
      await old.dispose();
    }

    cameraIndex = targetIndex % cameras.length;
    final newController = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await newController.initialize();
      controller = newController;
      isReady = true;
      onReady();
      newController.startImageStream(onFrame);
    } catch (e) {
      debugPrint('VisionAiCameraSession init error: $e');
    }
  }

  Future<void> toggle(void Function(CameraImage) onFrame, VoidCallback onReady) async {
    if (cameras.length < 2) return;
    await setup((cameraIndex + 1) % cameras.length, onFrame, onReady);
  }

  InputImageRotation get currentRotation {
    if (cameras.isEmpty) return InputImageRotation.rotation90deg;
    return InputImageRotationValue.fromRawValue(cameras[cameraIndex].sensorOrientation) ?? InputImageRotation.rotation90deg;
  }

  bool get isFrontCamera {
    if (cameras.isEmpty) return true;
    return cameras[cameraIndex].lensDirection == CameraLensDirection.front;
  }

  void dispose() {
    if (controller != null) {
      try {
        controller?.stopImageStream();
      } catch (_) {}
      controller?.dispose();
      controller = null;
    }
  }
}
