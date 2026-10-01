import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/models.dart';

final fraudModerationRepositoryProvider = Provider<FraudModerationRepository>((ref) {
  return FraudModerationRepository(Supabase.instance.client);
});

/// Dedicated repository for owner fraud audit queues, point clawbacks, and reels moderation.
class FraudModerationRepository {
  final SupabaseClient _client;

  FraudModerationRepository(this._client);

  /// Fetches items in flagged queue for review (e.g. wall photos, manual overrides).
  Future<List<FlaggedQueueItem>> fetchFlaggedQueue({
    required String tenantId,
    String status = 'pending_review',
    int limit = 50,
  }) async {
    final res = await _client
        .from('gamification_flagged_queue')
        .select('*, profiles(id, full_name)')
        .eq('tenant_id', tenantId)
        .eq('status', status)
        .order('created_at', ascending: false)
        .limit(limit);

    final list = res as List<dynamic>;
    return list.map((e) => FlaggedQueueItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Executes atomic point clawback or approves flagged proof.
  Future<Map<String, dynamic>> clawbackFlaggedPoints({
    required String queueId,
    required String reviewerId,
    required bool deductPoints,
    String reason = 'Proof rejected by gym owner',
  }) async {
    final res = await _client.rpc('rpc_clawback_flagged_points', params: {
      'p_queue_id': queueId,
      'p_reviewer_id': reviewerId,
      'p_deduct_points': deductPoints,
      'p_reason': reason,
    });

    if (res is Map<String, dynamic>) return res;
    return {'success': true, 'raw': res};
  }

  /// Fetches approved public micro-reels for Explore feed.
  Future<List<WorkoutMicroReel>> fetchExploreReels({
    String? tenantId,
    int limit = 30,
  }) async {
    var query = _client
        .from('member_workout_reels')
        .select('*, profiles(full_name)')
        .eq('is_public_explore', true)
        .eq('is_flagged', false);

    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.eq('tenant_id', tenantId);
    }

    final res = await query.order('created_at', ascending: false).limit(limit);
    final list = res as List<dynamic>;
    return list.map((e) => WorkoutMicroReel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
