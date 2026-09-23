import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransformationPost {
  final String id;
  final String title;
  final String story;
  final String memberName;
  final String weightLoss;
  final String bodyFat;
  final String program;
  final int daysActive;
  final int likesCount;

  const TransformationPost({
    required this.id,
    required this.title,
    required this.story,
    required this.memberName,
    required this.weightLoss,
    required this.bodyFat,
    required this.program,
    required this.daysActive,
    required this.likesCount,
  });

  factory TransformationPost.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return TransformationPost(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Member Transformation',
      story: json['story'] as String? ?? '',
      memberName: stats['member_name'] as String? ?? 'Ahmad Raza',
      weightLoss: stats['weight_loss'] as String? ?? '-14.5 KG',
      bodyFat: stats['body_fat'] as String? ?? '28% ➔ 15%',
      program: stats['program'] as String? ?? 'SHRED D-90',
      daysActive: (stats['days_active'] as int?) ?? 78,
      likesCount: (json['likes_count'] as int?) ?? 143,
    );
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('CommunityRepository: Supabase client unavailable: $e');
  }
  return CommunityRepository(client);
});

final transformationSpotlightProvider = FutureProvider<TransformationPost?>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.fetchSpotlightPost();
});

class CommunityRepository {
  final SupabaseClient? _supabase;

  const CommunityRepository(this._supabase);

  Future<TransformationPost?> fetchSpotlightPost() async {
    final client = _supabase;
    if (client == null) return null;

    try {
      final res = await client
          .from('transformation_posts')
          .select()
          .eq('is_approved', true)
          .order('likes_count', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        return TransformationPost.fromJson(res);
      }
      return null;
    } catch (e) {
      debugPrint('CommunityRepository: fetchSpotlightPost error: $e');
      return null;
    }
  }

  Future<void> updateLikes(String postId, int newLikes) async {
    final client = _supabase;
    if (client == null) return;

    try {
      await client.from('transformation_posts').update({
        'likes_count': newLikes,
      }).eq('id', postId);
    } catch (e) {
      debugPrint('CommunityRepository: updateLikes error: $e');
    }
  }
}
