import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';

class ConfettiCelebrationDialog extends StatefulWidget {
  final int totalSets;
  final double totalVolumeKg;
  final int durationMinutes;
  final VoidCallback onClose;

  const ConfettiCelebrationDialog({
    super.key,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.durationMinutes,
    required this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required int totalSets,
    required double totalVolumeKg,
    required int durationMinutes,
    required VoidCallback onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfettiCelebrationDialog(
        totalSets: totalSets,
        totalVolumeKg: totalVolumeKg,
        durationMinutes: durationMinutes,
        onClose: onClose,
      ),
    );
  }

  @override
  State<ConfettiCelebrationDialog> createState() => _ConfettiCelebrationDialogState();
}

class _ConfettiCelebrationDialogState extends State<ConfettiCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: accent.withValues(alpha: 0.4), width: 1.5)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) => CustomPaint(painter: _ConfettiPainter(_controller.value, accent)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(Icons.military_tech_rounded, color: accent, size: 48),
                ),
                const SizedBox(height: 16),
                Text('WORKOUT CRUSHED!', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('+100 XP EARNED • STREAK EXTENDED 🔥', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _metricCol('${widget.totalSets}', 'SETS DONE'),
                    _metricCol('${widget.totalVolumeKg.toInt()} kg', 'VOLUME'),
                    _metricCol('${widget.durationMinutes}m', 'DURATION'),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'CLAIM & RETURN TO HUB',
                  icon: Icons.check_circle_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClose();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCol(String val, String label) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color accent;

  _ConfettiPainter(this.progress, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [accent, Colors.amber, Colors.cyanAccent, Colors.deepOrangeAccent];
    final paint = Paint()..style = PaintingStyle.fill;
    final rand = math.Random(42);

    for (int i = 0; i < 25; i++) {
      paint.color = colors[i % colors.length].withValues(alpha: 0.7);
      final startX = rand.nextDouble() * size.width;
      final startY = (rand.nextDouble() * size.height + (progress * size.height)) % size.height;
      canvas.drawCircle(Offset(startX, startY), 3 + rand.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
