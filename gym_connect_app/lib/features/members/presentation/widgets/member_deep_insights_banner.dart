import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/gym_member.dart';

class MemberDeepInsightsBanner extends StatelessWidget {
  final GymMember member;
  final bool isCompact;

  const MemberDeepInsightsBanner({
    super.key,
    required this.member,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12, vertical: isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Fitness Tracking (Streak + Protocol + Day)
          Row(
            children: [
              // Streak Flame Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.orangeAccent),
                    const SizedBox(width: 3),
                    Text(
                      '${member.currentStreakDays}D STREAK',
                      style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Protocol Info
              Expanded(
                child: Text(
                  '${member.assignedProtocol} (Day ${member.currentRoutineDay})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),

              // Total Check-Ins
              Text(
                '${member.totalCheckIns} Visits',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),

          if (!isCompact) ...[
            const Divider(color: AppColors.border, height: 12),
            // Row 2: Financial Health & Security Gate Access Audit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_score_rounded, size: 12, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      'Last Payment: ${member.lastPaymentDate != null ? "${member.lastPaymentDate!.day}/${member.lastPaymentDate!.month}/${member.lastPaymentDate!.year}" : "Reconciled at Admission"}',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.door_sliding_rounded, size: 12, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      member.lastScanGate,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
