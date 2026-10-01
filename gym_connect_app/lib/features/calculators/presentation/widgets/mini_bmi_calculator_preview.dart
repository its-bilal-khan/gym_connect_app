import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/bmi_models.dart';
import 'bmi_gauge_painter.dart';

/// Mini live preview widget representing Google BMI Calculator module.
class MiniBmiCalculatorPreview extends StatelessWidget {
  final double bmi;

  const MiniBmiCalculatorPreview({
    super.key,
    this.bmi = 22.4,
  });

  @override
  Widget build(BuildContext context) {
    final category = BmiCategory.fromBmi(bmi);

    return Container(
      color: const Color(0xFF0F0F13),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BMI', style: GoogleFonts.inter(fontSize: 8, color: AppColors.textSecondary)),
                  Text(
                    bmi.toStringAsFixed(1),
                    style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 5, height: 5, decoration: BoxDecoration(color: category.color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(category.label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: BmiGaugePainter(
                currentBmi: bmi,
                surfaceColor: const Color(0xFF0F0F13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
