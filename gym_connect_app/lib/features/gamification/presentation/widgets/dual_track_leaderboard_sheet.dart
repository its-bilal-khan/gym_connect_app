import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dual_track_leaderboard_provider.dart';
import '../providers/dual_track_leaderboard_state.dart';
import 'leaderboard_grid_view.dart';
import 'leaderboard_header_bar.dart';
import 'leaderboard_list_view.dart';
import 'leaderboard_podium_row.dart';
import 'leaderboard_qualification_banner.dart';
import 'podium_archives_list_view.dart';

class DualTrackLeaderboardSheet extends ConsumerWidget {
  const DualTrackLeaderboardSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const DualTrackLeaderboardSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dualTrackLeaderboardProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            const LeaderboardHeaderBar(),
            const LeaderboardQualificationBanner(),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.errorMessage != null
                      ? Center(child: Text(state.errorMessage!, style: GoogleFonts.inter(color: AppColors.error)))
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state.activeTrack == LeaderboardTrack.podiumArchives)
                                PodiumArchivesListView(archives: state.archives)
                              else if (state.viewMode == LeaderboardViewMode.grid)
                                LeaderboardGridView(
                                  members: state.activeMembers,
                                  isMonthly: state.activeTrack == LeaderboardTrack.monthlyRace,
                                )
                              else ...[
                                if (state.activeMembers.isEmpty)
                                  const LeaderboardListView(members: [])
                                else ...[
                                  if (state.podiumMembers.isNotEmpty)
                                    LeaderboardPodiumRow(
                                      podiumMembers: state.podiumMembers,
                                      isMonthly: state.activeTrack == LeaderboardTrack.monthlyRace,
                                    ),
                                  if (state.runnersUpMembers.isNotEmpty)
                                    LeaderboardListView(
                                      members: state.runnersUpMembers,
                                      isMonthly: state.activeTrack == LeaderboardTrack.monthlyRace,
                                    ),
                                ],
                              ],
                            ],
                          ),
                        ),
            ),
            const SizedBox(height: 8),
            _buildUserStatusBar(context, state, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatusBar(BuildContext context, DualTrackLeaderboardState state, Color accent) {
    final isMonthly = state.activeTrack == LeaderboardTrack.monthlyRace;
    int userRank = 0;
    int points = 0;
    final status = state.memberStatus;
    if (status != null) {
      if (isMonthly) {
        userRank = (status['monthly_rank'] as num?)?.toInt() ?? 0;
        points = (status['monthly_points'] as num?)?.toInt() ?? 0;
      } else {
        userRank = (status['hall_of_fame_rank'] as num?)?.toInt() ?? 0;
        points = (status['longest_streak_days'] as num?)?.toInt() ?? 0;
      }
    }
    final streak = (status?['current_streak_days'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 22),
          const SizedBox(width: 8),
          Text(
            userRank > 0 ? 'YOUR RANK: #$userRank' : 'YOUR RANK: UNRANKED',
            style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const Spacer(),
          Text(
            '$streak-Day Streak • $points ${isMonthly ? "XP" : "Days"}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
          ),
        ],
      ),
    );
  }
}
