import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'bmi_gauge_painter.dart';

/// Smooth animated wrapper around BmiGaugePainter.
class BmiGaugeWidget extends StatelessWidget {
  final double bmi;
  final double height;

  const BmiGaugeWidget({
    super.key,
    required this.bmi,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: bmi, end: bmi),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        builder: (context, animatedBmi, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: BmiGaugePainter(
              currentBmi: animatedBmi,
              surfaceColor: AppColors.surface,
            ),
          );
        },
      ),
    );
  }
}
