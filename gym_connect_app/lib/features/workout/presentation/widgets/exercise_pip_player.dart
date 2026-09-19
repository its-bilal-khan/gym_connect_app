import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';

class ExercisePipPlayer extends StatefulWidget {
  final Exercise exercise;
  const ExercisePipPlayer({super.key, required this.exercise});

  @override
  State<ExercisePipPlayer> createState() => _ExercisePipPlayerState();
}

class _ExercisePipPlayerState extends State<ExercisePipPlayer> {
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
    if (oldWidget.exercise.videoUrl != widget.exercise.videoUrl) {
      _disposeController();
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final url = widget.exercise.videoUrl;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
      return;
    }
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(0.0);
      await ctrl.play();
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
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
    final accent = Theme.of(context).colorScheme.primary;
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
                  else if (_isLoading)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: accent)),
                        const SizedBox(height: 10),
                        Text('STREAMING EXERCISE FORM...', style: GoogleFonts.oswald(fontSize: 12, letterSpacing: 1.0, color: Colors.white70)),
                      ],
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fitness_center_rounded, color: AppColors.textSecondary, size: 36),
                        const SizedBox(height: 6),
                        Text('VISUAL POSTURE CHECKPOINT', style: GoogleFonts.oswald(fontSize: 13, letterSpacing: 1.0, color: Colors.white70)),
                        TextButton(onPressed: _initVideo, child: Text('RETRY STREAM', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: accent))),
                      ],
                    ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(8), border: Border.all(color: accent.withValues(alpha: 0.5))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.repeat_rounded, color: AppColors.primaryAccent, size: 12),
                          const SizedBox(width: 4),
                          Text('PIP SILENT AUTO-LOOP', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: () => setState(() => _isFrontAngle = !_isFrontAngle),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(_isFrontAngle ? 'SIDE VIEW' : 'FRONT VIEW', style: GoogleFonts.inter(fontSize: 10, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
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
