import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../gamification/presentation/widgets/adaptive_step_alert_card.dart';
import '../../../../gamification/presentation/widgets/composite_compliance_ring_card.dart';
import '../../../../gamification/presentation/widgets/diet_proof_card.dart';
import '../../../../gamification/presentation/widgets/sleep_tracker_card.dart';
import '../../../../notifications/presentation/widgets/urgent_dues_banner.dart';
import '../../../../tracking/presentation/providers/step_tracker_notifier.dart';
import '../../../../tracking/presentation/step_tracker_full_screen.dart';
import '../../../../workout/presentation/active_workout_screen.dart';
import '../../../../workout/presentation/providers/fitness_profile_provider.dart';
import '../../../../workout/presentation/providers/gamification_provider.dart';
import '../../../../workout/presentation/providers/workout_notifier.dart';
import '../../../../workout/presentation/widgets/ai_nutrition_fuel_card.dart';
import '../../../../workout/presentation/widgets/gym_leaderboard_sheet.dart';
import '../../../../workout/presentation/widgets/one_tap_action_card.dart';
import 'in_gym_store_teaser_card.dart';
import 'explore_reels_teaser_card.dart';
import 'pedometer_card.dart';
import 'profile_quest_card.dart';
import 'streak_badge.dart';
import 'transformation_spotlight_card.dart';

class MemberTodayTab extends ConsumerWidget {
  const MemberTodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutNotifierProvider);
    final fitnessProfile = ref.watch(fitnessProfileProvider).asData?.value;
    final activeType = fitnessProfile?.bodyType ?? workoutState.activeBodyType;
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
            const AdaptiveStepAlertCard(),
            const CompositeComplianceRingCard(),
            const SizedBox(height: 14),
            if (fitnessProfile?.profileCompleted != true) ...[
              const ProfileQuestCard(),
              const SizedBox(height: 14),
            ],
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
            const SleepTrackerCard(),
            const SizedBox(height: 14),
            const DietProofCard(),
            const SizedBox(height: 14),
            AiNutritionFuelCard(
              targetCalories: fitnessProfile?.recommendedDailyCalories ?? (activeType == 'ectomorph' ? 2950 : (activeType == 'endomorph' ? 2150 : 2650)),
              proteinGrams: fitnessProfile?.recommendedProteinGrams ?? (activeType == 'ectomorph' ? 175 : (activeType == 'endomorph' ? 185 : 165)),
              waterLiters: fitnessProfile?.recommendedWaterLiters ?? (activeType == 'endomorph' ? 4.0 : 3.5),
              bodyTypeLabel: activeType.toUpperCase(),
            ),
            const SizedBox(height: 14),
            const InGymStoreTeaserCard(),
            const SizedBox(height: 14),
            const ExploreReelsTeaserCard(),
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
