import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';

class FullscreenVideoDialog extends StatefulWidget {
  final Exercise exercise;
  final bool initialFrontAngle;

  const FullscreenVideoDialog({
    super.key,
    required this.exercise,
    this.initialFrontAngle = true,
  });

  static Future<void> show(BuildContext context, Exercise exercise, {bool isFrontAngle = true}) {
    return showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) => FullscreenVideoDialog(exercise: exercise, initialFrontAngle: isFrontAngle),
    );
  }

  @override
  State<FullscreenVideoDialog> createState() => _FullscreenVideoDialogState();
}

class _FullscreenVideoDialogState extends State<FullscreenVideoDialog> {
  late bool _isFront;
  VideoPlayerController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isFront = widget.initialFrontAngle;
    _initVideo();
  }

  String get _activeUrl => (_isFront ? widget.exercise.videoUrl : widget.exercise.sideVideoUrl) ?? widget.exercise.videoUrl ?? '';

  Future<void> _initVideo() async {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    final url = _activeUrl;
    if (url.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.play();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final ctrl = _controller;
    final ready = !_isLoading && ctrl != null && ctrl.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.exercise.name.toUpperCase(), style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(widget.exercise.targetMuscle, style: GoogleFonts.inter(fontSize: 12, color: accent)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ready
                    ? AspectRatio(aspectRatio: ctrl.value.aspectRatio, child: VideoPlayer(ctrl))
                    : _isLoading
                        ? CircularProgressIndicator(color: accent)
                        : const Icon(Icons.fitness_center_rounded, color: Colors.white38, size: 50),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CAMERA ANGLE', style: GoogleFonts.oswald(fontSize: 12, letterSpacing: 1.2, color: Colors.white70)),
                      Row(
                        children: [
                          _angleBtn('FRONT', _isFront, () { setState(() => _isFront = true); _initVideo(); }),
                          const SizedBox(width: 8),
                          _angleBtn('SIDE', !_isFront, () { setState(() => _isFront = false); _initVideo(); }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(widget.exercise.tips, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _angleBtn(String label, bool active, VoidCallback onTap) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: active ? accent : AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: active ? accent : AppColors.border)),
        child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.black : Colors.white)),
      ),
    );
  }
}
