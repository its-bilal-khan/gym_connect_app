import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../domain/models/gym_member.dart';
import '../providers/members_provider.dart';
import '../widgets/add_edit_member_dialog.dart';
import '../widgets/excel_import_dialog.dart';
import '../widgets/freeze_membership_dialog.dart';
import '../widgets/member_credentials_dialog.dart';
import '../widgets/member_data_table.dart';
import '../widgets/member_empty_state_card.dart';
import '../widgets/member_grid_card.dart';
import '../widgets/member_list_card.dart';

class DesktopMemberHubScreen extends ConsumerStatefulWidget {
  final UserProfile profile;

  const DesktopMemberHubScreen({super.key, required this.profile});

  static void open(BuildContext context, {required UserProfile profile}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DesktopMemberHubScreen(profile: profile),
      ),
    );
  }

  @override
  ConsumerState<DesktopMemberHubScreen> createState() => _DesktopMemberHubScreenState();
}

class _DesktopMemberHubScreenState extends ConsumerState<DesktopMemberHubScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onExportCsv() {
    final csv = ref.read(membersNotifierProvider.notifier).exportMembersToCsv();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtered member roster exported and copied to clipboard as CSV!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _confirmDelete(GymMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Member?', style: GoogleFonts.oswald(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove ${member.fullName} (${member.memberCode}) from the gym roster?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(membersNotifierProvider.notifier).deleteMember(member.id);
              Navigator.of(ctx).pop();
            },
            child: Text('Remove', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final tenantId = widget.profile.tenantId ?? '';

    final filterState = ref.watch(membersFilterProvider);
    final filterNotifier = ref.read(membersFilterProvider.notifier);
    final membersState = ref.watch(membersNotifierProvider);
    final filteredMembers = ref.watch(filteredMembersProvider);
    final stats = ref.watch(memberHubStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(accent, membersState.allMembers),
            Expanded(
              child: membersState.isLoading
                  ? Center(child: CircularProgressIndicator(color: accent))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsRow(stats, accent),
                          const SizedBox(height: 18),
                          _buildQuickStatusTabs(filterState.statusFilter, filterNotifier, stats, accent),
                          const SizedBox(height: 14),
                          _buildMasterToolbar(filterState, filterNotifier, tenantId, accent),
                          const SizedBox(height: 18),
                          _buildViewContent(filterState, filteredMembers, tenantId),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Color accent, List<GymMember> allMembers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back to Executive Overview',
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.groups_rounded, color: accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MEMBERS DIRECTORY & EXCEL INGESTION HUB [DESKTOP]',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white),
                      ),
                      Text(
                        'Batch spreadsheet ingestion, credential generation, and deep workout diagnostics',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text('Export CSV', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: _onExportCsv,
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: Text('Excel / CSV Ingestion', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ExcelImportDialog.show(
                    context,
                    tenantId: widget.profile.tenantId ?? '',
                    existingMembers: allMembers,
                    onConfirmImport: (validMembers) async {
                      final success = await ref.read(membersNotifierProvider.notifier).importBatch(validMembers, tenantId: widget.profile.tenantId ?? '');
                      if (!mounted) return;
                      final mState = ref.read(membersNotifierProvider);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    mState.successMessage ?? 'Successfully synchronized ${validMembers.length} members with roster!',
                                    style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: accent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    mState.errorMessage ?? 'Import notice: Could not complete spreadsheet ingestion.',
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 6),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(MemberHubStats stats, Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildStatCard('TOTAL MEMBERS', '${stats.totalCount}', Icons.groups_rounded, Colors.white, 'Registered roster'),
          _buildStatCard('ACTIVE PASSES', '${stats.activeCount}', Icons.verified_user_rounded, Colors.greenAccent, 'Valid & Unlocked'),
          _buildStatCard('EXPIRING SOON', '${stats.expiringSoonCount}', Icons.warning_amber_rounded, Colors.orangeAccent, 'Within 7 days'),
          _buildStatCard('OVERDUE DUES', 'PKR ${stats.totalOverdueDues.toStringAsFixed(0)}', Icons.money_off_rounded, Colors.redAccent, '${stats.overdueCount} pending dues'),
          _buildStatCard('FROZEN (ON LEAVE)', '${stats.frozenCount}', Icons.pause_circle_outline_rounded, Colors.cyanAccent, 'Days preserved'),
        ];

        // Responsive wrap when screen width is constrained
        if (constraints.maxWidth < 1050) {
          final itemWidth = constraints.maxWidth < 600
              ? constraints.maxWidth
              : constraints.maxWidth < 850
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 24) / 3;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
          );
        }

        return Row(
          children: cards.asMap().entries.map((entry) {
            final isLast = entry.key == cards.length - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 12),
                child: entry.value,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusTabs(
    String currentStatus,
    MembersFilterNotifier notifier,
    MemberHubStats stats,
    Color accent,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatusTab('all', 'ALL MEMBERS (${stats.totalCount})', currentStatus, notifier, accent),
          const SizedBox(width: 8),
          _buildStatusTab('active', 'ACTIVE (${stats.activeCount})', currentStatus, notifier, Colors.greenAccent),
          const SizedBox(width: 8),
          _buildStatusTab('expiring_soon', '⚠️ EXPIRING SOON (${stats.expiringSoonCount})', currentStatus, notifier, Colors.orangeAccent),
          const SizedBox(width: 8),
          _buildStatusTab('overdue', 'OVERDUE DUES (${stats.overdueCount})', currentStatus, notifier, Colors.redAccent),
          const SizedBox(width: 8),
          _buildStatusTab('frozen', 'FROZEN / ON LEAVE (${stats.frozenCount})', currentStatus, notifier, Colors.cyanAccent),
          const SizedBox(width: 8),
          _buildStatusTab('expired', 'EXPIRED PASSES', currentStatus, notifier, Colors.white54),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String statusKey, String label, String currentStatus, MembersFilterNotifier notifier, Color color) {
    final isSelected = currentStatus == statusKey;

    return InkWell(
      onTap: () => notifier.setStatusFilter(statusKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMasterToolbar(
    MembersFilterState filter,
    MembersFilterNotifier notifier,
    String tenantId,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: notifier.setSearchQuery,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by member code, name, phone, or email...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white30),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: accent.withValues(alpha: 0.3))),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: Text('Register Member', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  AddEditMemberDialog.show(
                    context,
                    tenantId: tenantId,
                    onSave: (member) {
                      ref.read(membersNotifierProvider.notifier).addMember(member);
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 820;

              final insightsWidget = InkWell(
                onTap: notifier.toggleDeepInsights,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: filter.deepInsightsEnabled ? accent.withValues(alpha: 0.12) : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: filter.deepInsightsEnabled ? accent.withValues(alpha: 0.5) : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        size: 16,
                        color: filter.deepInsightsEnabled ? accent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '360° DETAILED MODE (Workout Split, Streak, Gate Access Logs)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: filter.deepInsightsEnabled ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Switch(
                        value: filter.deepInsightsEnabled,
                        activeThumbColor: accent,
                        onChanged: (_) => notifier.toggleDeepInsights(),
                      ),
                    ],
                  ),
                ),
              );

              final viewModesWidget = Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewButton(Icons.table_chart_rounded, 'Data Grid (Table)', MemberViewMode.table, filter.viewMode, notifier, accent),
                    _buildViewButton(Icons.view_list_rounded, 'Density List', MemberViewMode.list, filter.viewMode, notifier, accent),
                    _buildViewButton(Icons.grid_view_rounded, 'Cards', MemberViewMode.grid, filter.viewMode, notifier, accent),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    insightsWidget,
                    viewModesWidget,
                  ],
                );
              }

              return SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    insightsWidget,
                    viewModesWidget,
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(
    IconData icon,
    String label,
    MemberViewMode mode,
    MemberViewMode currentMode,
    MembersFilterNotifier notifier,
    Color accent,
  ) {
    final isSelected = mode == currentMode;
    return InkWell(
      onTap: () => notifier.setViewMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? accent : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? accent : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewContent(
    MembersFilterState filter,
    List<GymMember> members,
    String tenantId,
  ) {
    final notifier = ref.read(membersNotifierProvider.notifier);
    final allMembers = ref.watch(membersNotifierProvider).allMembers;

    // 1. If database has zero members at all, show the high-conversion Ingestion Empty State
    if (allMembers.isEmpty) {
      return MemberEmptyStateCard(
        onUploadExcel: () {
          ExcelImportDialog.show(
            context,
            tenantId: tenantId,
            existingMembers: allMembers,
            onConfirmImport: (validMembers) async {
              final success = await ref.read(membersNotifierProvider.notifier).importBatch(validMembers, tenantId: tenantId);
              if (!mounted) return;
              final mState = ref.read(membersNotifierProvider);
              final accent = Theme.of(context).colorScheme.primary;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      mState.successMessage ?? 'Successfully synchronized ${validMembers.length} members with database!',
                      style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: accent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      mState.errorMessage ?? 'Database sync failed. Please ensure "supabase_run_bulk_member_ingestion.sql" has been run in Supabase SQL Editor.',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 8),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
          );
        },
        onAddMember: () {
          AddEditMemberDialog.show(
            context,
            tenantId: tenantId,
            onSave: (member) {
              ref.read(membersNotifierProvider.notifier).addMember(member);
            },
          );
        },
      );
    }

    // 2. If members exist in database but search/filter returned 0 results
    if (members.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              'NO MEMBERS MATCH CURRENT FILTERS',
              style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'No member found for query "${filter.searchQuery}" or status "${filter.statusFilter}".',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.border)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Reset Filters & Search', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: () {
                _searchCtrl.clear();
                ref.read(membersFilterProvider.notifier).setSearchQuery('');
                ref.read(membersFilterProvider.notifier).setStatusFilter('all');
              },
            ),
          ],
        ),
      );
    }

