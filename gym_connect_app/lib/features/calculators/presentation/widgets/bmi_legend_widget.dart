import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/bmi_models.dart';

/// Clean legend row matching Google Search BMI categories.
class BmiLegendWidget extends StatelessWidget {
  const BmiLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: BmiCategory.values.map((cat) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: cat.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${cat.label} (${cat.rangeLabel})',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFA1A1AA),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
