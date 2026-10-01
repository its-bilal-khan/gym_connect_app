import '../../domain/models/models.dart';

enum LeaderboardTrack {
  monthlyRace,
  hallOfFame,
  podiumArchives,
}

enum LeaderboardViewMode {
  list,
  grid,
}

class DualTrackLeaderboardState {
  final LeaderboardTrack activeTrack;
  final LeaderboardViewMode viewMode;
  final String searchQuery;
  final String? selectedArchiveMonth;
  final List<LeaderboardMember> monthlyMembers;
  final List<LeaderboardMember> hallOfFameMembers;
  final List<MonthlyPodiumArchive> archives;
  final TenantRewardConfig rewardConfig;
  final Map<String, dynamic>? memberStatus;
  final bool isLoading;
  final String? errorMessage;

  const DualTrackLeaderboardState({
    this.activeTrack = LeaderboardTrack.monthlyRace,
    this.viewMode = LeaderboardViewMode.list,
    this.searchQuery = '',
    this.selectedArchiveMonth,
    this.monthlyMembers = const [],
    this.hallOfFameMembers = const [],
    this.archives = const [],
    this.rewardConfig = const TenantRewardConfig(),
    this.memberStatus,
    this.isLoading = false,
    this.errorMessage,
  });

  List<LeaderboardMember> get activeMembers {
    final list = activeTrack == LeaderboardTrack.monthlyRace ? monthlyMembers : hallOfFameMembers;
    if (searchQuery.trim().isEmpty) return list;
    final q = searchQuery.toLowerCase().trim();
    return list.where((m) => m.fullName.toLowerCase().contains(q)).toList();
  }

  List<LeaderboardMember> get podiumMembers {
    final list = activeMembers;
    return list.length >= 3 ? list.sublist(0, 3) : list;
  }

  List<LeaderboardMember> get runnersUpMembers {
    final list = activeMembers;
    return list.length > 3 ? list.sublist(3) : const [];
  }

  LeaderboardMember? get currentUserMember {
    final list = activeTrack == LeaderboardTrack.monthlyRace ? monthlyMembers : hallOfFameMembers;
    try {
      return list.firstWhere((m) => m.isCurrentUser);
    } catch (_) {
      return null;
    }
  }

  double get qualificationProgress {
    final completed = (memberStatus?['monthly_workouts_completed'] as num?)?.toInt() ?? 0;
    final required = rewardConfig.minMonthlyWorkoutsQualification;
    if (required <= 0) return 1.0;
    return (completed / required).clamp(0.0, 1.0);
  }

  bool get isQualified => (memberStatus?['is_qualified'] as bool?) ?? false;

  double get streakMultiplier => (memberStatus?['streak_multiplier'] as num?)?.toDouble() ?? 1.0;

  DualTrackLeaderboardState copyWith({
    LeaderboardTrack? activeTrack,
    LeaderboardViewMode? viewMode,
    String? searchQuery,
    String? selectedArchiveMonth,
    List<LeaderboardMember>? monthlyMembers,
    List<LeaderboardMember>? hallOfFameMembers,
    List<MonthlyPodiumArchive>? archives,
    TenantRewardConfig? rewardConfig,
    Map<String, dynamic>? memberStatus,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DualTrackLeaderboardState(
      activeTrack: activeTrack ?? this.activeTrack,
      viewMode: viewMode ?? this.viewMode,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedArchiveMonth: selectedArchiveMonth ?? this.selectedArchiveMonth,
      monthlyMembers: monthlyMembers ?? this.monthlyMembers,
      hallOfFameMembers: hallOfFameMembers ?? this.hallOfFameMembers,
      archives: archives ?? this.archives,
      rewardConfig: rewardConfig ?? this.rewardConfig,
      memberStatus: memberStatus ?? this.memberStatus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
