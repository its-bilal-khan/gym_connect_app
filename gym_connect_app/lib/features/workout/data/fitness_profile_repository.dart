import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/secure_storage_service.dart';
import '../domain/models/fitness_profile_model.dart';

final fitnessProfileRepositoryProvider = Provider<FitnessProfileRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('FitnessProfileRepository: Supabase client unavailable: $e');
  }
  final storage = ref.read(secureStorageProvider);
  return FitnessProfileRepository(client, storage);
});

class FitnessProfileRepository {
  final SupabaseClient? _supabase;
  final SecureStorageService _storage;

  const FitnessProfileRepository(this._supabase, this._storage);

  Future<UserFitnessProfile> fetchFitnessProfile(String userId) async {
    // 1. Check local persistent storage first for fast response
    String? cachedBodyType;
    String? cachedGoal;
    try {
      cachedBodyType = await _storage.getSelectedBodyType();
      cachedGoal = await _storage.getFitnessGoal();
    } catch (_) {}

    final client = _supabase;
    if (client != null && userId.isNotEmpty) {
      try {
        final data = await client
            .from('user_fitness_profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (data != null) {
          final profile = UserFitnessProfile.fromJson(data);
          try {
            await _storage.saveSelectedBodyType(profile.bodyType);
            await _storage.saveFitnessGoal(profile.fitnessGoal);
          } catch (_) {}
          return profile;
        }

        // Check fallback in profiles.raw_user_meta
        final profileRow = await client
            .from('profiles')
            .select('raw_user_meta')
            .eq('id', userId)
            .maybeSingle();

        if (profileRow != null && profileRow['raw_user_meta'] is Map) {
          final meta = profileRow['raw_user_meta'] as Map<String, dynamic>;
          final metaBodyType = meta['body_type'] as String?;
          final metaGoal = meta['fitness_goal'] as String?;
          if (metaBodyType != null && metaBodyType.isNotEmpty) {
            final profile = UserFitnessProfile(
              userId: userId,
              bodyType: metaBodyType,
              fitnessGoal: metaGoal ?? 'muscle_gain',
            );
            try {
              await _storage.saveSelectedBodyType(metaBodyType);
              if (metaGoal != null) await _storage.saveFitnessGoal(metaGoal);
            } catch (_) {}
            return profile;
          }
        }
      } catch (e) {
        debugPrint('FitnessProfileRepository: fetch error: $e');
      }
    }

    return UserFitnessProfile(
      userId: userId,
      bodyType: cachedBodyType ?? 'mesomorph',
      fitnessGoal: cachedGoal ?? 'muscle_gain',
    );
  }

  Future<UserFitnessProfile> saveFitnessProfile(UserFitnessProfile profile) async {
    // 1. Persist locally immediately to ensure zero-lag offline safety
    try {
      await _storage.saveSelectedBodyType(profile.bodyType);
      await _storage.saveFitnessGoal(profile.fitnessGoal);
    } catch (_) {}

    final client = _supabase;
    if (client != null && profile.userId.isNotEmpty) {
      try {
        // Upsert into dedicated user_fitness_profiles table
        await client.from('user_fitness_profiles').upsert({
          'user_id': profile.userId,
          'body_type': profile.bodyType,
          'fitness_goal': profile.fitnessGoal,
          'experience_level': profile.experienceLevel,
          if (profile.heightCm != null) 'height_cm': profile.heightCm,
          if (profile.currentWeightKg != null) 'current_weight_kg': profile.currentWeightKg,
          if (profile.targetWeightKg != null) 'target_weight_kg': profile.targetWeightKg,
          'preferred_days_per_week': profile.preferredDaysPerWeek,
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Mirror to profiles table raw_user_meta for seamless auth joins
        await client.from('profiles').update({
          'raw_user_meta': {
            'body_type': profile.bodyType,
            'fitness_goal': profile.fitnessGoal,
          },
        }).eq('id', profile.userId);
      } catch (e) {
        debugPrint('FitnessProfileRepository: save error: $e');
      }
    }

    return profile;
  }
}
