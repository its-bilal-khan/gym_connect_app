import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../store/presentation/in_gym_store_screen.dart';
import '../../../../super_admin/data/system_feature_toggle_repository.dart';
import '../../../../super_admin/domain/models/system_feature_flags.dart';
import '../../../../workout/presentation/providers/fitness_profile_provider.dart';
import '../../../../workout/presentation/providers/workout_notifier.dart';
import '../../../../workout/presentation/widgets/ai_workout_synthesizer_sheet.dart';
import '../../../../workout/presentation/widgets/calorie_calculator_sheet.dart';
import '../../../../workout/presentation/widgets/goal_onboarding_dialog.dart';
import '../../../../workout/presentation/widgets/gym_leaderboard_sheet.dart';
import 'gym_review_dialog.dart';
import 'pay_dues_sheet.dart';

class MemberProfileModulesList extends ConsumerWidget {
  const MemberProfileModulesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final flagsAsync = ref.watch(currentTenantFeatureFlagsProvider);
    final flags = flagsAsync.asData?.value ?? const SystemFeatureFlags();

    final profile = ref.watch(fitnessProfileProvider).asData?.value;
    final activeType = profile?.bodyType ?? ref.watch(workoutNotifierProvider).activeBodyType;
    final subText = profile?.bodyTypeSplitDescription ?? 'Tailored workouts tuned to genetics';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: accent.withValues(alpha: 0.4))),
          leading: const Icon(Icons.accessibility_new_rounded, color: Colors.cyanAccent),
          title: Row(
            children: [
              Text('Body Type & Goals', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
                child: Text(activeType.toUpperCase(), style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold, color: accent)),
              ),
            ],
          ),
          subtitle: Text(subText, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          onTap: () => GoalOnboardingDialog.show(context),
        ),
        if (flags.aiWorkouts) ...[
          const SizedBox(height: 10),
          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: accent.withValues(alpha: 0.5))),
            leading: Icon(Icons.auto_awesome_rounded, color: accent),
            title: Row(
              children: [
                Text('AI Workout Synthesizer', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('CLOUD AI', style: GoogleFonts.oswald(fontSize: 9, fontWeight: FontWeight.bold, color: accent)),
                ),
              ],
            ),
            subtitle: Text('Generate 90-day split with silent BMI & Track A/B routing', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            onTap: () => AiWorkoutSynthesizerSheet.show(context),
          ),
        ],
        if (flags.clinicalTools) ...[
          const SizedBox(height: 10),
          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
            leading: const Icon(Icons.calculate_rounded, color: Colors.deepOrangeAccent),
            title: Text('BMI & Calorie Calculator', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            subtitle: Text('Calculate TDEE, BMR, and daily macro targets', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            onTap: () => CalorieCalculatorSheet.show(context),
          ),
        ],
        if (flags.gamification) ...[
          const SizedBox(height: 10),
          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
            leading: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
            title: Text('Gym Consistency Leaderboard', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            subtitle: Text('View rankings, streaks & points', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            onTap: () => GymLeaderboardSheet.show(context),
          ),
        ],
        const SizedBox(height: 10),
        ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
          leading: const Icon(Icons.payments_rounded, color: Colors.lightGreenAccent),
          title: Text('Pay Dues & Renewals', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          subtitle: Text('JazzCash, EasyPaisa, Card & Instant Gate Unlock', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          onTap: () => PayDuesSheet.show(context),
        ),
        const SizedBox(height: 10),
        ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
          leading: const Icon(Icons.storefront_rounded, color: Colors.tealAccent),
          title: Text('In-Gym Supplements & Shakes', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          subtitle: Text('Protein shakes, bars & gear with counter pickup code', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          onTap: () => InGymStoreScreen.open(context),
        ),
        const SizedBox(height: 10),
        ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
          leading: const Icon(Icons.rate_review_rounded, color: Colors.purpleAccent),
          title: Text('Rate & Review Your Gym', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          subtitle: Text('Verified member rating, equipment and hygiene review', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          onTap: () => GymReviewDialog.show(context),
        ),
      ],
    );
  }
}
