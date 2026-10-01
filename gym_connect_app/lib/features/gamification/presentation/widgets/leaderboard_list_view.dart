import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/models.dart';

class LeaderboardListView extends StatelessWidget {
  final List<LeaderboardMember> members;
  final bool isMonthly;

  const LeaderboardListView({
    super.key,
    required this.members,
    this.isMonthly = true,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'NO MEMBERS RANKED YET',
              style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete workouts and log habits to claim a spot on the leaderboard!',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final accent = Theme.of(context).colorScheme.primary;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final member = members[index];
        final score = isMonthly ? member.monthlyPoints : member.longestStreakDays;
        final scoreUnit = isMonthly ? 'XP' : 'Days';

        Color rankColor = AppColors.textSecondary;
        if (member.rank == 1) rankColor = Colors.amber;
        if (member.rank == 2) rankColor = const Color(0xFFC0C0C0);
        if (member.rank == 3) rankColor = const Color(0xFFCD7F32);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: member.isCurrentUser ? accent.withValues(alpha: 0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: member.isCurrentUser ? accent : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#${member.rank}',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.background,
                backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                child: member.avatarUrl == null
                    ? Text(
                        member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                        style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: member.isCurrentUser ? FontWeight.bold : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          '🔥 ${member.currentStreakDays}d streak',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                        ),
                        if (member.streakMultiplier > 1.0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${member.streakMultiplier.toStringAsFixed(2)}x',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrangeAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '$score $scoreUnit',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: member.isCurrentUser ? accent : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
