import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';

class ExerciseTabBar extends StatelessWidget {
  final List<WorkoutDayExercise> exercises;
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final Color accentColor;

  const ExerciseTabBar({
    super.key,
    required this.exercises,
    required this.activeIndex,
    required this.onSelect,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: exercises.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isCurrent = i == activeIndex;
          return ChoiceChip(
            selected: isCurrent,
            onSelected: (_) => onSelect(i),
            label: Text(exercises[i].exercise.name),
            labelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? Colors.black : AppColors.textPrimary,
            ),
            selectedColor: accentColor,
            backgroundColor: AppColors.surface,
          );
        },
      ),
    );
  }
}
