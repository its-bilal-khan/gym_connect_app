import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class NinetyDayCalendarWidget extends StatelessWidget {
  final int currentDay;
  final ValueChanged<int> onDaySelected;

  const NinetyDayCalendarWidget({
    super.key,
    this.currentDay = 24,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '90-DAY SMART CALENDAR',
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'WEEK ${((currentDay - 1) ~/ 7) + 1} OF 13',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 90,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final dayNum = index + 1;
                final isPast = dayNum < currentDay;
                final isToday = dayNum == currentDay;
                final isRest = dayNum % 4 == 0;

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDaySelected(dayNum);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? accent.withValues(alpha: 0.15)
                          : isPast
                              ? AppColors.background
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday
                            ? accent
                            : isPast
                                ? accent.withValues(alpha: 0.3)
                                : AppColors.border,
                        width: isToday ? 1.8 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'DAY',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isToday ? accent : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$dayNum',
                          style: GoogleFonts.oswald(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isToday ? accent : AppColors.textPrimary,
                          ),
                        ),
                        Icon(
                          isPast
                              ? Icons.check_circle_rounded
                              : isRest
                                  ? Icons.bedtime_rounded
                                  : Icons.fitness_center_rounded,
                          size: 13,
                          color: isPast
                              ? accent
                              : isRest
                                  ? Colors.blueGrey
                                  : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
