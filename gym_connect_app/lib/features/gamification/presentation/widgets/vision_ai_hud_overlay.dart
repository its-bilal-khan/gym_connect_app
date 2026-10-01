import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VisionAiHudOverlay extends StatelessWidget {
  final int repCount;
  final int targetReps;
  final double currentAngle;
  final String statusText;
  final bool isBadPosture;
  final VoidCallback onStop;
  final VoidCallback onToggleCamera;

  const VisionAiHudOverlay({
    super.key,
    required this.repCount,
    required this.targetReps,
    required this.currentAngle,
    required this.statusText,
    required this.isBadPosture,
    required this.onStop,
    required this.onToggleCamera,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final statusColor = isBadPosture ? Colors.redAccent : accent;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      'AI TRAINER LIVE',
                      style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: accent),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onToggleCamera,
                    icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
                    label: Text('STOP', style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: statusColor.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 1),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isBadPosture ? Icons.warning_rounded : Icons.check_circle_rounded, color: statusColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          statusText.toUpperCase(),
                          style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ANGLE: ${currentAngle.toStringAsFixed(0)}°  •  REPS: $repCount / $targetReps',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
