import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/members/domain/models/gym_member.dart';
import 'package:gym_connect_app/features/members/presentation/providers/members_provider.dart';

/// 1:1 exact replica of Desktop Members Directory Hub screen matching user screenshot.
class MiniMemberTablePreview extends ConsumerWidget {
  final String tenantId;

  const MiniMemberTablePreview({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final membersState = ref.watch(membersNotifierProvider);
    final members = membersState.allMembers;
    final filter = ref.watch(membersFilterProvider);
    final currentViewMode = filter.viewMode;
    final totalCount = members.isNotEmpty ? members.length : 3;
    final activeCount = members.isNotEmpty
        ? members.where((m) => m.status == MemberAccountStatus.active).length
        : 2;

    // Use live members if available, or populate with authentic members from screenshot
    final member1Name = members.isNotEmpty ? members[0].fullName : 'Hamza Tariq';
    final member1Code = members.isNotEmpty ? members[0].memberCode : 'GC-M-1011';
    final member2Name = members.length > 1 ? members[1].fullName : 'Bilal Ahmed';
    final member2Code = members.length > 1 ? members[1].memberCode : 'GC-M-1012';
    final member3Name = members.length > 2 ? members[2].fullName : 'user';
    final member3Code = members.length > 2 ? members[2].memberCode : 'GC-M-B721';

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Container(
          width: 1024,
          height: 492,
          color: const Color(0xFF09090B),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header: Back, Title, Subtitle, Export CSV & Ingestion
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141418),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 11, color: Colors.white70),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'MEMBERS DIRECTORY & EXCEL INGESTION HUB [DESKTOP]',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.oswald(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      'ROSTER: $totalCount ($activeCount ACTIVE)',
                                      style: GoogleFonts.inter(fontSize: 7.2, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Batch spreadsheet ingestion, credential generation, and deep workout diagnostics',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 7.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.download_rounded, size: 9, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text('Export CSV', style: GoogleFonts.inter(fontSize: 8, color: Colors.white70, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.upload_file_rounded, size: 9, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'EXCEL IMPORT',
                              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. The 5 Stat Cards across the full width
              Row(
                children: [
                  _buildStatCard('TOTAL MEMBERS', '$totalCount', Icons.groups_rounded, Colors.white, 'Registered roster'),
                  const SizedBox(width: 8),
                  _buildStatCard('ACTIVE PASSES', '$activeCount', Icons.verified_user_rounded, Colors.greenAccent, 'Valid & Unlocked'),
                  const SizedBox(width: 8),
                  _buildStatCard('EXPIRING SOON', '0', Icons.warning_amber_rounded, Colors.orangeAccent, 'Within 7 days'),
                  const SizedBox(width: 8),
                  _buildStatCard('OVERDUE DUES', 'PKR 5000', Icons.money_off_rounded, Colors.redAccent, '1 pending dues'),
                  const SizedBox(width: 8),
                  _buildStatCard('FROZEN (ON LEAVE)', '0', Icons.pause_circle_outline_rounded, Colors.cyanAccent, 'Days preserved'),
                ],
              ),
              const SizedBox(height: 8),

              // 3. Quick Status Filter Tabs
              Row(
                children: [
                  _buildFilterTab('ALL MEMBERS ($totalCount)', isActive: true, accent: accent),
                  const SizedBox(width: 5),
                  _buildFilterTab('ACTIVE ($activeCount)', isActive: false, accent: accent),
                  const SizedBox(width: 5),
                  _buildFilterTab('EXPIRING SOON (0)', isActive: false, accent: accent),
                  const SizedBox(width: 5),
                  _buildFilterTab('OVERDUE DUES (1)', isActive: false, accent: accent),
                  const SizedBox(width: 5),
                  _buildFilterTab('FROZEN / ON LEAVE (0)', isActive: false, accent: accent),
                  const SizedBox(width: 5),
                  _buildFilterTab('EXPIRED PASSES', isActive: false, accent: accent),
                ],
              ),
              const SizedBox(height: 8),

              // 4. Search Bar, 360 Toggle, View Switcher & Register Member
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 11, color: Colors.white54),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Search by member code, name, phone, or email...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 8, color: Colors.white38),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('360° DETAILED MODE (Workout Split, Streak, Gate Access Logs)', style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8))),
                        const SizedBox(width: 5),
                        Container(
                          width: 20,
                          height: 11,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.5), color: const Color(0xFF2563EB)),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(width: 9, height: 9, margin: const EdgeInsets.all(1), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // View Switcher: Data Grid (Table), Density List, Cards
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: currentViewMode == MemberViewMode.table
                                    ? BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(3))
                                    : null,
                                child: Row(
                                  children: [
                                    Icon(Icons.table_chart_rounded, size: 8, color: currentViewMode == MemberViewMode.table ? Colors.white : Colors.white60),
                                    const SizedBox(width: 2),
                                    Text('TABLE', style: GoogleFonts.inter(fontSize: 6.8, color: currentViewMode == MemberViewMode.table ? Colors.white : Colors.white60, fontWeight: currentViewMode == MemberViewMode.table ? FontWeight.bold : FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: currentViewMode == MemberViewMode.list
                                    ? BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(3))
                                    : null,
                                child: Row(
                                  children: [
                                    Icon(Icons.view_headline_rounded, size: 8, color: currentViewMode == MemberViewMode.list ? Colors.white : Colors.white60),
                                    const SizedBox(width: 2),
                                    Text('Density List', style: GoogleFonts.inter(fontSize: 6.8, color: currentViewMode == MemberViewMode.list ? Colors.white : Colors.white60, fontWeight: currentViewMode == MemberViewMode.list ? FontWeight.bold : FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: currentViewMode == MemberViewMode.grid
                                    ? BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(3))
                                    : null,
                                child: Row(
                                  children: [
                                    Icon(Icons.badge_rounded, size: 8, color: currentViewMode == MemberViewMode.grid ? Colors.white : Colors.white60),
                                    const SizedBox(width: 2),
                                    Text('Cards', style: GoogleFonts.inter(fontSize: 6.8, color: currentViewMode == MemberViewMode.grid ? Colors.white : Colors.white60, fontWeight: currentViewMode == MemberViewMode.grid ? FontWeight.bold : FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_add_rounded, size: 9, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 2),
                              Text('Register Member', style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 5. Dynamic Content: Table View vs Density List View vs Cards View
              Expanded(
                child: currentViewMode == MemberViewMode.table
                    ? _buildMiniTableView(members, accent)
                    : currentViewMode == MemberViewMode.list
                        ? _buildMiniListView(members, accent)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Member Card #1: Hamza Tariq (GC-M-1011)
                              SizedBox(
                                width: 155,
                                child: _buildExactMemberCard(
                                  initial: member1Name.isNotEmpty ? member1Name[0].toUpperCase() : 'H',
                                  name: member1Name,
                                  code: member1Code,
                                  tier: 'ANNUAL VIP',
                                  status: 'ACTIVE',
                                  expiry: 'Exp: 2027-01-15 • PAID',
                                  telemetry: '10 Streak • Mesomorphic Athletic Power & V-...',
                                  tierColor: const Color(0xFFFFC107),
                                  isActive: true,
                                  accent: accent,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Member Card #2: Bilal Ahmed (GC-M-1012)
                              SizedBox(
                                width: 155,
                                child: _buildExactMemberCard(
                                  initial: member2Name.isNotEmpty ? member2Name[0].toUpperCase() : 'B',
                                  name: member2Name,
                                  code: member2Code,
                                  tier: 'MONTHLY FITNESS',
                                  status: 'EXPIRED',
                                  expiry: 'Exp: 2026-03-01 • PAID',
                                  telemetry: '12 Streak • Ectomorph: Lean Bulk Meso',
                                  tierColor: const Color(0xFF00E5FF),
                                  isActive: false,
                                  accent: accent,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Member Card #3: user (GC-M-B721)
                              SizedBox(
                                width: 155,
                                child: _buildExactMemberCard(
                                  initial: member3Name.isNotEmpty ? member3Name[0].toUpperCase() : 'U',
                                  name: member3Name,
                                  code: member3Code,
                                  tier: 'ANNUAL VIP',
                                  status: 'ACTIVE',
                                  expiry: 'Exp: 2027-01-26 • PKR 5000 DUE',
                                  telemetry: '08 Streak • Mesomorph: Athletic Power & V-...',
                                  tierColor: const Color(0xFFFFC107),
                                  isActive: true,
                                  isDuesOverdue: true,
                                  accent: accent,
                                ),
                              ),

                              const Spacer(),
                            ],
                          ),
              ),
            ],
          ),
        );

        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: 1024,
            height: 492,
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4.5),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 6.2, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  Text(val, style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(sub, style: GoogleFonts.inter(fontSize: 5.8, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, {required bool isActive, required Color accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E293B) : const Color(0xFF141418),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isActive ? const Color(0xFF38BDF8) : Colors.white12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 6.8,
          fontWeight: FontWeight.bold,
          color: isActive ? const Color(0xFF38BDF8) : Colors.white60,
        ),
      ),
    );
  }

  Widget _buildExactMemberCard({
    required String initial,
    required String name,
    required String code,
    required String tier,
    required String status,
    required String expiry,
    required String telemetry,
    required Color tierColor,
    required bool isActive,
    bool isDuesOverdue = false,
    required Color accent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16161B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? tierColor.withValues(alpha: 0.4) : const Color(0xFFEF4444).withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lanyard Hole Header with GYMCONNECT & 3-dots
          Container(
            height: 15,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 7.5, color: tierColor),
                    const SizedBox(width: 2),
                    Text('GYMCONNECT', style: GoogleFonts.oswald(fontSize: 6.5, fontWeight: FontWeight.bold, color: tierColor)),
                  ],
                ),
                Container(width: 14, height: 2.5, decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(1))),
                const Icon(Icons.more_vert_rounded, size: 8, color: Colors.white54),
              ],
            ),
          ),

          // Card Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: tierColor.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: tierColor),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.oswald(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(2.5)),
                        child: Text(
                          code,
                          style: GoogleFonts.jetBrainsMono(fontSize: 6.5, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                        ),
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.8),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(fontSize: 5.5, fontWeight: FontWeight.bold, color: isActive ? Colors.greenAccent : Colors.redAccent),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.8),
                          decoration: BoxDecoration(color: tierColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                          child: Text(
                            tier,
                            style: GoogleFonts.inter(fontSize: 5.5, fontWeight: FontWeight.bold, color: tierColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    expiry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 5.8, color: isDuesOverdue ? Colors.redAccent : Colors.white60, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    telemetry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 5.2, color: AppColors.textSecondary),
                  ),
                  // Barcode
                  Text(
                    'RFID PASS - $code',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(fontSize: 4.5, color: Colors.white30, letterSpacing: 0.2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTableView(List<GymMember> members, Color accent) {
    final items = _resolveMiniItems(members);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111116),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF18181E),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('MEMBER', style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white70))),
                Expanded(flex: 2, child: Text('TIER & PLAN', style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white70))),
                Expanded(flex: 2, child: Text('STATUS', style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white70))),
                Expanded(flex: 2, child: Text('EXPIRY / DUES', style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white70))),
                Expanded(flex: 3, child: Text('TELEMETRY / PROTOCOL', style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white70))),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.04)),
              itemBuilder: (context, i) {
                final m = items[i];
                return Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Member info
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: accent.withValues(alpha: 0.2),
                              child: Text(
                                m.name.isNotEmpty ? m.name[0].toUpperCase() : 'M',
                                style: GoogleFonts.oswald(fontSize: 9, fontWeight: FontWeight.bold, color: accent),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text(m.code, style: GoogleFonts.jetBrainsMono(fontSize: 6.8, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tier
                      Expanded(
                        flex: 2,
                        child: Text(m.tier, style: GoogleFonts.inter(fontSize: 7.8, color: m.tierColor, fontWeight: FontWeight.w600)),
                      ),
                      // Status
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: m.isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: m.isActive ? Colors.greenAccent : Colors.redAccent, width: 0.6),
                            ),
                            child: Text(
                              m.status,
                              style: GoogleFonts.inter(fontSize: 6.5, fontWeight: FontWeight.bold, color: m.isActive ? Colors.greenAccent : Colors.redAccent),
                            ),
                          ),
                        ),
                      ),
                      // Expiry / Dues
                      Expanded(
                        flex: 2,
                        child: Text('${m.expiry} • ${m.dues}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 7.2, color: m.isDuesOverdue ? Colors.redAccent : Colors.white70)),
                      ),
                      // Telemetry
                      Expanded(
                        flex: 3,
                        child: Text(m.telemetry, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 7.2, color: const Color(0xFF38BDF8))),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniListView(List<GymMember> members, Color accent) {
    final items = _resolveMiniItems(members);
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final m = items[i];
        return Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: accent.withValues(alpha: 0.2),
                child: Text(
                  m.name.isNotEmpty ? m.name[0].toUpperCase() : 'M',
                  style: GoogleFonts.oswald(fontSize: 9, fontWeight: FontWeight.bold, color: accent),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(m.code, style: GoogleFonts.jetBrainsMono(fontSize: 6.8, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: m.isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  m.status,
                  style: GoogleFonts.inter(fontSize: 6.5, fontWeight: FontWeight.bold, color: m.isActive ? Colors.greenAccent : Colors.redAccent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Text(m.tier, style: GoogleFonts.inter(fontSize: 7.8, color: m.tierColor, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                flex: 2,
                child: Text(m.expiry, style: GoogleFonts.inter(fontSize: 7.2, color: Colors.white70)),
              ),
              Text(m.telemetry, style: GoogleFonts.inter(fontSize: 7.2, color: const Color(0xFF38BDF8))),
            ],
          ),
        );
      },
    );
  }

  List<_MiniMemberRowData> _resolveMiniItems(List<GymMember> members) {
    if (members.isNotEmpty) {
      return members.take(4).map((m) {
        final isActive = m.status == MemberAccountStatus.active;
        final isOverdue = m.duesStatus == MemberDuesStatus.overdue;
        final isVip = m.planName.toLowerCase().contains('vip');
        return _MiniMemberRowData(
          name: m.fullName,
          code: m.memberCode,
          tier: m.planName.toUpperCase(),
          status: isActive ? 'ACTIVE' : (isOverdue ? 'OVERDUE' : 'EXPIRED'),
          expiry: 'Exp: ${m.expiryDate.toIso8601String().substring(0, 10)}',
          dues: isOverdue ? 'PKR ${m.duesAmount.toStringAsFixed(0)} DUE' : 'PAID',
          telemetry: '${m.currentStreakDays} Streak • ${m.assignedProtocol.isNotEmpty ? m.assignedProtocol : m.targetGoal}',
          isActive: isActive,
          isDuesOverdue: isOverdue,
          tierColor: isVip ? const Color(0xFFFFC107) : const Color(0xFF00E5FF),
        );
      }).toList();
    }
    return const [
      _MiniMemberRowData(
        name: 'Hamza Tariq',
        code: 'GC-M-1011',
        tier: 'ANNUAL VIP',
        status: 'ACTIVE',
        expiry: 'Exp: 2027-01-15',
        dues: 'PAID',
        telemetry: '10 Streak • Mesomorphic Athletic Power & V-...',
        isActive: true,
        isDuesOverdue: false,
        tierColor: Color(0xFFFFC107),
      ),
      _MiniMemberRowData(
        name: 'Bilal Ahmed',
        code: 'GC-M-1012',
        tier: 'MONTHLY FITNESS',
        status: 'EXPIRED',
        expiry: 'Exp: 2026-03-01',
        dues: 'PAID',
        telemetry: '12 Streak • Ectomorph: Lean Bulk Meso',
        isActive: false,
        isDuesOverdue: false,
        tierColor: Color(0xFF00E5FF),
      ),
      _MiniMemberRowData(
        name: 'user',
        code: 'GC-M-B721',
        tier: 'ANNUAL VIP',
        status: 'ACTIVE',
        expiry: 'Exp: 2027-01-26',
        dues: 'PKR 5000 DUE',
        telemetry: '08 Streak • Mesomorph: Athletic Power & V-...',
        isActive: true,
        isDuesOverdue: true,
        tierColor: Color(0xFFFFC107),
      ),
    ];
  }
}

class _MiniMemberRowData {
  final String name;
  final String code;
  final String tier;
  final String status;
  final String expiry;
  final String dues;
  final String telemetry;
  final bool isActive;
  final bool isDuesOverdue;
  final Color tierColor;

  const _MiniMemberRowData({
    required this.name,
    required this.code,
    required this.tier,
    required this.status,
    required this.expiry,
    required this.dues,
    required this.telemetry,
    required this.isActive,
    required this.isDuesOverdue,
    required this.tierColor,
  });
}

