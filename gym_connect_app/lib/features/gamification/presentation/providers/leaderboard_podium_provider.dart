import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/models/models.dart';

/// Provider for active monthly leaderboard race (resets to 0 on 1st of month).
final activeMonthlyRaceProvider =
    FutureProvider.family<List<LeaderboardMember>, String?>((ref, tenantId) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchActiveMonthlyLeaderboard(tenantId: tenantId);
});

/// Provider for Hall of Fame unbroken lifetime streaks.
final hallOfFameStreakProvider =
    FutureProvider.family<List<LeaderboardMember>, String?>((ref, tenantId) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchHallOfFameLifetimeStreaks(tenantId: tenantId);
});

/// Provider for historical month archives and fulfillment records.
final monthlyArchivesProvider =
    FutureProvider.family<List<MonthlyPodiumArchive>, String?>((ref, tenantId) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchMonthlyArchives(tenantId: tenantId);
});

/// Provider for gym tenant custom podium reward configuration.
final tenantRewardConfigProvider =
    FutureProvider.family<TenantRewardConfig, String>((ref, tenantId) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchTenantRewardConfig(tenantId);
});
