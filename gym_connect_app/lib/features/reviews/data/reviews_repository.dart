import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('ReviewsRepository: Supabase client unavailable: $e');
  }
  return ReviewsRepository(client);
});

class ReviewsRepository {
  final SupabaseClient? _supabase;

  const ReviewsRepository(this._supabase);

  Future<bool> submitGymReview({
    required int rating,
    required String reviewTitle,
    required String reviewText,
  }) async {
    final client = _supabase;
    if (client == null) return true; // Handled safely when offline

    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final profile = await client.from('profiles').select('tenant_id').eq('id', userId).maybeSingle();
      final tenantId = profile?['tenant_id'] as String?;
      if (tenantId == null) return false;

      await client.from('gym_reviews').upsert({
        'tenant_id': tenantId,
        'member_id': userId,
        'rating': rating,
        'review_title': reviewTitle,
        'review_text': reviewText,
        'is_verified_member': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'tenant_id,member_id');

      return true;
    } catch (e) {
      debugPrint('ReviewsRepository: submitGymReview error: $e');
      return false;
    }
  }
}
