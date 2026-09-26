import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/gym_member.dart';

class MemberListCard extends StatelessWidget {
  final GymMember member;
  final bool showDeepInsights;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageCredentials;
  final VoidCallback onToggleFreeze;
  final VoidCallback onSendReminder;

  const MemberListCard({
    super.key,
    required this.member,
    required this.showDeepInsights,
    required this.onEdit,
    required this.onDelete,
    required this.onManageCredentials,
    required this.onToggleFreeze,
    required this.onSendReminder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isExp = member.isExpired;

    // Resolve Tier Color & Label
    Color tierColor;
    String tierLabel;

    final planLower = member.planName.toLowerCase();
    if (planLower.contains('vip') || planLower.contains('annual') || planLower.contains('gold')) {
      tierColor = const Color(0xFFFFC107);
      tierLabel = 'ANNUAL VIP';
    } else if (planLower.contains('quarter') || planLower.contains('shred') || planLower.contains('silver')) {
      tierColor = const Color(0xFF00E5FF);
      tierLabel = 'QUARTERLY';
    } else if (planLower.contains('semi') || planLower.contains('pro')) {
      tierColor = const Color(0xFFB388FF);
      tierLabel = 'PRO';
    } else {
      tierColor = accent;
      tierLabel = member.planName.toUpperCase();
    }

    final statusColor = member.isFrozen
        ? Colors.cyanAccent
        : isExp
            ? Colors.redAccent
            : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surface, // Pure #18181B surface
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A), width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Subtle 2.5px left border indicator
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2.5,
                color: tierColor.withValues(alpha: 0.85),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
          children: [
            // 1. Monospace Code Badge (85px)
            SizedBox(
              width: 85,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF131316),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Center(
                  child: Text(
                    member.memberCode,
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFA1A1AA),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 2. Member Identity: Avatar (Subtle #27272A border) + Name + Phone (220px)
            SizedBox(
              width: 220,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF131316),
                      border: Border.all(color: const Color(0xFF27272A), width: 1.2),
                    ),
                    child: Center(
                      child: Text(
                        member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'M',
                        style: GoogleFonts.oswald(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          member.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                        Text(
                          member.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // 3. Plan Tier Pill (10% opacity, solid text) & Expiry (170px)
            SizedBox(
              width: 170,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: tierColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: tierColor.withValues(alpha: 0.25), width: 0.8),
                        ),
                        child: Text(
                          tierLabel,
                          style: GoogleFonts.oswald(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: tierColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          member.planName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Exp: ${member.expiryDate.year}-${member.expiryDate.month.toString().padLeft(2, '0')}-${member.expiryDate.day.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isExp ? Colors.redAccent : const Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // 4. Status & Dues (120px)
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      member.statusDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.duesAmount > 0 ? 'PKR ${member.duesAmount.toStringAsFixed(0)} DUE' : 'PAID',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: member.duesAmount > 0 ? Colors.redAccent : const Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Deep Insights Telemetry (if Enabled)
            if (showDeepInsights) ...[
              const SizedBox(width: 14),
              SizedBox(
                width: 200,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131316),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center_rounded, size: 12, color: Color(0xFFA1A1AA)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          member.assignedProtocol,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA1A1AA)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '🔥 ${member.currentStreakDays}D',
                        style: GoogleFonts.oswald(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(width: 14),

            // 6. Action Toolbar Capsule
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF131316),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (member.isExpiringSoon)
                    IconButton(
                      icon: const Icon(Icons.send_rounded, size: 14),
                      color: Colors.greenAccent,
                      tooltip: 'WhatsApp Renewal Reminder',
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      padding: EdgeInsets.zero,
                      onPressed: onSendReminder,
                    ),
                  IconButton(
                    icon: const Icon(Icons.key_rounded, size: 14),
                    color: const Color(0xFFA1A1AA),
                    tooltip: 'Login Credentials',
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    padding: EdgeInsets.zero,
                    onPressed: onManageCredentials,
                  ),
                  IconButton(
                    icon: Icon(
                      member.isFrozen ? Icons.play_circle_fill_rounded : Icons.pause_circle_outline_rounded,
                      size: 14,
                      color: member.isFrozen ? Colors.greenAccent : const Color(0xFFA1A1AA),
                    ),
                    tooltip: member.isFrozen ? 'Unfreeze Membership' : 'Freeze Membership (Leave)',
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    padding: EdgeInsets.zero,
                    onPressed: onToggleFreeze,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFFA1A1AA)),
                    tooltip: 'Edit Member',
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    padding: EdgeInsets.zero,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                    tooltip: 'Remove',
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    padding: EdgeInsets.zero,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
),
);
  }
}
