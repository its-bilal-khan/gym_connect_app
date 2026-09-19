import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../workout/presentation/providers/workout_notifier.dart';
import '../../../../workout/presentation/widgets/ninety_day_calendar_widget.dart';

class MemberWorkoutHubTab extends ConsumerWidget {
  const MemberWorkoutHubTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutNotifierProvider);
    final dayNum = workoutState.routineDay?.dayNumber ?? 1;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NinetyDayCalendarWidget(
              currentDay: dayNum,
              onDaySelected: (day) => ref.read(workoutNotifierProvider.notifier).loadTodayRoutine(day: day),
            ),
            const SizedBox(height: 16),
            Text('SCHEDULED FOR DAY $dayNum', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(workoutState.routineDay?.title ?? 'Personalized Routine', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
