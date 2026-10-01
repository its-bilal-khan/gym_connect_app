import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/workout_models.dart';

final aiWorkoutRepositoryProvider = Provider<AiWorkoutRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('AiWorkoutRepository: Supabase client unavailable: $e');
  }
  return AiWorkoutRepository(client);
});

class AiWorkoutRepository {
  final SupabaseClient? _supabase;

  const AiWorkoutRepository(this._supabase);

  /// 1. Assign Static Master Workout Template (Track A or Track B)
  /// Computes silent BMI, assigns the 90-Day Master Template from the database,
  /// and automatically swaps contraindicated exercises using swap_group_id.
  /// (Zero LLM / Zero Token Cost / Pure PostgreSQL Performance).
  Future<AiWorkoutGenerationResult> generateWorkout({
    required String userId,
    String? tenantId,
    String? goal,
    String? bodyType,
    double? currentWeightKg,
    double? heightCm,
    int? age,
    String? fitnessLevel,
    List<String> medicalInjuries = const [],
    String? overrideTrack,
    int durationDays = 90,
  }) async {
    final client = _supabase;
    if (client == null) {
      return AiWorkoutGenerationResult.failure('Database client not initialized');
    }

    try {
      // 1. Direct Execution via rpc_assign_master_workout_template
      final rpcRes = await client.rpc(
        'rpc_assign_master_workout_template',
        params: {
          'p_user_id': userId,
          'p_tenant_id': tenantId,
          'p_target_body_type': bodyType,
          'p_current_weight_kg': currentWeightKg,
          'p_height_cm': heightCm,
          'p_age': age,
          'p_fitness_level': fitnessLevel ?? 'beginner',
          'p_medical_injuries': medicalInjuries,
          'p_override_track': overrideTrack,
        },
      );

      if (rpcRes is Map) {
        final data = Map<String, dynamic>.from(rpcRes);
        return AiWorkoutGenerationResult.fromJson(data);
      }

      // 2. Fallback to Edge Function if RPC output was unexpected
      final payload = <String, dynamic>{
        'userId': userId,
        'medicalInjuries': medicalInjuries,
        'durationDays': durationDays,
      };
      if (tenantId != null && tenantId.isNotEmpty) payload['tenantId'] = tenantId;
      if (bodyType != null && bodyType.isNotEmpty) payload['targetBodyType'] = bodyType;
      if (currentWeightKg != null) payload['currentWeightKg'] = currentWeightKg;
      if (heightCm != null) payload['heightCm'] = heightCm;
      if (age != null) payload['age'] = age;
      if (fitnessLevel != null) payload['fitnessLevel'] = fitnessLevel;
      if (overrideTrack != null) payload['overrideTrack'] = overrideTrack;

      final res = await client.functions.invoke(
        'generate-ai-workout',
        body: payload,
      );

      if (res.status == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        return AiWorkoutGenerationResult.fromJson(data);
      }

      return AiWorkoutGenerationResult.failure('Failed to assign master workout template');
    } catch (e) {
      debugPrint('AiWorkoutRepository: Template assignment error ($e)');
      return AiWorkoutGenerationResult.failure('Failed to assign template: $e');
    }
  }

  /// 2. Get Member's Active Assigned Routine with Full 7-Day Cycle & Exercises
  Future<WorkoutRoutine?> getActiveUserRoutine(String userId) async {
    final client = _supabase;
    if (client == null || userId.isEmpty) return null;

    try {
      final res = await client
          .from('workout_routines')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        return WorkoutRoutine.fromJson(res);
      }
    } catch (e) {
      debugPrint('AiWorkoutRepository.getActiveUserRoutine error: $e');
    }
    return null;
  }

  /// 3. Get Eligible Alternative Exercises for 1-Tap Swap Feature
  Future<List<ExerciseSwapCandidate>> getEligibleSwapCandidates({
    String? tenantId,
    List<String> medicalInjuries = const [],
    String assignedTrack = 'track_a',
    String? targetMuscle,
  }) async {
    final client = _supabase;
    if (client == null) return const [];

    try {
      final res = await client.rpc('rpc_get_eligible_exercises_for_ai', params: {
        'p_tenant_id': tenantId,
        'p_medical_injuries': medicalInjuries,
        'p_assigned_track': assignedTrack,
      });

      if (res is List) {
        var list = res.map((e) => ExerciseSwapCandidate.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (targetMuscle != null && targetMuscle.isNotEmpty) {
          list = list
              .where((c) => c.targetMuscle.toLowerCase().contains(targetMuscle.toLowerCase()))
              .toList();
        }
        return list;
      }
    } catch (e) {
      debugPrint('AiWorkoutRepository.getEligibleSwapCandidates error: $e');
    }
    return const [];
  }

  /// 4. 1-Tap Exercise Swap execution in live workout day (Zero penalty)
  Future<bool> swapWorkoutDayExercise({
    required String dayExerciseId,
    required String newExerciseId,
  }) async {
    final client = _supabase;
    if (client == null) return false;

    try {
      await client
          .from('workout_day_exercises')
          .update({'exercise_id': newExerciseId})
          .eq('id', dayExerciseId);
      return true;
    } catch (e) {
      debugPrint('AiWorkoutRepository.swapWorkoutDayExercise error: $e');
      return false;
    }
  }
}
