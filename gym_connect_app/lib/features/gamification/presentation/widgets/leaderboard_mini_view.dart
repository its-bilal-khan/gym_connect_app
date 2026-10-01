import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dual_track_leaderboard_provider.dart';
import '../providers/dual_track_leaderboard_state.dart';

class LeaderboardMiniView extends ConsumerWidget {
  final double scale;
  const LeaderboardMiniView({super.key, this.scale = 0.85});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dualTrackLeaderboardProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final podium = state.podiumMembers;
    final topMember = podium.isNotEmpty ? podium.first : null;
    final isMonthly = state.activeTrack == LeaderboardTrack.monthlyRace;
    final userRank = (state.memberStatus?['monthly_rank'] as num?)?.toInt() ?? 0;
    final multiplier = state.streakMultiplier;

    return Transform.scale(
      scale: scale,
      alignment: Alignment.topLeft,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMonthly ? 'LEADERBOARD • MONTHLY RACE' : 'LEADERBOARD • HALL OF FAME',
                    style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                if (multiplier > 1.0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${multiplier.toStringAsFixed(2)}x',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('👑 #1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      topMember?.fullName ?? 'No Leader Yet',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${isMonthly ? topMember?.monthlyPoints ?? 0 : topMember?.longestStreakDays ?? 0} ${isMonthly ? "XP" : "d"}',
                    style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    userRank > 0 ? 'Your Rank: #$userRank' : 'Unranked',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    state.isQualified ? '✓ Qualified for Top 3' : 'Needs workouts',
                    style: GoogleFonts.inter(fontSize: 10, color: state.isQualified ? accent : Colors.amber),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
