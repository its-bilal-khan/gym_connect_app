import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/bmi_models.dart';

/// CustomPainter rendering Google Search style BMI Speedometer Gauge.
class BmiGaugePainter extends CustomPainter {
  final double currentBmi;
  final Color surfaceColor;

  const BmiGaugePainter({
    required this.currentBmi,
    this.surfaceColor = const Color(0xFF18181B),
  });

  static const double _minBmi = 15.0;
  static const double _maxBmi = 40.0;
  static const double _totalSpan = _maxBmi - _minBmi;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 14;
    final radius = math.min(cx - 24, size.height - 28);
    const strokeWidth = 16.0;

    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // 1. Draw the 4 colored segments
    final segments = [
      (15.0, 18.5, BmiCategory.underweight.color),
      (18.5, 25.0, BmiCategory.normal.color),
      (25.0, 30.0, BmiCategory.overweight.color),
      (30.0, 40.0, BmiCategory.obese.color),
    ];

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (final seg in segments) {
      final startFrac = (seg.$1 - _minBmi) / _totalSpan;
      final sweepFrac = (seg.$2 - seg.$1) / _totalSpan;
      final startAngle = math.pi + (startFrac * math.pi);
      final sweepAngle = sweepFrac * math.pi;

      segmentPaint.color = seg.$3;
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, segmentPaint);
    }

    // 2. Draw Google-style boundary labels (15, 18.5, 25, 30, 40)
    _drawMarker(canvas, '15', math.pi, cx, cy, radius + 15);
    _drawMarker(canvas, '18.5', math.pi + (3.5 / 25.0) * math.pi, cx, cy, radius + 15);
    _drawMarker(canvas, '25', math.pi + (10.0 / 25.0) * math.pi, cx, cy, radius + 15);
    _drawMarker(canvas, '30', math.pi + (15.0 / 25.0) * math.pi, cx, cy, radius + 15);
    _drawMarker(canvas, '40', 2 * math.pi, cx, cy, radius + 15);

    // 3. Draw Needle pointing to current BMI
    final clampedBmi = currentBmi.clamp(_minBmi, _maxBmi);
    final needleFrac = (clampedBmi - _minBmi) / _totalSpan;
    final needleAngle = math.pi + (needleFrac * math.pi);

    final needleLength = radius - (strokeWidth / 2) + 2;
    final needleTip = Offset(
      cx + needleLength * math.cos(needleAngle),
      cy + needleLength * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx, cy), needleTip, needlePaint);

    // 4. Draw Center Pivot (Google White Ring with Hollow Center)
    final outerPivot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 6.5, outerPivot);

    final innerHole = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 3.2, innerHole);
  }

  void _drawMarker(
    Canvas canvas,
    String text,
    double angle,
    double cx,
    double cy,
    double textRadius,
  ) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFFA1A1AA),
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final x = cx + textRadius * math.cos(angle) - (textPainter.width / 2);
    final y = cy + textRadius * math.sin(angle) - (textPainter.height / 2);

    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant BmiGaugePainter oldDelegate) {
    return oldDelegate.currentBmi != currentBmi ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}
