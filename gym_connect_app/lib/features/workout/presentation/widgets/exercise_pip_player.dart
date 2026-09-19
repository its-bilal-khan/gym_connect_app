import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';
import 'fullscreen_video_dialog.dart';
import 'pip_player_overlay.dart';

class ExercisePipPlayer extends StatefulWidget {
  final Exercise exercise;
  const ExercisePipPlayer({super.key, required this.exercise});

  @override
  State<ExercisePipPlayer> createState() => _ExercisePipPlayerState();
}

class _ExercisePipPlayerState extends State<ExercisePipPlayer> {
  static const String _fallbackUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isFrontAngle = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(ExercisePipPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id ||
        oldWidget.exercise.videoUrl != widget.exercise.videoUrl ||
        oldWidget.exercise.sideVideoUrl != widget.exercise.sideVideoUrl) {
      _initVideo();
    }
  }

  String get _activeUrl => (_isFrontAngle ? widget.exercise.videoUrl : widget.exercise.sideVideoUrl) ?? widget.exercise.videoUrl ?? '';

  void _toggleAngle() {
    setState(() => _isFrontAngle = !_isFrontAngle);
    _initVideo();
  }

  Future<void> _initVideo() async {
    _disposeController();
    final primary = _activeUrl;
    if (primary.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
      return;
    }
    if (mounted) setState(() { _isLoading = true; _hasError = false; });
    bool ok = await _tryLoadVideo(primary);
    if (!ok && primary != _fallbackUrl) ok = await _tryLoadVideo(_fallbackUrl);
    if (mounted) setState(() { _isLoading = false; _hasError = !ok; });
  }

  Future<bool> _tryLoadVideo(String url) async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(0.0);
      await ctrl.play();
      ctrl.addListener(() {
        if (ctrl.value.hasError && mounted && !_hasError) {
          setState(() { _isLoading = false; _hasError = true; });
        }
      });
      return true;
    } catch (_) {
      _disposeController();
      return false;
    }
  }

  void _disposeController() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    final isReady = !_isLoading && !_hasError && ctrl != null && ctrl.value.isInitialized;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 175,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isReady)
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(width: ctrl.value.size.width, height: ctrl.value.size.height, child: VideoPlayer(ctrl)),
                      ),
                    )
                  else
                    PipStatusPlaceholder(isLoading: _isLoading, onRetry: _initVideo),
                  PipPlayerOverlay(
                    isFrontAngle: _isFrontAngle,
                    onToggleAngle: _toggleAngle,
                    onExpand: () => FullscreenVideoDialog.show(context, widget.exercise, isFrontAngle: _isFrontAngle),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: AppColors.primaryAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.exercise.tips, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
