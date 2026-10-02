import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';

class WorkoutVideoLoopCard extends StatelessWidget {
  final VideoPlayerController? controller;
  final Color accent;

  const WorkoutVideoLoopCard({
    super.key,
    required this.controller,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = controller != null && controller!.value.isInitialized;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: isReady
          ? Center(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              ),
            )
          : Center(
              child: Icon(Icons.videocam_rounded, size: 64, color: accent.withValues(alpha: 0.6)),
            ),
    );
  }
}
