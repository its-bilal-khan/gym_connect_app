import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../tracking/presentation/providers/step_tracker_notifier.dart';
import '../../../../workout/presentation/active_workout_screen.dart';
import '../../../../workout/presentation/providers/gamification_provider.dart';
import '../../../../workout/presentation/providers/workout_notifier.dart';
import '../../../../workout/presentation/widgets/ai_nutrition_fuel_card.dart';
import '../../../../workout/presentation/widgets/gym_leaderboard_sheet.dart';
import '../../../../workout/presentation/widgets/one_tap_action_card.dart';
import 'pedometer_card.dart';
import 'streak_badge.dart';

class MemberTodayTab extends ConsumerWidget {
  const MemberTodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutNotifierProvider);
    final stepData = ref.watch(stepTrackerProvider);
    final gamification = ref.watch(gamificationProvider);
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
                StreakBadge(
                  streakDays: gamification.currentStreakDays,
                  onTap: () => GymLeaderboardSheet.show(context),
                ),
                const Spacer(),
                Text('DAY ${routine?.dayNumber ?? 1} OF 90', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            if (routine != null) ...[
              OneTapActionCard(
                routine: routine,
                onStart: () {
                  ref.read(workoutNotifierProvider.notifier).startWorkout();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
                },
              ),
              const SizedBox(height: 14),
            ],
            const AiNutritionFuelCard(),
            const SizedBox(height: 14),
            PedometerCard(
              steps: stepData.steps,
              distanceKm: stepData.distanceKm,
              caloriesBurned: stepData.caloriesBurned,
              isLive: stepData.isTrackingLive,
              isWaiting: stepData.isWaitingForSensor,
              isPaused: stepData.isPaused,
              errorMessage: stepData.sensorError,
              badgeText: stepData.badgeText,
              isHealthConnectMissing: stepData.isHealthConnectMissing,
              onTap: () => ref.read(stepTrackerProvider.notifier).handleCardAction(),
              onTogglePause: () => ref.read(stepTrackerProvider.notifier).togglePauseResume(),
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
