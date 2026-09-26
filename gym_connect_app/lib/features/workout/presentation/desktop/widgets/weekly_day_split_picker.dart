import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/workout_models.dart';

class WeeklyDaySplitPicker extends StatelessWidget {
  final List<WorkoutRoutineDay> days;
  final int selectedDayNumber;
  final ValueChanged<int> onSelectDay;

  const WeeklyDaySplitPicker({
    super.key,
    required this.days,
    required this.selectedDayNumber,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final dayNum = index + 1;
          final day = days.firstWhere(
            (d) => d.dayNumber == dayNum,
            orElse: () => WorkoutRoutineDay(
              id: 'day-$dayNum',
              routineId: '',
              dayNumber: dayNum,
              title: 'Day $dayNum',
              muscleGroups: const ['General'],
            ),
          );

          final isSelected = selectedDayNumber == dayNum;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => onSelectDay(dayNum),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 160,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DAY $dayNum',
                          style: GoogleFonts.oswald(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: isSelected ? AppColors.primary : Colors.white,
                          ),
                        ),
                        if (day.isRestDay)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'REST',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day.muscleGroups.join(' & '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.isRestDay
                          ? 'Recovery Protocol'
                          : '${day.exercises.length} Exercise${day.exercises.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isSelected ? AppColors.primary : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
