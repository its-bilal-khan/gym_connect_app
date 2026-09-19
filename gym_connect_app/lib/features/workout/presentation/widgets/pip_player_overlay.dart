import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class PipPlayerOverlay extends StatelessWidget {
  final bool isFrontAngle;
  final VoidCallback onToggleAngle;
  final VoidCallback onExpand;

  const PipPlayerOverlay({
    super.key,
    required this.isFrontAngle,
    required this.onToggleAngle,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onToggleAngle,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(isFrontAngle ? 'SIDE VIEW' : 'FRONT VIEW', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: accent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onExpand,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PipStatusPlaceholder extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRetry;

  const PipStatusPlaceholder({
    super.key,
    required this.isLoading,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    if (isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: accent)),
          const SizedBox(height: 10),
          Text('STREAMING EXERCISE FORM...', style: GoogleFonts.oswald(fontSize: 12, letterSpacing: 1.0, color: Colors.white70)),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.fitness_center_rounded, color: AppColors.textSecondary, size: 36),
        const SizedBox(height: 6),
        Text('VISUAL POSTURE CHECKPOINT', style: GoogleFonts.oswald(fontSize: 13, letterSpacing: 1.0, color: Colors.white70)),
        TextButton(onPressed: onRetry, child: Text('RETRY STREAM', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: accent))),
      ],
    );
  }
}
