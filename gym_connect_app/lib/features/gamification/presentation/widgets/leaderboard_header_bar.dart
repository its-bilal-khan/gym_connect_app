import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dual_track_leaderboard_provider.dart';
import '../providers/dual_track_leaderboard_state.dart';

class LeaderboardHeaderBar extends ConsumerWidget {
  const LeaderboardHeaderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dualTrackLeaderboardProvider);
    final notifier = ref.read(dualTrackLeaderboardProvider.notifier);
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GYM LEADERBOARD',
                    style: GoogleFonts.oswald(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    state.activeTrack == LeaderboardTrack.monthlyRace
                        ? 'Monthly Race: Resets on 1st • Top 3 Win Prizes'
                        : state.activeTrack == LeaderboardTrack.hallOfFame
                            ? 'Hall of Fame: Lifetime Unbroken Streaks'
                            : 'Podium Archives: Past Winners & Ledger',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Rule 5: Dual-View Standard Toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.view_list_rounded,
                      size: 18,
                      color: state.viewMode == LeaderboardViewMode.list ? accent : AppColors.textSecondary,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'List View',
                    onPressed: () => notifier.setViewMode(LeaderboardViewMode.list),
                  ),
                  Container(width: 1, height: 16, color: AppColors.border),
                  IconButton(
                    icon: Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: state.viewMode == LeaderboardViewMode.grid ? accent : AppColors.textSecondary,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'Grid View',
                    onPressed: () => notifier.setViewMode(LeaderboardViewMode.grid),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Track selector tabs
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _buildTab(context, 'Monthly Race', LeaderboardTrack.monthlyRace, state.activeTrack, notifier, accent),
              _buildTab(context, 'Hall of Fame', LeaderboardTrack.hallOfFame, state.activeTrack, notifier, accent),
              _buildTab(context, 'Archives', LeaderboardTrack.podiumArchives, state.activeTrack, notifier, accent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(
    BuildContext context,
    String title,
    LeaderboardTrack track,
    LeaderboardTrack activeTrack,
    DualTrackLeaderboardNotifier notifier,
    Color accent,
  ) {
    final isSelected = activeTrack == track;
    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.setTrack(track),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: isSelected ? Border.all(color: accent.withValues(alpha: 0.4)) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
