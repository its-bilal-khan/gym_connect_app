import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';

/// Mini live preview matching the exact signature layout of CalculatorsHubScreen.
class MiniCalculatorsHubPreview extends StatelessWidget {
  const MiniCalculatorsHubPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F13),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: The Two Iconic Calculator Hub Cards
          Row(
            children: [
              // Card 1: Calorie Calculator (Flame icon + Orange gradient)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.local_fire_department_rounded, size: 12, color: Color(0xFFFF6B35)),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CALORIES', style: GoogleFonts.oswald(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('2,450 kcal', style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w600, color: const Color(0xFFFF6B35))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Card 2: Macro Calculator (Pie chart icon + Purple gradient)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.pie_chart_rounded, size: 12, color: Color(0xFF7C4DFF)),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MACROS', style: GoogleFonts.oswald(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('40P:40C:20F', style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w600, color: const Color(0xFF7C4DFF))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Bottom Bar: 1RM and BMI clinical output
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center_rounded, size: 12, color: Colors.amberAccent),
                        const SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('1RM BENCH MAX', style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            Text('105 KG ESTIMATE', style: GoogleFonts.oswald(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.monitor_weight_rounded, size: 12, color: Colors.cyanAccent),
                        const SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('BMI INDEX', style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            Text('22.4 OPTIMAL', style: GoogleFonts.oswald(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
