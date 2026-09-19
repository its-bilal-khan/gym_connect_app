import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/gamification_models.dart';
import '../providers/gamification_provider.dart';

class GymLeaderboardSheet extends ConsumerWidget {
  const GymLeaderboardSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const GymLeaderboardSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final myGamification = ref.watch(gamificationProvider);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GYM LEADERBOARD', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('Ranked by consistency, workout streak & volume', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            leaderboardAsync.when(
              loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => Expanded(child: Center(child: Text('Failed to load leaderboard', style: GoogleFonts.inter(color: AppColors.error)))),
              data: (entries) => Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _buildEntryTile(entries[i], accent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 24),
                  const SizedBox(width: 10),
                  Text('YOUR STREAK: ${myGamification.currentStreakDays} DAYS', style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const Spacer(),
                  Text('${myGamification.totalPoints} XP', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTile(LeaderboardEntry entry, Color accent) {
    Color rankColor = AppColors.textSecondary;
    if (entry.rank == 1) rankColor = Colors.amber;
    if (entry.rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (entry.rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? accent.withValues(alpha: 0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: entry.isCurrentUser ? accent : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Text('#${entry.rank}', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: rankColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('${entry.streakDays} Day Streak 🔥', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('${entry.totalPoints} XP', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: accent)),
        ],
      ),
    );
  }
}
