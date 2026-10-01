import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class RapidGoalSelector extends StatelessWidget {
  final String selectedGoal;
  final ValueChanged<String> onSelect;
  final Color accent;

  const RapidGoalSelector({
    super.key,
    required this.selectedGoal,
    required this.onSelect,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TARGET PHYSIQUE GOAL',
          style: GoogleFonts.oswald(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _goalCard('lean_slim', 'Lean & Shred', Icons.directions_run_rounded),
            const SizedBox(width: 8),
            _goalCard('v_shape', 'Athletic V-Taper', Icons.fitness_center_rounded),
            const SizedBox(width: 8),
            _goalCard('heavyweight', 'Mass & Power', Icons.sports_mma_rounded),
          ],
        ),
      ],
    );
  }

  Widget _goalCard(String key, String title, IconData icon) {
    final isSelected = selectedGoal == key;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.12) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? accent : AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? accent : AppColors.textSecondary, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
