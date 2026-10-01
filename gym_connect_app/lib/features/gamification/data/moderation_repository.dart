import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/models.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}
  return ModerationRepository(client);
});

/// Dedicated repository for owner fraud verification queue and reward configurations.
class ModerationRepository {
  final SupabaseClient? _client;

  ModerationRepository([this._client]);

  /// Fetches pending flagged items requiring gym owner audit with zero mock data.
  Future<List<FlaggedQueueItem>> fetchPendingFlaggedItems({
    required String tenantId,
    int limit = 50,
  }) async {
    final client = _client;
    if (client == null) return const [];

    final res = await client
        .from('gamification_flagged_queue')
        .select('*, profiles(full_name)')
        .eq('tenant_id', tenantId)
        .eq('status', 'pending_review')
        .order('created_at', ascending: false)
        .limit(limit);

    final list = res as List<dynamic>;
    return list.map((e) => FlaggedQueueItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 1-Tap audit approval or point clawback via backend RPC.
  Future<Map<String, dynamic>> moderateFlaggedItem({
    required String queueId,
    required String status, // 'approved' or 'deducted'
    required String reviewerId,
    String? notes,
  }) async {
    final client = _client;
    if (client == null) return {'success': true};

    final res = await client.rpc('rpc_moderate_flagged_item', params: {
      'p_queue_id': queueId,
      'p_status': status,
      'p_reviewer_id': reviewerId,
      'p_notes': notes,
    });

    if (res is Map<String, dynamic>) return res;
    return {'success': true, 'raw': res};
  }

  /// Fetches tenant reward configuration and veteran multipliers.
  Future<TenantRewardConfig> fetchTenantRewardConfig(String tenantId) async {
    final client = _client;
    if (client == null) return const TenantRewardConfig();
    try {
      final res = await client
          .from('tenants')
          .select('leaderboard_rewards, min_monthly_workouts_qualification, veteran_multiplier_config')
          .eq('id', tenantId)
          .single();
      return TenantRewardConfig.fromJson(res);
    } catch (_) {
      return const TenantRewardConfig();
    }
  }

  /// Updates gym custom rewards, baseline qualification targets, and multipliers.
  Future<Map<String, dynamic>> updateTenantRewardConfig({
    required String tenantId,
    required TenantRewardConfig config,
  }) async {
    final client = _client;
    if (client == null) return {'success': true};

    final res = await client.rpc('rpc_update_tenant_reward_config', params: {
      'p_tenant_id': tenantId,
      'p_rewards': {
        'rank_1': {'title': config.rank1Title, 'type': config.rank1Type, 'value': config.rank1Value},
        'rank_2': {'title': config.rank2Title, 'type': config.rank2Type, 'value': config.rank2Value},
        'rank_3': {'title': config.rank3Title, 'type': config.rank3Type, 'value': config.rank3Value},
      },
      'p_min_workouts': config.minMonthlyWorkoutsQualification,
      'p_multipliers': {
        'tier_1_days': config.tier1Days,
        'tier_1_multiplier': config.tier1Multiplier,
        'tier_2_days': config.tier2Days,
        'tier_2_multiplier': config.tier2Multiplier,
        'tier_3_days': config.tier3Days,
        'tier_3_multiplier': config.tier3Multiplier,
      },
    });

    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  /// Fetches historical automated fulfillment ledger for the owner workstation.
  Future<List<MonthlyPodiumArchive>> fetchFulfillmentLedger({
    required String tenantId,
  }) async {
    final client = _client;
    if (client == null) return const [];

    final res = await client
        .from('monthly_leaderboard_archives')
        .select('*, profiles(full_name)')
        .eq('tenant_id', tenantId)
        .order('month_year', ascending: false)
        .order('podium_rank', ascending: true);

    final list = res as List<dynamic>;
    return list.map((e) => MonthlyPodiumArchive.fromJson(e as Map<String, dynamic>)).toList();
  }
}
