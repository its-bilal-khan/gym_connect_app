import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/gym_member.dart';

class MemberDataTable extends StatelessWidget {
  final List<GymMember> members;
  final bool showDeepInsights;
  final Function(GymMember) onEdit;
  final Function(GymMember) onDelete;
  final Function(GymMember) onManageCredentials;
  final Function(GymMember) onToggleFreeze;
  final Function(GymMember) onSendReminder;

  const MemberDataTable({
    super.key,
    required this.members,
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Live SaaS Status Bar on Table Top
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1B1B1E),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE DATABASE ROSTER • ${members.length} MEMBERS LOADED',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Direct Actions: WhatsApp Alert • Credentials • Freeze • Edit • Delete',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            // 2. Data Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF222226)),
                headingRowHeight: 48,
                dataRowMinHeight: 62,
                dataRowMaxHeight: 68,
                columnSpacing: 22,
                horizontalMargin: 20,
                dividerThickness: 0.8,
                headingTextStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
                dataTextStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                columns: [
                  _buildColumnHeader(Icons.badge_outlined, 'MEMBER CODE'),
                  _buildColumnHeader(Icons.person_outline_rounded, 'MEMBER DETAILS'),
                  _buildColumnHeader(Icons.phone_outlined, 'CONTACT'),
                  _buildColumnHeader(Icons.workspace_premium_outlined, 'MEMBERSHIP PLAN'),
                  _buildColumnHeader(Icons.verified_outlined, 'STATUS'),
                  _buildColumnHeader(Icons.calendar_today_outlined, 'EXPIRY DATE'),
                  _buildColumnHeader(Icons.payments_outlined, 'DUES'),
                  if (showDeepInsights) ...[
                    _buildColumnHeader(Icons.fitness_center_rounded, 'WORKOUT PROTOCOL'),
                    _buildColumnHeader(Icons.local_fire_department_rounded, 'CONSISTENCY'),
                    _buildColumnHeader(Icons.door_sliding_outlined, 'LAST GATE SCAN'),
                  ],
                  _buildColumnHeader(Icons.bolt_rounded, 'ACTIONS'),
                ],
              rows: members.asMap().entries.map((entry) {
                final index = entry.key;
                final m = entry.value;
                final isEven = index % 2 == 0;
                final isExp = m.isExpired;

                final statusColor = m.isFrozen
                    ? Colors.cyanAccent
                    : isExp
                        ? Colors.redAccent
                        : Colors.greenAccent;

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return accent.withValues(alpha: 0.08);
                    }
                    return isEven ? AppColors.surface : const Color(0xFF131316);
                  }),
                  cells: [
                    // Member Code Pill
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accent.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          m.memberCode,
                          style: GoogleFonts.oswald(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: accent,
                          ),
                        ),
                      ),
                    ),

                    // Member Name with Avatar
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: accent.withValues(alpha: 0.15),
                            child: Text(
                              m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : 'M',
                              style: GoogleFonts.oswald(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m.fullName,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                  if (m.isExpiringSoon) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        '⚠️ Exp in ${m.daysUntilExpiry}d',
                                        style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                m.email,
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Contact Phone
                    DataCell(
                      Text(
                        m.phone,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                    ),

                    // Membership Plan Badge
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          m.planName,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),

                    // Status Pill with Glowing Dot
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              m.statusDisplay,
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expiry Date with Calendar Icon
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: isExp ? Colors.redAccent : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${m.expiryDate.year}-${m.expiryDate.month.toString().padLeft(2, '0')}-${m.expiryDate.day.toString().padLeft(2, '0')}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isExp ? Colors.redAccent : Colors.white70,
                              fontWeight: isExp ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dues Tag
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: m.duesAmount > 0 ? Colors.redAccent.withValues(alpha: 0.15) : Colors.greenAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: m.duesAmount > 0 ? Colors.redAccent.withValues(alpha: 0.4) : Colors.greenAccent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          m.duesAmount > 0 ? 'PKR ${m.duesAmount.toStringAsFixed(0)} DUE' : 'PAID',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: m.duesAmount > 0 ? Colors.redAccent : Colors.greenAccent,
                          ),
                        ),
                      ),
                    ),

                    // Deep Telemetry: Workout Protocol
                    if (showDeepInsights) ...[
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fitness_center_rounded, size: 13, color: accent),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                '${m.assignedProtocol} (Day ${m.currentRoutineDay})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '🔥 ${m.currentStreakDays}D • ${m.totalCheckIns} visits',
                            style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            m.lastScanGate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],

                    // Actions Toolbar Capsule
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.isExpiringSoon)
                              IconButton(
                                icon: const Icon(Icons.send_rounded, size: 14),
                                color: Colors.greenAccent,
                                tooltip: 'Send WhatsApp Renewal Alert',
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                padding: EdgeInsets.zero,
                                onPressed: () => onSendReminder(m),
                              ),
                            IconButton(
                              icon: const Icon(Icons.key_rounded, size: 14),
                              color: accent,
                              tooltip: 'Manage Credentials / Password',
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              padding: EdgeInsets.zero,
                              onPressed: () => onManageCredentials(m),
                            ),
                            IconButton(
                              icon: Icon(
                                m.isFrozen ? Icons.play_circle_fill_rounded : Icons.pause_circle_outline_rounded,
                                size: 14,
                                color: m.isFrozen ? Colors.greenAccent : Colors.cyanAccent,
                              ),
                              tooltip: m.isFrozen ? 'Unfreeze Membership' : 'Freeze Membership (Leave)',
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              padding: EdgeInsets.zero,
                              onPressed: () => onToggleFreeze(m),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.white70),
                              tooltip: 'Edit Member',
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              padding: EdgeInsets.zero,
                              onPressed: () => onEdit(m),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                              tooltip: 'Remove Member',
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              padding: EdgeInsets.zero,
                              onPressed: () => onDelete(m),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

DataColumn _buildColumnHeader(IconData icon, String title) {
  return DataColumn(
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.9,
          ),
        ),
      ],
    ),
  );
}
}
