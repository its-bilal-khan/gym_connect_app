import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lightweight dashed human torso silhouette helping users align in the camera frame.
class HumanAlignmentSilhouette extends StatelessWidget {
  final Color? color;

  const HumanAlignmentSilhouette({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;

    return IgnorePointer(
      child: CustomPaint(
        painter: _SilhouettePainter(color: accent),
        child: Align(
          alignment: const Alignment(0, 0.72),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Text(
              'ALIGN BODY IN FRAME',
              style: GoogleFonts.oswald(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: accent.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final Color color;

  _SilhouettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height * 0.42;

    // Head
    final headRect = Rect.fromCenter(
      center: Offset(cx, cy - size.height * 0.22),
      width: size.width * 0.18,
      height: size.height * 0.16,
    );
    _drawDashedOval(canvas, headRect, paint);

    // Shoulders and Torso
    final torsoPath = Path();
    final shoulderW = size.width * 0.36;
    final waistW = size.width * 0.24;
    final hipW = size.width * 0.28;

    torsoPath.moveTo(cx - shoulderW / 2, cy - size.height * 0.10);
    // Neck to left shoulder
    torsoPath.quadraticBezierTo(cx - size.width * 0.08, cy - size.height * 0.14, cx, cy - size.height * 0.14);
    torsoPath.quadraticBezierTo(cx + size.width * 0.08, cy - size.height * 0.14, cx + shoulderW / 2, cy - size.height * 0.10);

    // Right arm/torso down to waist
    torsoPath.lineTo(cx + waistW / 2, cy + size.height * 0.12);
    // Right hip
    torsoPath.lineTo(cx + hipW / 2, cy + size.height * 0.24);
    // Bottom hip line
    torsoPath.lineTo(cx - hipW / 2, cy + size.height * 0.24);
    // Left hip to waist
    torsoPath.lineTo(cx - waistW / 2, cy + size.height * 0.12);
    torsoPath.close();

    _drawDashedPath(canvas, torsoPath, paint);
  }

  void _drawDashedOval(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()..addOval(rect);
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, {double dashWidth = 5.0, double dashSpace = 4.0}) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length) ? dashWidth : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) => oldDelegate.color != color;
}
