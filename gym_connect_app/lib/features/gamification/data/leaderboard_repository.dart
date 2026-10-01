import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/models.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(Supabase.instance.client);
});

/// Dedicated repository for monthly races, Hall of Fame streaks, and archive ledgers.
class LeaderboardRepository {
  final SupabaseClient _client;

  LeaderboardRepository(this._client);

  /// Fetches current month race rankings (resets 1st of month) with zero mock data.
  Future<List<LeaderboardMember>> fetchActiveMonthlyLeaderboard({
    String? tenantId,
    int limit = 50,
  }) async {
    var query = _client
        .from('member_gamification')
        .select('user_id, monthly_points, total_points, current_streak_days, longest_streak_days, monthly_workouts_completed, streak_multiplier, is_elite_qualified, last_month_rank, profiles(id, full_name, avatar_url)');

    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.eq('tenant_id', tenantId);
    }

    final res = await query.order('monthly_points', ascending: false).limit(limit);
    final currentUserId = _client.auth.currentUser?.id;

    final list = res as List<dynamic>;
    return List.generate(list.length, (i) {
      final row = list[i] as Map<String, dynamic>;
      return LeaderboardMember.fromJson(row, currentUserId: currentUserId, calculatedRank: i + 1);
    });
  }

  /// Fetches Hall of Fame unbroken lifetime streaks.
  Future<List<LeaderboardMember>> fetchHallOfFameLifetimeStreaks({
    String? tenantId,
    int limit = 50,
  }) async {
    var query = _client
        .from('member_gamification')
        .select('user_id, monthly_points, total_points, current_streak_days, longest_streak_days, monthly_workouts_completed, streak_multiplier, is_elite_qualified, profiles(id, full_name, avatar_url)');

    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.eq('tenant_id', tenantId);
    }

    final res = await query.order('longest_streak_days', ascending: false).order('current_streak_days', ascending: false).limit(limit);
    final currentUserId = _client.auth.currentUser?.id;

    final list = res as List<dynamic>;
    return List.generate(list.length, (i) {
      final row = list[i] as Map<String, dynamic>;
      return LeaderboardMember.fromJson(row, currentUserId: currentUserId, calculatedRank: i + 1);
    });
  }

  /// Fetches past month podium archives and fulfillment history.
  Future<List<MonthlyPodiumArchive>> fetchMonthlyArchives({
    String? tenantId,
    String? monthYear,
  }) async {
    var query = _client
        .from('monthly_leaderboard_archives')
        .select('*, profiles(full_name)');

    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.eq('tenant_id', tenantId);
    }
    if (monthYear != null && monthYear.isNotEmpty) {
      query = query.eq('month_year', monthYear);
    }

    final res = await query.order('month_year', ascending: false).order('podium_rank', ascending: true);
    final list = res as List<dynamic>;
    return list.map((e) => MonthlyPodiumArchive.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetches custom podium rewards configured by gym owner.
  Future<TenantRewardConfig> fetchTenantRewardConfig(String tenantId) async {
    final res = await _client
        .from('tenants')
        .select('leaderboard_rewards, min_monthly_workouts_qualification, veteran_multiplier_config')
        .eq('id', tenantId)
        .maybeSingle();

    if (res == null) return const TenantRewardConfig();
    return TenantRewardConfig.fromJson(res);
  }
}
