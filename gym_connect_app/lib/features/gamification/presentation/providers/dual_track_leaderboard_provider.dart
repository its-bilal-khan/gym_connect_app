import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/models/models.dart';
import 'dual_track_leaderboard_state.dart';

final dualTrackLeaderboardProvider =
    NotifierProvider<DualTrackLeaderboardNotifier, DualTrackLeaderboardState>(
  DualTrackLeaderboardNotifier.new,
);

class DualTrackLeaderboardNotifier extends Notifier<DualTrackLeaderboardState> {
  LeaderboardRepository get _repo => ref.read(leaderboardRepositoryProvider);

  @override
  DualTrackLeaderboardState build() {
    Future.microtask(() => loadLeaderboardData());
    return const DualTrackLeaderboardState();
  }

  Future<void> loadLeaderboardData({String? tenantId, String? userId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final monthly = await _repo.fetchActiveMonthlyLeaderboard(tenantId: tenantId);
      final hallOfFame = await _repo.fetchHallOfFameLifetimeStreaks(tenantId: tenantId);
      final archives = await _repo.fetchMonthlyArchives(tenantId: tenantId);

      TenantRewardConfig rewardConfig = state.rewardConfig;
      if (tenantId != null && tenantId.isNotEmpty) {
        rewardConfig = await _repo.fetchTenantRewardConfig(tenantId);
      }

      Map<String, dynamic>? memberStatus;
      if (userId != null && tenantId != null) {
        memberStatus = await _repo.fetchMemberLeaderboardStatus(
          userId: userId,
          tenantId: tenantId,
        );
      }

      state = state.copyWith(
        monthlyMembers: monthly,
        hallOfFameMembers: hallOfFame,
        archives: archives,
        rewardConfig: rewardConfig,
        memberStatus: memberStatus,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setTrack(LeaderboardTrack track) {
    state = state.copyWith(activeTrack: track);
  }

  void setViewMode(LeaderboardViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectArchiveMonth(String? monthYear) {
    state = state.copyWith(selectedArchiveMonth: monthYear);
  }

  Future<void> refresh({String? tenantId, String? userId}) async {
    await loadLeaderboardData(tenantId: tenantId, userId: userId);
  }
}
