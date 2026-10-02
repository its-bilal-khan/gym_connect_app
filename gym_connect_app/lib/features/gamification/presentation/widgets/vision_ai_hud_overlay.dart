import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vision_ai_metric_bar.dart';

class VisionAiHudOverlay extends StatelessWidget {
  final int repCount;
  final int targetReps;
  final double currentAngle;
  final String statusText;
  final bool isBadPosture;
  final VoidCallback onStop;
  final VoidCallback onToggleCamera;
  final int currentSet;
  final int totalSets;
  final int elapsedSeconds;
  final String exerciseName;
  final bool isTestSquatsActive;
  final VoidCallback? onToggleTestSquats;
  final String? missedRepReason;

  const VisionAiHudOverlay({
    super.key,
    required this.repCount,
    required this.targetReps,
    required this.currentAngle,
    required this.statusText,
    required this.isBadPosture,
    required this.onStop,
    required this.onToggleCamera,
    this.currentSet = 1,
    this.totalSets = 3,
    this.elapsedSeconds = 0,
    this.exerciseName = 'SQUAT',
    this.isTestSquatsActive = false,
    this.onToggleTestSquats,
    this.missedRepReason,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final statusColor = (missedRepReason != null || isBadPosture) ? Colors.redAccent : accent;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE AI • ${isTestSquatsActive ? "TEST SQUATS" : exerciseName.toUpperCase()}',
                    style: GoogleFonts.oswald(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: accent,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black),
                        Shadow(blurRadius: 16, color: Colors.black),
                      ],
                    ),
                  ),
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    onPressed: onToggleCamera,
                    icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(backgroundColor: Colors.black38),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    label: Text('EXIT', style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.85), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                  ),
                ]),
              ]),
              const SizedBox(height: 6),
              VisionAiMetricBar(elapsedSeconds: elapsedSeconds, currentSet: currentSet, totalSets: totalSets, repCount: repCount, targetReps: targetReps, accent: accent),
            ]),
            Column(children: [
              if (missedRepReason != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    missedRepReason!.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.redAccent,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black),
                        Shadow(blurRadius: 16, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              if (onToggleTestSquats != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: onToggleTestSquats,
                    icon: Icon(isTestSquatsActive ? Icons.check_circle_rounded : Icons.science_rounded, size: 16, color: accent),
                    label: Text(isTestSquatsActive ? '🧪 TEST SQUATS (ACTIVE)' : '🧪 Debug: Test Squats', style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black38,
                      side: BorderSide(color: isTestSquatsActive ? accent : Colors.white30, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(isBadPosture || missedRepReason != null ? Icons.warning_rounded : Icons.check_circle_rounded, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      statusText.toUpperCase(),
                      style: GoogleFonts.oswald(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        shadows: const [Shadow(blurRadius: 8, color: Colors.black), Shadow(blurRadius: 16, color: Colors.black)],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    'ANGLE: ${currentAngle.toStringAsFixed(0)}°  •  FORM ACCURACY ACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: const [Shadow(blurRadius: 8, color: Colors.black), Shadow(blurRadius: 16, color: Colors.black)],
                    ),
                  ),
                ]),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
