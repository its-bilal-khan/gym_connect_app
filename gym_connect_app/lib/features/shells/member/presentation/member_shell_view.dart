import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../tracking/presentation/providers/step_tracker_notifier.dart';
import '../../../workout/presentation/active_workout_screen.dart';
import '../../../workout/presentation/providers/workout_notifier.dart';
import '../../../workout/presentation/widgets/ninety_day_calendar_widget.dart';
import '../../../workout/presentation/widgets/one_tap_action_card.dart';
import 'widgets/gate_pass_card.dart';
import 'widgets/pedometer_card.dart';
import 'widgets/streak_badge.dart';

class MemberShellView extends ConsumerWidget {
  final UserProfile profile;
  final int selectedIndex;

  const MemberShellView({
    super.key,
    required this.profile,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (selectedIndex) {
      case 0:
        return _buildTodayTab(context, ref);
      case 1:
        return _buildWorkoutHubTab(context, ref);
      case 2:
        return _buildGatePassTab(context);
      case 3:
      default:
        return _buildProfileTab(context);
    }
  }

  Widget _buildTodayTab(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutNotifierProvider);
    final stepData = ref.watch(stepTrackerProvider);
    final routine = workoutState.routineDay;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const StreakBadge(streakDays: 5),
                const Spacer(),
                Text('DAY ${routine?.dayNumber ?? 24} OF 90', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            if (routine != null)
              OneTapActionCard(
                routine: routine,
                onStart: () {
                  ref.read(workoutNotifierProvider.notifier).startWorkout();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
                },
              ),
            const SizedBox(height: 14),
            PedometerCard(
              steps: stepData.steps,
              distanceKm: stepData.distanceKm,
              caloriesBurned: stepData.caloriesBurned,
              isLive: stepData.isTrackingLive,
              isWaiting: stepData.isWaitingForSensor,
              errorMessage: stepData.sensorError,
              badgeText: stepData.badgeText,
              isHealthConnectMissing: stepData.isHealthConnectMissing,
              onTap: () => ref.read(stepTrackerProvider.notifier).handleCardAction(),
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutHubTab(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutNotifierProvider);
    final dayNum = workoutState.routineDay?.dayNumber ?? 24;
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

  Widget _buildGatePassTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [const GatePassCard(), SizedBox(height: 110 + bottomInset)]),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MEMBER PROFILE & STORE', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            Text('Plan: Annual VIP • Active through Dec 2026', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