    // 3. Render Table, Density List, or ID Cards Grid
    if (filter.viewMode == MemberViewMode.table) {
      return MemberDataTable(
        members: members,
        showDeepInsights: filter.deepInsightsEnabled,
        onEdit: (m) => AddEditMemberDialog.show(
          context,
          tenantId: tenantId,
          initialMember: m,
          onSave: (updated) => notifier.updateMember(updated),
        ),
        onDelete: _confirmDelete,
        onManageCredentials: (m) => MemberCredentialsDialog.show(
          context,
          member: m,
          onSavePassword: (pass) => notifier.resetPassword(m.id, pass),
        ),
        onToggleFreeze: (m) => FreezeMembershipDialog.show(
          context,
          member: m,
          onConfirm: (reason) => notifier.toggleFreezeMembership(m.id, reason: reason),
        ),
        onSendReminder: (m) => notifier.sendRenewalReminder(m),
      );
    } else if (filter.viewMode == MemberViewMode.list) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final m = members[index];
          return MemberListCard(
            member: m,
            showDeepInsights: filter.deepInsightsEnabled,
            onEdit: () => AddEditMemberDialog.show(
              context,
              tenantId: tenantId,
              initialMember: m,
              onSave: (updated) => notifier.updateMember(updated),
            ),
            onDelete: () => _confirmDelete(m),
            onManageCredentials: () => MemberCredentialsDialog.show(
              context,
              member: m,
              onSavePassword: (pass) => notifier.resetPassword(m.id, pass),
            ),
            onToggleFreeze: () => FreezeMembershipDialog.show(
              context,
              member: m,
              onConfirm: (reason) => notifier.toggleFreezeMembership(m.id, reason: reason),
            ),
            onSendReminder: () => notifier.sendRenewalReminder(m),
          );
        },
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Authentic Physical Plastic ID Badges (Portrait: 260 width x 420 height)
          final crossAxisCount = (constraints.maxWidth / 280).floor().clamp(1, 6);
          final totalGaps = (crossAxisCount - 1) * 20.0;
          final cardWidth = (constraints.maxWidth - totalGaps) / crossAxisCount;
          const desiredHeight = 430.0;
          final calculatedAspectRatio = (cardWidth / desiredHeight).clamp(0.58, 0.68);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: calculatedAspectRatio,
            ),
            itemBuilder: (context, index) {
              final m = members[index];
              return MemberGridCard(
                member: m,
                showDeepInsights: filter.deepInsightsEnabled,
                onEdit: () => AddEditMemberDialog.show(
                  context,
                  tenantId: tenantId,
                  initialMember: m,
                  onSave: (updated) => notifier.updateMember(updated),
                ),
                onDelete: () => _confirmDelete(m),
                onManageCredentials: () => MemberCredentialsDialog.show(
                  context,
                  member: m,
                  onSavePassword: (pass) => notifier.resetPassword(m.id, pass),
                ),
                onToggleFreeze: () => FreezeMembershipDialog.show(
                  context,
                  member: m,
                  onConfirm: (reason) => notifier.toggleFreezeMembership(m.id, reason: reason),
                ),
                onSendReminder: () => notifier.sendRenewalReminder(m),
              );
            },
          );
        },
      );
    }
  }
}
