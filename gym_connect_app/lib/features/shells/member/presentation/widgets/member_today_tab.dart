import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../notifications/presentation/widgets/urgent_dues_banner.dart';
import '../../../../store/presentation/in_gym_store_screen.dart';
import '../../../../tracking/presentation/providers/step_tracker_notifier.dart';
import '../../../../tracking/presentation/step_tracker_full_screen.dart';
import '../../../../workout/presentation/active_workout_screen.dart';
import '../../../../workout/presentation/providers/gamification_provider.dart';
import '../../../../workout/presentation/providers/workout_notifier.dart';
import '../../../../workout/presentation/widgets/ai_nutrition_fuel_card.dart';
import '../../../../workout/presentation/widgets/gym_leaderboard_sheet.dart';
import '../../../../workout/presentation/widgets/one_tap_action_card.dart';
import 'pedometer_card.dart';
import 'streak_badge.dart';
import 'transformation_spotlight_card.dart';

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
            const SizedBox(height: 14),
            const UrgentDuesBanner(),
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
            InkWell(
              onTap: () => InGymStoreScreen.open(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      radius: 18,
                      child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('IN-GYM PRO STORE & SHAKES', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Supplements, chilled protein shakes & gear', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                  ],
                ),
              ),
            ),
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
              onTap: () {
                if (stepData.isHealthConnectMissing || stepData.sensorError != null) {
                  ref.read(stepTrackerProvider.notifier).handleCardAction();
                } else {
                  StepTrackerFullScreen.open(context);
                }
              },
              onTogglePause: () => ref.read(stepTrackerProvider.notifier).togglePauseResume(),
            ),
            const SizedBox(height: 14),
            const TransformationSpotlightCard(),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
