import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../workout/domain/models/workout_models.dart';
import '../../data/rep_counter_state_machine.dart';
import '../../data/tts_voice_coach_service.dart';
import '../../data/vision_ai_pose_helper.dart';
import '../providers/vision_ai_config_provider.dart';
import 'vision_ai_camera_preview_stack.dart';
import 'vision_ai_placeholder_card.dart';

class VisionAiCameraView extends ConsumerStatefulWidget {
  final ExerciseMovementType movementType;
  final int targetReps;
  final void Function(int newRepCount)? onRepCountChanged;
  final VoidCallback onStop;
  final OptimalCameraPlacement? placement;

  const VisionAiCameraView({
    super.key,
    this.movementType = ExerciseMovementType.squat,
    this.targetReps = 12,
    this.onRepCountChanged,
    required this.onStop,
    this.placement,
  });

  @override
  ConsumerState<VisionAiCameraView> createState() => _VisionAiCameraViewState();
}

class _VisionAiCameraViewState extends ConsumerState<VisionAiCameraView> {
  CameraController? _cameraController;
  late final PoseDetector _poseDetector;
  late final RepCounterStateMachine _stateMachine;
  late final TtsVoiceCoachService _ttsService;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isProcessing = false;
  bool _isCameraReady = false;
  Pose? _currentPose;
  Size? _imageSize;
  double _currentAngle = 180.0;
  String _statusText = 'Align in Frame';
  bool _isBadPosture = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(visionAiConfigProvider);
    _ttsService = TtsVoiceCoachService(ttsCooldownSeconds: config.ttsCooldownSeconds)..init();
    _stateMachine = RepCounterStateMachine(
      movementType: widget.movementType,
      targetReps: widget.targetReps,
      config: config,
      onRepCompleted: (reps) {
        widget.onRepCountChanged?.call(reps);
        _ttsService.speak('Good rep!');
      },
      onVoiceFeedback: (prompt) => _ttsService.speak(prompt),
    );
    _poseDetector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      _cameraIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      if (_cameraIndex == -1) _cameraIndex = 0;
      final controller = CameraController(_cameras[_cameraIndex], ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });
      controller.startImageStream(_processCameraFrame);
    } catch (_) {}
  }

  void _processCameraFrame(CameraImage image) async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;
    try {
      final inputImage = VisionAiPoseHelper.buildInputImage(image, _cameras[_cameraIndex]);
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);
        if (mounted && poses.isNotEmpty) {
          final angle = VisionAiPoseHelper.extractAngle(poses.first, widget.movementType);
          final res = _stateMachine.processAngle(angle);
          setState(() {
            _currentPose = poses.first;
            _imageSize = Size(image.width.toDouble(), image.height.toDouble());
            _currentAngle = res.currentAngle;
            _statusText = res.statusText;
            _isBadPosture = res.isBadPosture;
          });
        }
      }
    } catch (_) {
    } finally {
      _isProcessing = false;
    }
  }

  void _toggleCamera() async {
    if (_cameras.length < 2) return;
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(visionAiConfigProvider);
    _stateMachine.updateConfig(config);
    _ttsService.setCooldownSeconds(config.ttsCooldownSeconds);

    if (!_isCameraReady || _cameraController == null) {
      return const VisionAiPlaceholderCard();
    }

    final isFront = _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;

    return VisionAiCameraPreviewStack(
      controller: _cameraController!,
      pose: _currentPose,
      imageSize: _imageSize,
      isBadPosture: _isBadPosture,
      isFrontCamera: isFront,
      repCount: _stateMachine.repCount,
      targetReps: widget.targetReps,
      currentAngle: _currentAngle,
      statusText: _statusText,
      placement: widget.placement,
      onStop: widget.onStop,
      onToggleCamera: _toggleCamera,
    );
  }
}
