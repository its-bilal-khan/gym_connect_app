import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/models.dart';

class PodiumArchivesListView extends StatelessWidget {
  final List<MonthlyPodiumArchive> archives;

  const PodiumArchivesListView({
    super.key,
    required this.archives,
  });

  @override
  Widget build(BuildContext context) {
    if (archives.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(
                'NO ARCHIVED SEASONS YET',
                style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Monthly podium archives are recorded automatically on the 1st of every month.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final accent = Theme.of(context).colorScheme.primary;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: archives.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = archives[index];
        Color rankColor = item.podiumRank == 1
            ? Colors.amber
            : item.podiumRank == 2
                ? const Color(0xFFC0C0C0)
                : const Color(0xFFCD7F32);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: rankColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '#${item.podiumRank} PODIUM',
                      style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: rankColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.monthYear,
                    style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${item.pointsScored} XP',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.memberName ?? 'Champion Member',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              Text(
                'Prize: ${item.rewardTitle} • Streak at finish: ${item.streakAtFinish}d',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isFulfilled ? accent.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: item.isFulfilled ? accent.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isFulfilled ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
                      size: 13,
                      color: item.isFulfilled ? accent : Colors.amber,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        item.isFulfilled
                            ? 'Fulfillment Complete • Official Rs. 0 Invoice & Subscription Extended'
                            : 'Pending Month-End Verification',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: item.isFulfilled ? accent : Colors.amber,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
