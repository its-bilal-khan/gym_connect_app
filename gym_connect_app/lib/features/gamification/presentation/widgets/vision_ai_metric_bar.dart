import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VisionAiMetricBar extends StatelessWidget {
  final int elapsedSeconds;
  final int currentSet;
  final int totalSets;
  final int repCount;
  final int targetReps;
  final Color accent;

  const VisionAiMetricBar({
    super.key,
    required this.elapsedSeconds,
    required this.currentSet,
    required this.totalSets,
    required this.repCount,
    required this.targetReps,
    required this.accent,
  });

  String _formatTimer(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem('TIMER', _formatTimer(elapsedSeconds), accent),
          Container(width: 1, height: 26, color: Colors.white24),
          _buildItem('SET', '$currentSet / $totalSets', Colors.white),
          Container(width: 1, height: 26, color: Colors.white24),
          _buildItem('REPS', '$repCount / $targetReps', accent),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
            letterSpacing: 0.8,
            shadows: const [
              Shadow(blurRadius: 8, color: Colors.black),
              Shadow(blurRadius: 16, color: Colors.black),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: const [
              Shadow(blurRadius: 8, color: Colors.black),
              Shadow(blurRadius: 16, color: Colors.black),
              Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black),
            ],
          ),
        ),
      ],
    );
  }
}
