import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/models.dart';

final exploreReelsRepositoryProvider = Provider<ExploreReelsRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}
  return ExploreReelsRepository(client);
});

/// Dedicated repository for Explore Feed video reels, uploads, and likes.
class ExploreReelsRepository {
  final SupabaseClient? _client;

  ExploreReelsRepository([this._client]);

  /// Fetches public, unflagged reels from live database with zero mock data.
  Future<List<WorkoutMicroReel>> fetchExploreReels({
    String? tenantId,
    int limit = 30,
  }) async {
    final client = _client;
    if (client == null) return const [];

    var query = client
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

  /// Uploads video bytes to the workout_reels storage bucket.
  Future<String?> uploadVideoFile({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final client = _client;
    if (client == null) return null;

    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final path = '$userId/$fileName';

    await client.storage.from('workout_reels').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'video/mp4', upsert: true),
        );

    return client.storage.from('workout_reels').getPublicUrl(path);
  }

  /// Publishes a verified workout reel to the live Explore Feed via backend RPC.
  Future<Map<String, dynamic>> publishWorkoutReel({
    required String tenantId,
    required String userId,
    required String videoUrl,
    String? thumbnailUrl,
    int durationSeconds = 60,
    String? routineTitle,
    int streakDays = 0,
    bool isPublic = true,
  }) async {
    final client = _client;
    if (client == null) return {'success': true};

    final res = await client.rpc('rpc_publish_workout_reel', params: {
      'p_tenant_id': tenantId,
      'p_user_id': userId,
      'p_video_url': videoUrl,
      'p_thumbnail_url': thumbnailUrl,
      'p_duration_seconds': durationSeconds,
      'p_routine_title': routineTitle ?? 'Workout Session',
      'p_streak_days': streakDays,
      'p_is_public': isPublic,
    });

    if (res is Map<String, dynamic>) return res;
    return {'success': true, 'raw': res};
  }

  /// Toggles like on an explore reel.
  Future<int> toggleLike({required String reelId, required bool increment}) async {
    final client = _client;
    if (client == null) return 0;

    final res = await client.rpc('rpc_toggle_reel_like', params: {
      'p_reel_id': reelId,
      'p_increment': increment,
    });

    return (res as num?)?.toInt() ?? 0;
  }
}
