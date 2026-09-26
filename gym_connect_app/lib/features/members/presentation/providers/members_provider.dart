import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/members_repository.dart';
import '../../domain/models/gym_member.dart';

enum MemberViewMode {
  grid,
  list,
  table,
}

class MembersFilterState {
  final String searchQuery;
  final String statusFilter;
  final String planFilter;
  final bool deepInsightsEnabled;
  final MemberViewMode viewMode;

  const MembersFilterState({
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.planFilter = 'all',
    this.deepInsightsEnabled = true,
    this.viewMode = MemberViewMode.table,
  });

  MembersFilterState copyWith({
    String? searchQuery,
    String? statusFilter,
    String? planFilter,
    bool? deepInsightsEnabled,
    MemberViewMode? viewMode,
  }) {
    return MembersFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      planFilter: planFilter ?? this.planFilter,
      deepInsightsEnabled: deepInsightsEnabled ?? this.deepInsightsEnabled,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

class MembersFilterNotifier extends Notifier<MembersFilterState> {
  @override
  MembersFilterState build() => const MembersFilterState();

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void setStatusFilter(String status) => state = state.copyWith(statusFilter: status);
  void setPlanFilter(String plan) => state = state.copyWith(planFilter: plan);
  void toggleDeepInsights() => state = state.copyWith(deepInsightsEnabled: !state.deepInsightsEnabled);
  void setViewMode(MemberViewMode mode) => state = state.copyWith(viewMode: mode);
}

final membersFilterProvider = NotifierProvider<MembersFilterNotifier, MembersFilterState>(
  MembersFilterNotifier.new,
);

class MembersState {
  final bool isLoading;
  final List<GymMember> allMembers;
  final String? errorMessage;
  final String? successMessage;

  const MembersState({
    this.isLoading = false,
    this.allMembers = const [],
    this.errorMessage,
    this.successMessage,
  });

  MembersState copyWith({
    bool? isLoading,
    List<GymMember>? allMembers,
    String? errorMessage,
    String? successMessage,
  }) {
    return MembersState(
      isLoading: isLoading ?? this.isLoading,
      allMembers: allMembers ?? this.allMembers,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class MembersNotifier extends Notifier<MembersState> {
  String _activeTenantId = '';

  @override
  MembersState build() {
    final authState = ref.watch(authNotifierProvider);
    String tid = '00000000-0000-0000-0000-000000000001';
    if (authState is AuthAuthenticated && authState.profile.tenantId != null && authState.profile.tenantId!.isNotEmpty) {
      final pTid = authState.profile.tenantId!.trim();
      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      if (uuidRegex.hasMatch(pTid)) {
        tid = pTid;
      }
    }
    _activeTenantId = tid;
    Future.microtask(() => loadMembers(_activeTenantId));
    return const MembersState(isLoading: true);
  }

  MembersRepository get _repo => ref.read(membersRepositoryProvider);

  String get currentTenantId => _activeTenantId;

  Future<void> loadMembers([String? tenantId]) async {
    final target = tenantId ?? _activeTenantId;
    if (target.isEmpty) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final members = await _repo.fetchMembers(tenantId: target);
      state = state.copyWith(isLoading: false, allMembers: members);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load members: $e');
    }
  }

  Future<bool> importBatch(List<GymMember> members, {String? tenantId}) async {
    final target = tenantId ?? _activeTenantId;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.importBatch(tenantId: target, members: members);
      final refreshed = await _repo.fetchMembers(tenantId: target);
      state = state.copyWith(
        isLoading: false,
        allMembers: refreshed,
        successMessage: 'Successfully ingested & synchronized ${members.length} members!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Import failed: $e');
      return false;
    }
  }

  Future<bool> addMember(GymMember member) async {
    try {
      final target = member.tenantId.isNotEmpty ? member.tenantId : _activeTenantId;
      final created = await _repo.createMember(tenantId: target, member: member);
      final deduped = state.allMembers.where((m) => m.id != created.id && m.memberCode != created.memberCode).toList();
      state = state.copyWith(
        allMembers: [created, ...deduped],
        successMessage: 'Member ${member.fullName} registered.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to register member: $e');
      return false;
    }
  }

  Future<bool> updateMember(GymMember member) async {
    try {
      final updated = await _repo.updateMember(member: member);
      final list = state.allMembers.map((m) => m.id == updated.id ? updated : m).toList();
      state = state.copyWith(
        allMembers: list,
        successMessage: 'Member ${member.fullName} updated.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update member: $e');
      return false;
    }
  }

  Future<bool> deleteMember(String memberId, {String? tenantId}) async {
    final target = tenantId ?? _activeTenantId;
    try {
      await _repo.deleteMember(tenantId: target, memberId: memberId);
      final list = state.allMembers.where((m) => m.id != memberId).toList();
      state = state.copyWith(allMembers: list, successMessage: 'Member removed.');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove member: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String memberId, String newPassword, {String? tenantId}) async {
    final target = tenantId ?? _activeTenantId;
    try {
      await _repo.resetPassword(tenantId: target, memberId: memberId, newPassword: newPassword);
      final list = state.allMembers.map((m) {
        if (m.id == memberId) return m.copyWith(tempPassword: newPassword);
        return m;
      }).toList();
      state = state.copyWith(allMembers: list, successMessage: 'Password successfully changed.');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reset password: $e');
      return false;
    }
  }

  /// Freezes or unfreezes membership to preserve active days
  Future<bool> toggleFreezeMembership(String memberId, {String? reason, String? tenantId}) async {
    final member = state.allMembers.firstWhere((m) => m.id == memberId, orElse: () => state.allMembers.first);
    final isCurrentlyFrozen = member.isFrozen;

    final updated = member.copyWith(
      status: isCurrentlyFrozen ? MemberAccountStatus.active : MemberAccountStatus.frozen,
      freezeReason: isCurrentlyFrozen ? null : (reason ?? 'Medical / Travel Leave'),
      updatedByStaff: 'Reception Desk (Status Toggle)',
    );

    return updateMember(updated);
  }

  /// Sends automated WhatsApp renewal reminder for expiring memberships
  Future<void> sendRenewalReminder(GymMember member) async {
    final phone = member.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final expDateStr = '${member.expiryDate.year}-${member.expiryDate.month.toString().padLeft(2, '0')}-${member.expiryDate.day.toString().padLeft(2, '0')}';
    final days = member.daysUntilExpiry;

    final msgText = Uri.encodeComponent(
      'Salam ${member.fullName}! This is a friendly reminder from Titan Fitness Club.\n'
      'Your gym membership (${member.planName}) is expiring in $days day(s) on $expDateStr.\n'
      'Please renew your plan to prevent interruption of your Dynamic QR turnstile gate pass & workout tracking!\n'
      'Titan Reception: +92-300-1234567',
    );

    final url = Uri.parse('https://wa.me/$phone?text=$msgText');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String exportMembersToCsv() {
    final headers = [
      'Member Code',
      'Full Name',
      'Phone',
      'Email',
      'Status',
      'Plan Name',
      'Join Date',
      'Expiry Date',
      'Pending Dues (PKR)',
      'Temp Password',
      'Assigned Protocol',
      'Streak Days',
      'Total CheckIns',
      'Last Gate Scan',
      'Updated By Staff',
    ];

    final rows = state.allMembers.map((m) {
      return [
        m.memberCode,
        '"${m.fullName}"',
        m.phone,
        m.email,
        m.statusDisplay,
        '"${m.planName}"',
        m.joinDate.toIso8601String().split('T').first,
        m.expiryDate.toIso8601String().split('T').first,
        m.duesAmount.toStringAsFixed(0),
        m.tempPassword,
        '"${m.assignedProtocol}"',
        m.currentStreakDays,
        m.totalCheckIns,
        '"${m.lastScanGate}"',
        '"${m.updatedByStaff}"',
      ].join(',');
    }).toList();

    return '${headers.join(',')}\n${rows.join('\n')}';
  }
}

final membersNotifierProvider = NotifierProvider<MembersNotifier, MembersState>(
  MembersNotifier.new,
);

final filteredMembersProvider = Provider<List<GymMember>>((ref) {
  final membersState = ref.watch(membersNotifierProvider);
  final filter = ref.watch(membersFilterProvider);

  return membersState.allMembers.where((member) {
    // Search query matching
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final matchName = member.fullName.toLowerCase().contains(q);
      final matchCode = member.memberCode.toLowerCase().contains(q);
      final matchPhone = member.phone.contains(q);
      final matchEmail = member.email.toLowerCase().contains(q);
      if (!matchName && !matchCode && !matchPhone && !matchEmail) return false;
    }

    // Status filter
    switch (filter.statusFilter) {
      case 'active':
        if (member.isExpired || member.isFrozen || member.status != MemberAccountStatus.active) return false;
        break;
      case 'overdue':
        if (!member.isDuesOverdue) return false;
        break;
      case 'frozen':
        if (!member.isFrozen) return false;
        break;
      case 'expiring_soon':
        if (!member.isExpiringSoon) return false;
        break;
      case 'expired':
        if (!member.isExpired) return false;
        break;
      default:
        break;
    }

    // Plan filter
    if (filter.planFilter != 'all') {
      if (!member.planName.toLowerCase().contains(filter.planFilter.toLowerCase())) return false;
    }

    return true;
  }).toList();
});

class MemberHubStats {
  final int totalCount;
  final int activeCount;
  final int overdueCount;
  final double totalOverdueDues;
  final int activeStreaksCount;
  final int frozenCount;
  final int expiringSoonCount;

  const MemberHubStats({
    required this.totalCount,
    required this.activeCount,
    required this.overdueCount,
    required this.totalOverdueDues,
    required this.activeStreaksCount,
    required this.frozenCount,
    required this.expiringSoonCount,
  });
}

final memberHubStatsProvider = Provider<MemberHubStats>((ref) {
  final members = ref.watch(membersNotifierProvider).allMembers;

  int active = 0;
  int overdue = 0;
  double duesSum = 0;
  int streaks = 0;
  int frozen = 0;
  int expiringSoon = 0;

  for (final m in members) {
    if (!m.isExpired && !m.isFrozen && m.status == MemberAccountStatus.active) {
      active++;
    }
    if (m.isDuesOverdue) {
      overdue++;
      duesSum += m.duesAmount;
    }
    if (m.hasActiveStreak) {
      streaks++;
    }
    if (m.isFrozen) {
      frozen++;
    }
    if (m.isExpiringSoon) {
      expiringSoon++;
    }
  }

  return MemberHubStats(
    totalCount: members.length,
    activeCount: active,
    overdueCount: overdue,
    totalOverdueDues: duesSum,
    activeStreaksCount: streaks,
    frozenCount: frozen,
    expiringSoonCount: expiringSoon,
  );
});
