import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/models.dart';

class LeaderboardGridView extends StatelessWidget {
  final List<LeaderboardMember> members;
  final bool isMonthly;

  const LeaderboardGridView({
    super.key,
    required this.members,
    this.isMonthly = true,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view_rounded, size: 36, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(
                'NO MEMBERS FOUND',
                style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      );
    }

    final accent = Theme.of(context).colorScheme.primary;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final member = members[index];
        final score = isMonthly ? member.monthlyPoints : member.longestStreakDays;
        final scoreUnit = isMonthly ? 'XP' : 'Days';

        Color rankColor = AppColors.textSecondary;
        if (member.rank == 1) rankColor = Colors.amber;
        if (member.rank == 2) rankColor = const Color(0xFFC0C0C0);
        if (member.rank == 3) rankColor = const Color(0xFFCD7F32);

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: member.isCurrentUser ? accent.withValues(alpha: 0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: member.isCurrentUser ? accent : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: rankColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '#${member.rank}',
                      style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: rankColor),
                    ),
                  ),
                  if (member.streakMultiplier > 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${member.streakMultiplier.toStringAsFixed(2)}x',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent),
                      ),
                    ),
                ],
              ),
              Center(
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.background,
                  backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                  child: member.avatarUrl == null
                      ? Text(
                          member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                          style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        )
                      : null,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    member.fullName,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '🔥 ${member.currentStreakDays}d • $score $scoreUnit',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: member.isCurrentUser ? accent : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
