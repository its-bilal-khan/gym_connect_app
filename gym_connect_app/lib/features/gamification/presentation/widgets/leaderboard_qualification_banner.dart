import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dual_track_leaderboard_provider.dart';

class LeaderboardQualificationBanner extends ConsumerWidget {
  const LeaderboardQualificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dualTrackLeaderboardProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final completed = (state.memberStatus?['monthly_workouts_completed'] as num?)?.toInt() ?? 0;
    final required = state.rewardConfig.minMonthlyWorkoutsQualification;
    final remaining = (required - completed).clamp(0, required);
    final isQualified = state.isQualified;
    final multiplier = state.streakMultiplier;
    final streakDays = (state.memberStatus?['current_streak_days'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isQualified ? accent.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isQualified ? Icons.verified_rounded : Icons.fitness_center_rounded,
                size: 16,
                color: isQualified ? accent : Colors.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isQualified
                      ? 'ELITE QUALIFIED: Eligible for Top 3 Rewards'
                      : '$completed/$required Workouts Completed • $remaining More to Qualify',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isQualified ? accent : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (multiplier > 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.deepOrangeAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${multiplier.toStringAsFixed(2)}x BOOST',
                    style: GoogleFonts.oswald(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrangeAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: state.qualificationProgress,
              minHeight: 5,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(isQualified ? accent : Colors.amber),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Streak: $streakDays Days unbroken',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
              ),
              Text(
                multiplier >= 1.50
                    ? 'Max 1.50x Titan Tier 🔥'
                    : multiplier >= 1.25
                        ? '1.25x Beast Mode (60d for 1.50x)'
                        : multiplier >= 1.10
                            ? '1.10x Iron Tier (30d for 1.25x)'
                            : '14d streak unlocks 1.10x boost',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: multiplier > 1.0 ? Colors.deepOrangeAccent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
