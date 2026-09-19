import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'calorie_calculator_sheet.dart';

class AiNutritionFuelCard extends StatelessWidget {
  final int targetCalories;
  final int proteinGrams;
  final double waterLiters;
  final double bmi;
  final VoidCallback? onRecalibrate;

  const AiNutritionFuelCard({
    super.key,
    this.targetCalories = 2650,
    this.proteinGrams = 160,
    this.waterLiters = 3.5,
    this.bmi = 24.2,
    this.onRecalibrate,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onRecalibrate ?? () => CalorieCalculatorSheet.show(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(Icons.bolt_rounded, color: accent, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI NUTRITION & FUEL TARGET', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('BMI: $bmi • Optimized for Hypertrophy', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 12, color: accent),
                      const SizedBox(width: 4),
                      Text('TUNE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: accent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(child: _stat('CALORIES', '$targetCalories kcal', Icons.local_fire_department_rounded, Colors.deepOrangeAccent)),
                  _divider(),
                  Expanded(child: _stat('PROTEIN', '${proteinGrams}g', Icons.restaurant_rounded, Colors.cyanAccent)),
                  _divider(),
                  Expanded(child: _stat('WATER', '${waterLiters}L', Icons.water_drop_rounded, Colors.lightBlueAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String val, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(val, style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 26, color: AppColors.border);
}
