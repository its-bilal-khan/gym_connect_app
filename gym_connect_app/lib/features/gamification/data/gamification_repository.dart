import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/models.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(Supabase.instance.client);
});

/// Dedicated repository for daily 80% composite submissions, gate attendance checks, and logs.
class GamificationRepository {
  final SupabaseClient _client;

  GamificationRepository(this._client);

  /// Submits daily multi-sensor activity directly to the atomic backend RPC.
  Future<Map<String, dynamic>> submitDailyActivity({
    required String userId,
    required String tenantId,
    String? deviceId,
    int workoutAssignedSets = 0,
    int workoutCompletedSets = 0,
    int stepTarget = 10000,
    int stepActual = 0,
    String stepSource = 'live_pedometer',
    String dietLoggedType = 'none',
    String? dietProofUrl,
    double sleepLoggedHours = 0.0,
    String sleepSource = 'none',
    int sleepAsleepMinutes = 0,
  }) async {
    final response = await _client.rpc('rpc_submit_daily_activity', params: {
      'p_user_id': userId,
      'p_tenant_id': tenantId,
      'p_device_id': deviceId ?? 'unknown_device',
      'p_workout_assigned_sets': workoutAssignedSets,
      'p_workout_completed_sets': workoutCompletedSets,
      'p_step_target': stepTarget,
      'p_step_actual': stepActual,
      'p_step_source': stepSource,
      'p_diet_logged_type': dietLoggedType,
      'p_diet_proof_url': dietProofUrl,
      'p_sleep_logged_hours': sleepLoggedHours,
      'p_sleep_source': sleepSource,
      'p_sleep_asleep_minutes': sleepAsleepMinutes,
    });

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true, 'raw': response};
  }

  /// Fetches daily log for a specific date (defaults to today).
  Future<DailyGamificationLog?> getDailyLog(String userId, {String? logDate}) async {
    final targetDate = logDate ?? DateTime.now().toIso8601String().split('T').first;
    final res = await _client
        .from('daily_gamification_logs')
        .select()
        .eq('user_id', userId)
        .eq('log_date', targetDate)
        .maybeSingle();

    if (res == null) return null;
    return DailyGamificationLog.fromJson(res);
  }

  /// Fetches aggregate member gamification summary (points, streak, multipliers).
  Future<Map<String, dynamic>?> getMemberGamificationStats(String userId) async {
    final res = await _client
        .from('member_gamification')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return res;
  }

  /// Checks if physical gate attendance occurred today for anti-cheat verification.
  Future<bool> checkGateAttendance(String userId, String tenantId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final res = await _client
        .from('attendance_logs')
        .select('id')
        .eq('member_id', userId)
        .eq('tenant_id', tenantId)
        .gte('check_in_time', '$today 00:00:00')
        .eq('access_result', 'granted')
        .limit(1);

    return res.isNotEmpty;
  }

  /// Updates adaptive habit calibration when 3 consecutive misses occur.
  Future<void> autoCalibrateStepTarget({required String userId, required int newTarget}) async {
    await _client.from('user_fitness_profiles').update({
      'current_step_target': newTarget,
      'consecutive_target_misses': 0,
      'last_auto_calibrated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }
}
