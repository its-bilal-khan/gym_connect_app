import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/models.dart';

class LeaderboardPodiumRow extends StatelessWidget {
  final List<LeaderboardMember> podiumMembers;
  final bool isMonthly;

  const LeaderboardPodiumRow({
    super.key,
    required this.podiumMembers,
    this.isMonthly = true,
  });

  @override
  Widget build(BuildContext context) {
    if (podiumMembers.isEmpty) return const SizedBox.shrink();

    final first = podiumMembers.isNotEmpty ? podiumMembers[0] : null;
    final second = podiumMembers.length > 1 ? podiumMembers[1] : null;
    final third = podiumMembers.length > 2 ? podiumMembers[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildPodiumColumn(context, second, 2, const Color(0xFFC0C0C0), 65)),
          Expanded(child: _buildPodiumColumn(context, first, 1, Colors.amber, 88)),
          Expanded(child: _buildPodiumColumn(context, third, 3, const Color(0xFFCD7F32), 50)),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(BuildContext context, LeaderboardMember? member, int rank, Color rankColor, double standHeight) {
    final accent = Theme.of(context).colorScheme.primary;
    if (member == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.surface, child: Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('-', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          _buildStand(standHeight, rank, rankColor),
        ],
      );
    }

    final score = isMonthly ? member.monthlyPoints : member.longestStreakDays;
    final scoreUnit = isMonthly ? 'XP' : 'Days';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 26 : 21,
              backgroundColor: rankColor.withValues(alpha: 0.3),
              child: CircleAvatar(
                radius: rank == 1 ? 24 : 19,
                backgroundColor: AppColors.surface,
                backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                child: member.avatarUrl == null
                    ? Text(
                        member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                        style: GoogleFonts.oswald(fontSize: rank == 1 ? 16 : 13, fontWeight: FontWeight.bold, color: rankColor),
                      )
                    : null,
              ),
            ),
            if (rank == 1)
              const Positioned(
                top: -12,
                child: Icon(Icons.military_tech_rounded, color: Colors.amber, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          member.fullName,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          '$score $scoreUnit',
          style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: rank == 1 ? accent : AppColors.textSecondary),
        ),
        if (member.streakMultiplier > 1.0)
          Text(
            '${member.streakMultiplier.toStringAsFixed(2)}x',
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent),
          ),
        const SizedBox(height: 4),
        _buildStand(standHeight, rank, rankColor),
      ],
    );
  }

  Widget _buildStand(double height, int rank, Color color) {
    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$rank',
        style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
