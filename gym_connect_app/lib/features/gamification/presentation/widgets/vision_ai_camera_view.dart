import 'dart:async';
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
import 'vision_ai_camera_session.dart';
import 'vision_ai_placeholder_card.dart';

class VisionAiCameraView extends ConsumerStatefulWidget {
  final ExerciseMovementType movementType;
  final int targetReps;
  final void Function(int newRepCount)? onRepCountChanged;
  final VoidCallback onStop;
  final OptimalCameraPlacement? placement;
  final int currentSet;
  final int totalSets;
  final String exerciseName;
  final double? height;

  const VisionAiCameraView({
    super.key,
    this.movementType = ExerciseMovementType.squat,
    this.targetReps = 12,
    this.onRepCountChanged,
    required this.onStop,
    this.placement,
    this.currentSet = 1,
    this.totalSets = 3,
    this.exerciseName = 'SQUAT',
    this.height,
  });

  @override
  ConsumerState<VisionAiCameraView> createState() => _VisionAiCameraViewState();
}

class _VisionAiCameraViewState extends ConsumerState<VisionAiCameraView> {
  final _session = VisionAiCameraSession();
  late final PoseDetector _poseDetector;
  late final RepCounterStateMachine _stateMachine;
  late final TtsVoiceCoachService _ttsService;
  Pose? _currentPose;
  Size? _imageSize;
  double _currentAngle = 180.0;
  String _statusText = 'Align in Frame';
  bool _isBadPosture = false;
  String? _missedRepReason;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isTestSquatsActive = false;

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
        _ttsService.speak('Good rep!', force: true);
      },
      onVoiceFeedback: (prompt) => _ttsService.speak(prompt),
      onRepMissed: (reason) => _ttsService.speak(reason.replaceAll('Missed: ', ''), force: true),
    );
    _poseDetector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _elapsedSeconds++));
    _session.init(_processFrame, () => setState(() {}));
  }

  void _processFrame(CameraImage image) async {
    if (_session.isProcessing || !mounted || _session.cameras.isEmpty) return;
    _session.isProcessing = true;
    try {
      final inputImage = VisionAiPoseHelper.buildInputImage(image, _session.cameras[_session.cameraIndex]);
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);
        if (mounted && poses.isNotEmpty) {
          final angle = VisionAiPoseHelper.extractAngle(poses.first, _stateMachine.movementType);
          final res = _stateMachine.processAngle(angle);
          setState(() {
            _currentPose = poses.first;
            _imageSize = Size(image.width.toDouble(), image.height.toDouble());
            _currentAngle = res.currentAngle;
            _statusText = res.statusText;
            _isBadPosture = res.isBadPosture;
            _missedRepReason = res.missedRepReason;
          });
        }
      }
    } catch (_) {} finally { _session.isProcessing = false; }
  }

  void _toggleTestSquats() {
    setState(() {
      _isTestSquatsActive = !_isTestSquatsActive;
      _stateMachine.forceMovementType(_isTestSquatsActive ? ExerciseMovementType.squat : widget.movementType);
    });
    _ttsService.speak(_isTestSquatsActive ? 'Squat mode active' : 'Default mode active', force: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _session.dispose();
    _poseDetector.close();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_session.isReady || _session.controller == null) return const VisionAiPlaceholderCard();

    return VisionAiCameraPreviewStack(
      controller: _session.controller!,
      pose: _currentPose,
      imageSize: _imageSize,
      rotation: _session.currentRotation,
      isBadPosture: _isBadPosture,
      isFrontCamera: _session.isFrontCamera,
      repCount: _stateMachine.repCount,
      targetReps: widget.targetReps,
      currentAngle: _currentAngle,
      statusText: _statusText,
      placement: widget.placement,
      onStop: widget.onStop,
      onToggleCamera: () => _session.toggle(_processFrame, () => setState(() {})),
      currentSet: widget.currentSet,
      totalSets: widget.totalSets,
      elapsedSeconds: _elapsedSeconds,
      exerciseName: widget.exerciseName,
      isTestSquatsActive: _isTestSquatsActive,
      onToggleTestSquats: _toggleTestSquats,
      missedRepReason: _missedRepReason,
      height: widget.height,
    );
  }
}
