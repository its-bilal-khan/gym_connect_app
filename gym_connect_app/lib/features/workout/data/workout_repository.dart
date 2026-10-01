import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/workout_models.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('WorkoutRepository: Supabase client unavailable: $e');
  }
  return WorkoutRepository(client);
});

class WorkoutRepository {
  final SupabaseClient? _supabase;

  const WorkoutRepository(this._supabase);

  Future<WorkoutRoutineDay> getTodayRoutine({
    int dayNumber = 1,
    String bodyType = 'mesomorph',
    String? tenantId,
    String? userId,
  }) async {
    final client = _supabase;
    final cleanType = bodyType.toLowerCase().trim();
    final weeklyDay = ((dayNumber - 1) % 7) + 1;
    final effectiveUserId = userId ?? client?.auth.currentUser?.id;

    if (client != null) {
      try {
        String? routineId;

        // 0. Member Personal AI Routine Priority (Check user's active AI routine)
        if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
          final userAiRes = await client
              .from('workout_routines')
              .select('id')
              .eq('user_id', effectiveUserId)
              .eq('is_ai_generated', true)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          routineId = userAiRes?['id'] as String?;
        }

        // 1. Hierarchical check: Gym custom protocol first
        if (routineId == null && tenantId != null && tenantId.isNotEmpty) {
          final tenantRes = await client
              .from('workout_routines')
              .select('id')
              .eq('tenant_id', tenantId)
              .eq('body_type', cleanType)
              .maybeSingle();
          routineId = tenantRes?['id'] as String?;
        }

        // 2. Fall back to Platform Master default (tenant_id IS NULL)
        if (routineId == null) {
          final masterRes = await client
              .from('workout_routines')
              .select('id')
              .isFilter('tenant_id', null)
              .eq('body_type', cleanType)
              .maybeSingle();
          routineId = masterRes?['id'] as String?;
        }

        // 3. Fall back to any routine for this body type
        if (routineId == null) {
          final anyRes = await client
              .from('workout_routines')
              .select('id')
              .eq('body_type', cleanType)
              .limit(1)
              .maybeSingle();
          routineId = anyRes?['id'] as String?;
        }

        if (routineId != null) {
          final data = await client
              .from('workout_routine_days')
              .select('*, workout_day_exercises(*, exercises(*))')
              .eq('routine_id', routineId)
              .eq('day_number', weeklyDay)
              .maybeSingle();

          if (data != null && data['workout_day_exercises'] != null) {
            final rawExercises = List<Map<String, dynamic>>.from(data['workout_day_exercises'] as List);
            rawExercises.sort((a, b) => ((a['order_index'] as int?) ?? 0).compareTo((b['order_index'] as int?) ?? 0));

            final dayExercises = <WorkoutDayExercise>[];
            for (final item in rawExercises) {
              final exData = item['exercises'] as Map<String, dynamic>?;
              if (exData != null) {
                final exercise = Exercise.fromJson(exData);
                dayExercises.add(WorkoutDayExercise(
                  id: item['id'] as String? ?? 'wde-${dayExercises.length + 1}',
                  exercise: exercise,
                  orderIndex: (item['order_index'] as int?) ?? (dayExercises.length + 1),
                  targetSets: (item['target_sets'] as int?) ?? 3,
                  targetRepsRange: (item['target_reps_range'] as String?) ?? '8-12',
                  restSeconds: (item['rest_seconds'] as int?) ?? 60,
                  notes: item['notes'] as String?,
                ));
              }
            }

            if (dayExercises.isNotEmpty || ((data['is_rest_day'] as bool?) ?? false)) {
              return WorkoutRoutineDay(
                id: data['id'] as String? ?? 'day-$dayNumber',
                routineId: routineId,
                dayNumber: dayNumber,
                title: data['title'] as String? ?? 'Day $dayNumber Workout',
                muscleGroups: (data['muscle_groups'] as List?)?.map((e) => e.toString()).toList() ?? ['Full Body'],
                isRestDay: (data['is_rest_day'] as bool?) ?? false,
                exercises: dayExercises,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('WorkoutRepository: Supabase fetch error, using local fallback: $e');
      }
    }

    // Authentic local fallback tuned specifically to the active body type
    final catalog = _getDefaultRoutineDaysForBodyType(cleanType);
    final index = (weeklyDay - 1) % catalog.length;
    final template = catalog[index];
    return WorkoutRoutineDay(
      id: 'day-$dayNumber',
      routineId: template.routineId,
      dayNumber: dayNumber,
      title: template.title,
      muscleGroups: template.muscleGroups,
      isRestDay: template.isRestDay,
      exercises: template.exercises,
    );
  }

  WorkoutRoutineDay getDefaultRoutineSync({
    int dayNumber = 1,
    String bodyType = 'mesomorph',
  }) {
    final catalog = _getDefaultRoutineDaysForBodyType(bodyType.toLowerCase().trim());
    final weeklyDay = ((dayNumber - 1) % 7) + 1;
    final index = (weeklyDay - 1) % catalog.length;
    final template = catalog[index];
    return WorkoutRoutineDay(
      id: 'day-$dayNumber',
      routineId: template.routineId,
      dayNumber: dayNumber,
      title: template.title,
      muscleGroups: template.muscleGroups,
      isRestDay: template.isRestDay,
      exercises: template.exercises,
    );
  }

  Future<List<WorkoutRoutineDay>> get90DayCalendar({String bodyType = 'mesomorph'}) async {
    final catalog = _getDefaultRoutineDaysForBodyType(bodyType.toLowerCase().trim());
    return List.generate(90, (i) {
      final template = catalog[i % catalog.length];
      return WorkoutRoutineDay(
        id: 'day-${i + 1}',
        routineId: template.routineId,
        dayNumber: i + 1,
        title: 'Day ${i + 1}: ${template.title.split(': ').last}',
        muscleGroups: template.muscleGroups,
        isRestDay: template.isRestDay,
        exercises: template.exercises,
      );
    });
  }

  Future<void> logWorkoutCompletion({
    required String userId,
    required String routineDayId,
    required int durationMinutes,
    required List<WorkoutSetRecord> completedSets,
  }) async {
    final client = _supabase;
    if (client == null) return;

    try {
      final logRes = await client.from('workout_logs').insert({
        'user_id': userId,
        'routine_day_id': routineDayId,
        'started_at': DateTime.now().subtract(Duration(minutes: durationMinutes)).toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
        'total_duration_minutes': durationMinutes,
      }).select('id').maybeSingle();

      if (logRes != null && logRes['id'] != null) {
        final workoutLogId = logRes['id'] as String;
        final setEntries = completedSets.map((s) => {
              'workout_log_id': workoutLogId,
              'set_number': s.setNumber,
              'reps_completed': s.actualReps,
              'weight_kg': s.weightKg,
              'is_personal_record': s.isPersonalRecord,
            }).toList();
        await client.from('workout_set_logs').insert(setEntries);
      }
    } catch (e) {
      debugPrint('WorkoutRepository: logWorkoutCompletion error: $e');
    }
  }

  Future<FullWeeklyProtocolResult> fetchFullWeeklyProtocol({
    required String bodyType,
    String? tenantId,
  }) async {
    final client = _supabase;
    final cleanType = bodyType.toLowerCase().trim();

    if (client != null) {
      try {
        Map<String, dynamic>? routineRow;
        bool isCustom = false;

        // 1. Check gym custom override if tenantId is provided
        if (tenantId != null && tenantId.isNotEmpty) {
          final res = await client
              .from('workout_routines')
              .select('*')
              .eq('tenant_id', tenantId)
              .eq('body_type', cleanType)
              .maybeSingle();
          if (res != null) {
            routineRow = res;
            isCustom = true;
          }
        }

        // 2. Fall back to Platform Master default (tenant_id IS NULL)
        if (routineRow == null) {
          final res = await client
              .from('workout_routines')
              .select('*')
              .isFilter('tenant_id', null)
              .eq('body_type', cleanType)
              .maybeSingle();
          if (res != null) {
            routineRow = res;
            isCustom = false;
          }
        }

        if (routineRow != null) {
          final routineId = routineRow['id'] as String;
          final rawDays = await client
              .from('workout_routine_days')
              .select('*, workout_day_exercises(*, exercises(*))')
              .eq('routine_id', routineId)
              .order('day_number', ascending: true);

          final daysList = <WorkoutRoutineDay>[];
          for (final dayData in (rawDays as List)) {
            final dayMap = dayData as Map<String, dynamic>;
            final rawExercises = (dayMap['workout_day_exercises'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            rawExercises.sort((a, b) =>
                ((a['order_index'] as int?) ?? 0)
                    .compareTo((b['order_index'] as int?) ?? 0));

            final dayExercises = <WorkoutDayExercise>[];
            for (final item in rawExercises) {
              final exData = item['exercises'] as Map<String, dynamic>?;
              if (exData != null) {
                dayExercises.add(WorkoutDayExercise(
                  id: item['id'] as String? ?? 'wde-${dayExercises.length + 1}',
                  exercise: Exercise.fromJson(exData),
                  orderIndex: (item['order_index'] as int?) ??
                      (dayExercises.length + 1),
                  targetSets: (item['target_sets'] as int?) ?? 3,
                  targetRepsRange:
                      (item['target_reps_range'] as String?) ?? '8-12',
                  restSeconds: (item['rest_seconds'] as int?) ?? 60,
                  notes: item['notes'] as String?,
                ));
              }
            }

            daysList.add(WorkoutRoutineDay(
              id: dayMap['id'] as String? ?? 'day-${dayMap['day_number']}',
              routineId: routineId,
              dayNumber:
                  (dayMap['day_number'] as int?) ?? (daysList.length + 1),
              title: dayMap['title'] as String? ??
                  'Day ${dayMap['day_number']} Workout',
              muscleGroups: (dayMap['muscle_groups'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  ['Full Body'],
              isRestDay: (dayMap['is_rest_day'] as bool?) ?? false,
              exercises: dayExercises,
            ));
          }

          if (daysList.length == 7) {
            return FullWeeklyProtocolResult(
              routineId: routineId,
              title: routineRow['title'] as String? ??
                  '${cleanType.toUpperCase()} Weekly Protocol',
              description: routineRow['description'] as String? ??
                  'Scientifically calibrated hypertrophy schedule.',
              bodyType: cleanType,
              subtitle: routineRow['subtitle'] as String?,
              targetPhysique: routineRow['target_physique'] as String?,
              imageUrl: routineRow['image_url'] as String?,
              galleryImages: (routineRow['gallery_images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
              tenantId: routineRow['tenant_id'] as String?,
              isCustomTenantOverride: isCustom,
              days: daysList,
            );
          }
        }
      } catch (e) {
        debugPrint('WorkoutRepository.fetchFullWeeklyProtocol error: $e');
      }
    }

    // Fallback to built-in default 7-day protocol
    final fallbackDays = _getDefaultRoutineDaysForBodyType(cleanType);
    return FullWeeklyProtocolResult(
      routineId: 'local-$cleanType-master',
      title:
          '${cleanType[0].toUpperCase()}${cleanType.substring(1)} Master Platform Protocol',
      description:
          'Scientifically calibrated master protocol with optimal progressive overload.',
      bodyType: cleanType,
      subtitle: cleanType == 'ectomorph'
          ? 'Lean Build • High Calorie Hypertrophy Split'
          : (cleanType == 'endomorph'
              ? 'Stocky Build • Metabolic Circuit & High Volume'
              : 'Athletic Build • Heavy Compound & Definition'),
      targetPhysique: cleanType == 'ectomorph'
          ? 'Outcome: Shredded Athletic V-Taper (6-8% Body Fat)'
          : (cleanType == 'endomorph'
              ? 'Outcome: Solid Powerlifter Physique (Chiseled Mass)'
              : 'Outcome: Dense Muscular Beast (Full Chest & Wide Lats)'),
      imageUrl: null,
      tenantId: null,
      isCustomTenantOverride: false,
      days: fallbackDays,
    );
  }

  Future<List<BodyTypeInfo>> fetchBodyTypesCatalog({String? tenantId}) async {
    const defaults = [
      BodyTypeInfo(
        key: 'ectomorph',
        title: 'ECTOMORPH',
        subtitle: 'Lean Build • High Calorie Hypertrophy Split',
        description: 'Fast metabolism & lean build. Requires caloric surplus and hyper-focused compound volume.',
        targetPhysique: 'Outcome: Shredded Athletic V-Taper (6-8% Body Fat)',
        imageUrl: null,
        defaultImageAsset: 'assets/images/ectomorph.jpg',
      ),
      BodyTypeInfo(
        key: 'mesomorph',
        title: 'MESOMORPH',
        subtitle: 'Athletic Build • Heavy Compound & Definition',
        description: 'Naturally broad and muscular. Rapid response to progressive overload hypertrophy.',
        targetPhysique: 'Outcome: Dense Muscular Beast (Full Chest & Wide Lats)',
        imageUrl: null,
        defaultImageAsset: 'assets/images/mesomorph.jpg',
      ),
      BodyTypeInfo(
        key: 'endomorph',
        title: 'ENDOMORPH',
        subtitle: 'Stocky Build • Metabolic Circuit & High Volume',
        description: 'Thick bone density and raw lifting power. Combined with metabolic conditioning burn.',
        targetPhysique: 'Outcome: Solid Powerlifter Physique (Chiseled Mass)',
        imageUrl: null,
        defaultImageAsset: 'assets/images/endomorph.jpg',
      ),
    ];

    final client = _supabase;
    if (client == null) return defaults;

    try {
      final results = <BodyTypeInfo>[];
      for (final def in defaults) {
        Map<String, dynamic>? row;
        if (tenantId != null && tenantId.isNotEmpty) {
          final res = await client
              .from('workout_routines')
              .select('*')
              .eq('tenant_id', tenantId)
              .eq('body_type', def.key)
              .maybeSingle();
          row = res;
        }
        if (row == null) {
          final res = await client
              .from('workout_routines')
              .select('*')
              .isFilter('tenant_id', null)
              .eq('body_type', def.key)
              .maybeSingle();
          row = res;
        }

        if (row != null) {
          results.add(BodyTypeInfo(
            key: def.key,
            title: (row['title'] as String?)?.isNotEmpty == true
                ? row['title'] as String
                : def.title,
            subtitle: (row['subtitle'] as String?)?.isNotEmpty == true
                ? row['subtitle'] as String
                : def.subtitle,
            description: (row['description'] as String?)?.isNotEmpty == true
                ? row['description'] as String
                : def.description,
            targetPhysique: (row['target_physique'] as String?)?.isNotEmpty == true
                ? row['target_physique'] as String
                : def.targetPhysique,
            imageUrl: row['image_url'] as String?,
            galleryImages: (row['gallery_images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
            defaultImageAsset: def.defaultImageAsset,
          ));
        } else {
          results.add(def);
        }
      }
      return results;
    } catch (e) {
      debugPrint('WorkoutRepository.fetchBodyTypesCatalog error: $e');
      return defaults;
    }
  }

  Future<bool> updateBodyTypeProtocolInfo({
    required String bodyType,
    String? tenantId,
    required String title,
    required String subtitle,
    required String description,
    required String targetPhysique,
    String? imageUrl,
    List<String>? galleryImages,
  }) async {
    final client = _supabase;
    if (client == null) return false;
    final cleanType = bodyType.toLowerCase().trim();
    try {
      String? routineId;
      if (tenantId != null && tenantId.isNotEmpty) {
        final existing = await client
            .from('workout_routines')
            .select('id')
            .eq('tenant_id', tenantId)
            .eq('body_type', cleanType)
            .maybeSingle();
        routineId = existing?['id'] as String?;
      } else {
        final existing = await client
            .from('workout_routines')
            .select('id')
            .isFilter('tenant_id', null)
            .eq('body_type', cleanType)
            .maybeSingle();
        routineId = existing?['id'] as String?;
      }

      if (routineId == null) {
        final defaultDays = _getDefaultRoutineDaysForBodyType(cleanType);
        await saveCustomWeeklyProtocol(
          bodyType: cleanType,
          tenantId: tenantId,
          days: defaultDays,
          protocolTitle: title,
          protocolDescription: description,
          subtitle: subtitle,
          targetPhysique: targetPhysique,
          imageUrl: imageUrl,
          galleryImages: galleryImages,
        );
      } else {
        final updateMap = <String, dynamic>{
          'title': title,
          'subtitle': subtitle,
          'description': description,
          'target_physique': targetPhysique,
          'image_url': imageUrl,
          'gallery_images': ?galleryImages,
          'updated_at': DateTime.now().toIso8601String(),
        };
        await client.from('workout_routines').update(updateMap).eq('id', routineId);
      }
      return true;
    } catch (e) {
      debugPrint('WorkoutRepository.updateBodyTypeProtocolInfo error: $e');
      return false;
    }
  }

  Future<String?> uploadBodyTypeImage({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/jpeg',
  }) async {
    final client = _supabase;
    if (client == null) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'body_types/${timestamp}_$fileName';

      String bucketName = 'product_images';
      try {
        await client.storage.from(bucketName).uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );
      } catch (_) {
        bucketName = 'payment_receipts';
        await client.storage.from(bucketName).uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );
      }

      return client.storage.from(bucketName).getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('WorkoutRepository: uploadBodyTypeImage error: $e');
      return null;
    }
  }

  Future<void> saveCustomWeeklyProtocol({
    required String bodyType,
    String? tenantId,
    required List<WorkoutRoutineDay> days,
    String? protocolTitle,
    String? protocolDescription,
    String? subtitle,
    String? targetPhysique,
    String? imageUrl,
    List<String>? galleryImages,
  }) async {
    final client = _supabase;
    if (client == null) {
      debugPrint('Supabase client unavailable, skipping remote save');
      return;
    }

    final cleanType = bodyType.toLowerCase().trim();
    _inMemoryRoutineDays ??= {};
    _inMemoryRoutineDays![cleanType] = days;
    String? routineId;

    if (tenantId != null && tenantId.isNotEmpty) {
      final existing = await client
          .from('workout_routines')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('body_type', cleanType)
          .maybeSingle();
      routineId = existing?['id'] as String?;
    } else {
      final existing = await client
          .from('workout_routines')
          .select('id')
          .isFilter('tenant_id', null)
          .eq('body_type', cleanType)
          .maybeSingle();
      routineId = existing?['id'] as String?;
    }

    final defaultTitle = tenantId != null
        ? '${cleanType.toUpperCase()} Custom Gym Protocol'
        : '${cleanType.toUpperCase()} Master Global Protocol';

    if (routineId == null) {
      final insertRes = await client.from('workout_routines').insert({
        if (tenantId != null && tenantId.isNotEmpty) 'tenant_id': tenantId,
        'body_type': cleanType,
        'title': protocolTitle ?? defaultTitle,
        'description': protocolDescription ??
            'Calibrated protocol managed via desktop studio.',
        'subtitle': ?subtitle,
        'target_physique': ?targetPhysique,
        'image_url': ?imageUrl,
        'gallery_images': ?galleryImages,
        'target_goal': 'Hypertrophy & Metabolic Conditioning',
        'duration_days': 90,
      }).select('id').single();
      routineId = insertRes['id'] as String;
    } else {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (protocolTitle != null) updateData['title'] = protocolTitle;
      if (protocolDescription != null) updateData['description'] = protocolDescription;
      if (subtitle != null) updateData['subtitle'] = subtitle;
      if (targetPhysique != null) updateData['target_physique'] = targetPhysique;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (galleryImages != null) updateData['gallery_images'] = galleryImages;
      await client.from('workout_routines').update(updateData).eq('id', routineId);
    }

    final existingDays = await client
        .from('workout_routine_days')
        .select('id')
        .eq('routine_id', routineId);
    if (existingDays.isNotEmpty) {
      final dayIds = existingDays.map((d) => d['id'] as String).toList();
      await client
          .from('workout_day_exercises')
          .delete()
          .inFilter('day_id', dayIds);
      await client
          .from('workout_routine_days')
          .delete()
          .eq('routine_id', routineId);
    }

    for (final day in days) {
      final dayRes = await client.from('workout_routine_days').insert({
        'routine_id': routineId,
        'day_number': day.dayNumber,
        'title': day.title,
        'muscle_groups': day.muscleGroups,
        'is_rest_day': day.isRestDay,
      }).select('id').single();

      final dayId = dayRes['id'] as String;

      if (!day.isRestDay && day.exercises.isNotEmpty) {
        final exercisePayloads = <Map<String, dynamic>>[];
        for (int i = 0; i < day.exercises.length; i++) {
          final wde = day.exercises[i];
          String effectiveExerciseId = wde.exercise.id;

          if (!_isUuid(effectiveExerciseId)) {
            try {
              final match = await client
                  .from('exercises')
                  .select('id')
                  .ilike('name', wde.exercise.name.trim())
                  .maybeSingle();

              if (match != null && match['id'] != null) {
                effectiveExerciseId = match['id'] as String;
              } else {
                final insertData = wde.exercise.toJson(tenantId: tenantId, isGlobal: true);
                insertData.remove('id');
                final inserted = await client
                    .from('exercises')
                    .insert(insertData)
                    .select('id')
                    .maybeSingle();
                if (inserted != null && inserted['id'] != null) {
                  effectiveExerciseId = inserted['id'] as String;
                }
              }
            } catch (err) {
              debugPrint('saveCustomWeeklyProtocol: UUID resolution error: $err');
            }
          }

          exercisePayloads.add({
            'day_id': dayId,
            'exercise_id': effectiveExerciseId,
            'order_index': i + 1,
            'target_sets': wde.targetSets,
            'target_reps_range': wde.targetRepsRange,
            'rest_seconds': wde.restSeconds,
            'notes': wde.notes,
          });
        }
        if (exercisePayloads.isNotEmpty) {
          await client.from('workout_day_exercises').insert(exercisePayloads);
        }
      }
    }

    _inMemoryRoutineDays ??= {};
    _inMemoryRoutineDays![cleanType] = days;
  }

  Future<void> resetToPlatformDefault({
    required String bodyType,
    required String tenantId,
  }) async {
    final client = _supabase;
    if (client == null) return;
    final cleanType = bodyType.toLowerCase().trim();

    final routineRes = await client
        .from('workout_routines')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('body_type', cleanType)
        .maybeSingle();

    if (routineRes != null) {
      final routineId = routineRes['id'] as String;
      final existingDays = await client
          .from('workout_routine_days')
          .select('id')
          .eq('routine_id', routineId);
      if (existingDays.isNotEmpty) {
        final dayIds = existingDays.map((d) => d['id'] as String).toList();
        final formattedDayIds = '(${dayIds.join(',')})';
        await client
            .from('workout_day_exercises')
            .delete()
            .filter('day_id', 'in', formattedDayIds);
        await client
            .from('workout_routine_days')
            .delete()
            .eq('routine_id', routineId);
      }
      await client.from('workout_routines').delete().eq('id', routineId);
    }
  }

  static List<Exercise>? _inMemoryExerciseCatalog;

  Future<List<Exercise>> fetchExerciseCatalog({bool forceRefresh = false}) async {
    final client = _supabase;
    if (client != null && (_inMemoryExerciseCatalog == null || forceRefresh)) {
      try {
        final res = await client
            .from('exercises')
            .select()
            .order('name', ascending: true);
        if (res.isNotEmpty) {
          final list = res.map(Exercise.fromJson).toList();
          _inMemoryExerciseCatalog = list;
          return list;
        }
      } catch (e) {
        debugPrint('WorkoutRepository.fetchExerciseCatalog error: $e');
      }
    }
    _inMemoryExerciseCatalog ??= _getAllBuiltInExercises();
    return List.unmodifiable(_inMemoryExerciseCatalog!);
  }

  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool _isUuid(String id) => _uuidRegex.hasMatch(id);

  static Map<String, List<WorkoutRoutineDay>>? _inMemoryRoutineDays;

  void _syncExerciseIntoRoutineDays(Exercise updated) {
    if (_inMemoryRoutineDays != null) {
      final cleanUpdatedName = updated.name.toLowerCase().trim();
      for (final days in _inMemoryRoutineDays!.values) {
        for (int d = 0; d < days.length; d++) {
          final day = days[d];
          final updatedExercises = day.exercises.map((wde) {
            if (wde.exercise.id == updated.id ||
                wde.exercise.name.toLowerCase().trim() == cleanUpdatedName) {
              return wde.copyWith(exercise: updated);
            }
            return wde;
          }).toList();
          days[d] = day.copyWith(exercises: updatedExercises);
        }
      }
    }
  }

  Future<Exercise> saveOrUpdateExercise(
    Exercise exercise, {
    String? tenantId,
    bool isGlobal = true,
  }) async {
    final client = _supabase;
    if (client != null) {
      try {
        if (_isUuid(exercise.id)) {
          final data = exercise.toJson(tenantId: tenantId, isGlobal: isGlobal);
          await client.from('exercises').upsert(data);
        } else {
          // If ID is not a valid UUID (e.g. built-in 'ecto-1'), update by exercise name
          final existing = await client
              .from('exercises')
              .select('id')
              .ilike('name', exercise.name)
              .maybeSingle();

          if (existing != null && existing['id'] != null) {
            final realUuid = existing['id'] as String;
            await client.from('exercises').update({
              'video_url': exercise.videoUrl,
              if (exercise.sideVideoUrl != null)
                'side_video_url': exercise.sideVideoUrl,
              'tips': exercise.tips,
              'target_muscle': exercise.targetMuscle,
              'equipment': exercise.equipment,
            }).eq('id', realUuid);
            exercise = exercise.copyWith(id: realUuid);
          } else {
            final data = exercise.toJson(tenantId: tenantId, isGlobal: isGlobal);
            data.remove('id');
            final inserted = await client
                .from('exercises')
                .insert(data)
                .select('id')
                .maybeSingle();
            if (inserted != null && inserted['id'] != null) {
              exercise = exercise.copyWith(id: inserted['id'] as String);
            }
          }
        }
      } catch (e) {
        debugPrint('WorkoutRepository.saveOrUpdateExercise error: $e');
      }
    }

    _inMemoryExerciseCatalog ??= _getAllBuiltInExercises();
    final index = _inMemoryExerciseCatalog!.indexWhere((e) =>
        e.id == exercise.id ||
        e.name.toLowerCase().trim() == exercise.name.toLowerCase().trim());
    if (index >= 0) {
      _inMemoryExerciseCatalog![index] = exercise;
    } else {
      _inMemoryExerciseCatalog!.insert(0, exercise);
    }

    _syncExerciseIntoRoutineDays(exercise);
    return exercise;
  }

  Future<void> updateExerciseVideo({
    required String exerciseId,
    required String videoUrl,
    String? sideVideoUrl,
    String? exerciseName,
  }) async {
    final client = _supabase;
    if (client != null) {
      try {
        final updateData = <String, dynamic>{
          'video_url': videoUrl,
        };
        if (sideVideoUrl != null && sideVideoUrl.isNotEmpty) {
          updateData['side_video_url'] = sideVideoUrl;
        }

        if (_isUuid(exerciseId)) {
          await client.from('exercises').update(updateData).eq('id', exerciseId);
        } else if (exerciseName != null && exerciseName.isNotEmpty) {
          await client
              .from('exercises')
              .update(updateData)
              .ilike('name', exerciseName);
        }
      } catch (e) {
        debugPrint('WorkoutRepository.updateExerciseVideo error: $e');
      }
    }

    _inMemoryExerciseCatalog ??= _getAllBuiltInExercises();
    for (int i = 0; i < _inMemoryExerciseCatalog!.length; i++) {
      final old = _inMemoryExerciseCatalog![i];
      if (old.id == exerciseId ||
          (exerciseName != null &&
              old.name.toLowerCase().trim() ==
                  exerciseName.toLowerCase().trim())) {
        final updated = old.copyWith(
          videoUrl: videoUrl,
          sideVideoUrl: sideVideoUrl ?? old.sideVideoUrl,
        );
        _inMemoryExerciseCatalog![i] = updated;
        _syncExerciseIntoRoutineDays(updated);
      }
    }
  }

  Future<void> deleteExercise(String exerciseId) async {
    final client = _supabase;
    if (client != null) {
      try {
        if (_isUuid(exerciseId)) {
          await client.from('exercises').delete().eq('id', exerciseId);
        }
      } catch (e) {
        debugPrint('WorkoutRepository.deleteExercise error: $e');
      }
    }

    _inMemoryExerciseCatalog ??= _getAllBuiltInExercises();
    _inMemoryExerciseCatalog!.removeWhere((e) => e.id == exerciseId);
  }

  List<Exercise> _getAllBuiltInExercises() {
    final Map<String, Exercise> uniqueMap = {};
    for (final day in [
      ..._getMesomorphWeeklyDays(),
      ..._getEctomorphWeeklyDays(),
      ..._getEndomorphWeeklyDays(),
    ]) {
      for (final wde in day.exercises) {
        uniqueMap[wde.exercise.id] = wde.exercise;
      }
    }
    return uniqueMap.values.toList();
  }

  List<WorkoutRoutineDay> _getDefaultRoutineDaysForBodyType(String bodyType) {
    final key = bodyType.toLowerCase().trim();
    _inMemoryRoutineDays ??= {};
    if (!_inMemoryRoutineDays!.containsKey(key)) {
      final initialDays = switch (key) {
        'ectomorph' => _getEctomorphWeeklyDays(),
        'endomorph' => _getEndomorphWeeklyDays(),
        _ => _getMesomorphWeeklyDays(),
      };
      _inMemoryRoutineDays![key] = initialDays;
    }

    final days = _inMemoryRoutineDays![key]!;
    if (_inMemoryExerciseCatalog != null &&
        _inMemoryExerciseCatalog!.isNotEmpty) {
      final catalogMap = {
        for (final ex in _inMemoryExerciseCatalog!)
          ex.name.toLowerCase().trim(): ex,
      };
      for (int i = 0; i < days.length; i++) {
        final d = days[i];
        final updatedExercises = d.exercises.map((item) {
          final match = catalogMap[item.exercise.name.toLowerCase().trim()] ??
              catalogMap[item.exercise.id];
          if (match != null && match.videoUrl != item.exercise.videoUrl) {
            return item.copyWith(exercise: match);
          }
          return item;
        }).toList();
        days[i] = d.copyWith(exercises: updatedExercises);
      }
    }
    return days;
  }

  List<WorkoutRoutineDay> _getEctomorphWeeklyDays() {
    const exBench = Exercise(
      id: 'ecto-1',
      name: 'Flat Barbell Bench Press',
      targetMuscle: 'Chest',
      equipment: 'Barbell',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Tuck elbows at 45 degrees, touch lower sternum, and press explosively.',
    );
    const exIncline = Exercise(
      id: 'ecto-2',
      name: 'Incline Dumbbell Press',
      targetMuscle: 'Upper Chest',
      equipment: 'Dumbbells',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Set bench to 30-45 degrees for upper chest clavicular fibers.',
    );
    const exCableFly = Exercise(
      id: 'ecto-3',
      name: 'Cable Fly (Low to High)',
      targetMuscle: 'Upper Chest',
      equipment: 'Cable Machine',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
      tips: 'Scoop upward in an arc, squeezing upper pecs at eye level.',
    );
    const exTricep = Exercise(
      id: 'ecto-4',
      name: 'Overhead Cable Triceps Extension',
      targetMuscle: 'Triceps (Long Head)',
      equipment: 'Cable Machine',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
      tips: 'Extend elbows overhead for deep long head stretch.',
    );
    const exHangingLeg = Exercise(
      id: 'ecto-5',
      name: 'Hanging Leg Raises',
      targetMuscle: 'Lower Abs & Core',
      equipment: 'Pull-up Bar',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
      tips: 'Lift pelvis up towards ribs without swinging.',
    );

    const exPullup = Exercise(
      id: 'ecto-6',
      name: 'Weighted Pull-Ups',
      targetMuscle: 'Lats & Upper Back',
      equipment: 'Bodyweight & Belt',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      tips: 'Pull sternum to bar, driving elbows down and back.',
    );
    const exBarbellRow = Exercise(
      id: 'ecto-7',
      name: 'Barbell Bent-Over Row',
      targetMuscle: 'Mid-Back & Lats',
      equipment: 'Barbell',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
      tips: 'Hinge at 45 degrees, pull to belly button with tight core.',
    );
    const exBicepCurl = Exercise(
      id: 'ecto-8',
      name: 'Standing Barbell Biceps Curl',
      targetMuscle: 'Biceps Brachii',
      equipment: 'Barbell',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
      tips: 'Keep elbows pinned, squeeze hard for 1 full second at top.',
    );

    const exShoulderPress = Exercise(
      id: 'ecto-9',
      name: 'Dumbbell Overhead Shoulder Press',
      targetMuscle: 'Deltoids',
      equipment: 'Dumbbells',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      tips: 'Press straight overhead with 90-degree elbows.',
    );
    const exLateral = Exercise(
      id: 'ecto-10',
      name: 'Cable Lateral Raise',
      targetMuscle: 'Lateral Deltoids',
      equipment: 'Cable Machine',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      tips: 'Lead with elbows to sculpt 3D boulder shoulders.',
    );

    const exSquat = Exercise(
      id: 'ecto-11',
      name: 'Barbell Back Squat',
      targetMuscle: 'Quads & Glutes',
      equipment: 'Barbell',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
      tips: 'Squat below parallel with chest up and heels planted.',
    );

    return [
      const WorkoutRoutineDay(
        id: 'ecto-day-1',
        routineId: '00000000-0000-0000-0000-000000000011',
        dayNumber: 1,
        title: 'Day 1: Monday – Chest + Triceps + Abs',
        muscleGroups: ['Chest', 'Triceps', 'Abs'],
        exercises: [
          WorkoutDayExercise(id: 'ed-1', exercise: exBench, orderIndex: 1, targetSets: 4, targetRepsRange: '8-10', restSeconds: 90),
          WorkoutDayExercise(id: 'ed-2', exercise: exIncline, orderIndex: 2, targetSets: 4, targetRepsRange: '10-12', restSeconds: 60),
          WorkoutDayExercise(id: 'ed-3', exercise: exCableFly, orderIndex: 3, targetSets: 3, targetRepsRange: '12-15', restSeconds: 45),
          WorkoutDayExercise(id: 'ed-4', exercise: exTricep, orderIndex: 4, targetSets: 3, targetRepsRange: '12-15', restSeconds: 45),
          WorkoutDayExercise(id: 'ed-5', exercise: exHangingLeg, orderIndex: 5, targetSets: 4, targetRepsRange: '12-15', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'ecto-day-2',
        routineId: '00000000-0000-0000-0000-000000000011',
        dayNumber: 2,
        title: 'Day 2: Tuesday – Back + Biceps + Abs + Neck',
        muscleGroups: ['Back', 'Biceps', 'Abs', 'Neck'],
        exercises: [
          WorkoutDayExercise(id: 'ed-6', exercise: exPullup, orderIndex: 1, targetSets: 4, targetRepsRange: '6-10', restSeconds: 90),
          WorkoutDayExercise(id: 'ed-7', exercise: exBarbellRow, orderIndex: 2, targetSets: 4, targetRepsRange: '8-10', restSeconds: 75),
          WorkoutDayExercise(id: 'ed-8', exercise: exBicepCurl, orderIndex: 3, targetSets: 3, targetRepsRange: '8-10', restSeconds: 60),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'ecto-day-3',
        routineId: '00000000-0000-0000-0000-000000000011',
        dayNumber: 3,
        title: 'Day 3: Wednesday – Shoulders + Abs',
        muscleGroups: ['Shoulders', 'Abs'],
        exercises: [
          WorkoutDayExercise(id: 'ed-9', exercise: exShoulderPress, orderIndex: 1, targetSets: 4, targetRepsRange: '8-10', restSeconds: 75),
          WorkoutDayExercise(id: 'ed-10', exercise: exLateral, orderIndex: 2, targetSets: 5, targetRepsRange: '15-20', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'ecto-day-4',
        routineId: '00000000-0000-0000-0000-000000000011',
        dayNumber: 4,
        title: 'Day 4: Thursday – Chest + Triceps + Abs + Neck',
        muscleGroups: ['Chest', 'Triceps', 'Abs'],
        exercises: [
          WorkoutDayExercise(id: 'ed-11', exercise: exIncline, orderIndex: 1, targetSets: 4, targetRepsRange: '8-10', restSeconds: 90),
          WorkoutDayExercise(id: 'ed-12', exercise: exBench, orderIndex: 2, targetSets: 3, targetRepsRange: '10-12', restSeconds: 60),
          WorkoutDayExercise(id: 'ed-13', exercise: exTricep, orderIndex: 3, targetSets: 3, targetRepsRange: '12-15', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'ecto-day-5',
        routineId: '00000000-0000-0000-0000-000000000011',
        dayNumber: 5,
        title: 'Day 5: Friday – Back + Biceps + Abs + Neck',
        muscleGroups: ['Back', 'Biceps', 'Abs'],
        exercises: [
          WorkoutDayExercise(id: 'ed-14', exercise: exPullup, orderIndex: 1, targetSets: 4, targetRepsRange: '8-10', restSeconds: 75),
          WorkoutDayExercise(id: 'ed-15', exercise: exBicepCurl, orderIndex: 2, targetSets: 3, targetRepsRange: '10-12', restSeconds: 60),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'ecto-day-6',
        routineId: '00000000-0000-0000-0000-000000000011',
        dayNumber: 6,
        title: 'Day 6: Saturday – Legs + Abs',
        muscleGroups: ['Legs', 'Abs'],
        exercises: [
          WorkoutDayExercise(id: 'ed-16', exercise: exSquat, orderIndex: 1, targetSets: 4, targetRepsRange: '8-10', restSeconds: 90),
          WorkoutDayExercise(id: 'ed-17', exercise: exHangingLeg, orderIndex: 2, targetSets: 3, targetRepsRange: '15', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'ecto-day-7',
        routineId: '00000000-0000-0000-0000-000000000011',
        dayNumber: 7,
        title: 'Day 7: Sunday – Active Recovery & Mobility',
        muscleGroups: ['Mobility', 'Recovery'],
        isRestDay: true,
        exercises: [],
      ),
    ];
  }

  List<WorkoutRoutineDay> _getMesomorphWeeklyDays() {
    const exPushup = Exercise(
      id: 'meso-1',
      name: 'Full Range Push-Up Form',
      targetMuscle: 'Chest & Core',
      equipment: 'Bodyweight',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Keep elbows tucked at 45 degrees. Lower chest to floor and lock out at top.',
    );
    const exPress = Exercise(
      id: 'meso-2',
      name: 'Dumbbell Overhead Shoulder Press',
      targetMuscle: 'Anterior & Lateral Deltoids',
      equipment: 'Dumbbells',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Press directly overhead without arching lower back. Control the descent.',
    );
    const exCurl = Exercise(
      id: 'meso-3',
      name: 'Standing Biceps Dumbbell Curl',
      targetMuscle: 'Biceps Brachii',
      equipment: 'Dumbbells',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Keep elbows pinned to your sides. Supinate wrists at top.',
    );
    const exSquat = Exercise(
      id: 'meso-4',
      name: 'Barbell Back Squat',
      targetMuscle: 'Quadriceps & Glutes',
      equipment: 'Barbell',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Break at hips and knees simultaneously. Depth below parallel.',
    );
    const exLat = Exercise(
      id: 'meso-5',
      name: 'Wide Grip Lat Pulldown',
      targetMuscle: 'Lats & Upper Back',
      equipment: 'Cable Machine',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      tips: 'Lead with elbows and pull towards upper chest.',
    );
    const exRow = Exercise(
      id: 'meso-6',
      name: 'Seated Cable Row',
      targetMuscle: 'Mid-Back & Rhomboids',
      equipment: 'Cable Machine',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
      tips: 'Retract shoulder blades and hold peak contraction 1s.',
    );

    return [
      const WorkoutRoutineDay(
        id: 'meso-day-1',
        routineId: '00000000-0000-0000-0000-000000000012',
        dayNumber: 1,
        title: 'Day 1: Heavy Push & Delts',
        muscleGroups: ['Chest', 'Shoulders'],
        exercises: [
          WorkoutDayExercise(id: 'md-1', exercise: exPushup, orderIndex: 1, targetSets: 4, targetRepsRange: '8-10', restSeconds: 60),
          WorkoutDayExercise(id: 'md-2', exercise: exPress, orderIndex: 2, targetSets: 4, targetRepsRange: '8-10', restSeconds: 75),
          WorkoutDayExercise(id: 'md-3', exercise: exCurl, orderIndex: 3, targetSets: 4, targetRepsRange: '10-12', restSeconds: 60),
          WorkoutDayExercise(id: 'md-4', exercise: exSquat, orderIndex: 4, targetSets: 3, targetRepsRange: '12-15', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'meso-day-2',
        routineId: '00000000-0000-0000-0000-000000000012',
        dayNumber: 2,
        title: 'Day 2: Heavy Pull & Lats',
        muscleGroups: ['Back', 'Biceps'],
        exercises: [
          WorkoutDayExercise(id: 'md-3', exercise: exLat, orderIndex: 1, targetSets: 4, targetRepsRange: '8-12', restSeconds: 60),
          WorkoutDayExercise(id: 'md-4', exercise: exRow, orderIndex: 2, targetSets: 4, targetRepsRange: '10-12', restSeconds: 60),
          WorkoutDayExercise(id: 'md-5', exercise: exCurl, orderIndex: 3, targetSets: 3, targetRepsRange: '10-12', restSeconds: 60),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'meso-day-3',
        routineId: '00000000-0000-0000-0000-000000000012',
        dayNumber: 3,
        title: 'Day 3: Heavy Squat & Hamstrings',
        muscleGroups: ['Legs'],
        exercises: [
          WorkoutDayExercise(id: 'md-6', exercise: exSquat, orderIndex: 1, targetSets: 4, targetRepsRange: '6-8', restSeconds: 90),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'meso-day-4',
        routineId: '00000000-0000-0000-0000-000000000012',
        dayNumber: 4,
        title: 'Day 4: V-Taper Overhead Power',
        muscleGroups: ['Shoulders', 'Upper Back'],
        exercises: [
          WorkoutDayExercise(id: 'md-7', exercise: exPress, orderIndex: 1, targetSets: 4, targetRepsRange: '8-10', restSeconds: 75),
          WorkoutDayExercise(id: 'md-8', exercise: exLat, orderIndex: 2, targetSets: 3, targetRepsRange: '10-12', restSeconds: 60),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'meso-day-5',
        routineId: '00000000-0000-0000-0000-000000000012',
        dayNumber: 5,
        title: 'Day 5: Total Body Compound Drive',
        muscleGroups: ['Full Body'],
        exercises: [
          WorkoutDayExercise(id: 'md-9', exercise: exSquat, orderIndex: 1, targetSets: 3, targetRepsRange: '8-10', restSeconds: 90),
          WorkoutDayExercise(id: 'md-10', exercise: exPushup, orderIndex: 2, targetSets: 3, targetRepsRange: '12-15', restSeconds: 60),
          WorkoutDayExercise(id: 'md-11', exercise: exRow, orderIndex: 3, targetSets: 3, targetRepsRange: '10-12', restSeconds: 60),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'meso-day-6',
        routineId: '00000000-0000-0000-0000-000000000012',
        dayNumber: 6,
        title: 'Day 6: Arm Hypertrophy & Calves',
        muscleGroups: ['Arms', 'Calves'],
        exercises: [
          WorkoutDayExercise(id: 'md-12', exercise: exCurl, orderIndex: 1, targetSets: 4, targetRepsRange: '10-12', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'meso-day-7',
        routineId: '00000000-0000-0000-0000-000000000012',
        dayNumber: 7,
        title: 'Day 7: Strategic Rest & Decompress',
        muscleGroups: ['Rest'],
        isRestDay: true,
        exercises: [],
      ),
    ];
  }

  List<WorkoutRoutineDay> _getEndomorphWeeklyDays() {
    const exPushup = Exercise(
      id: 'endo-1',
      name: 'Full Range Push-Up Form',
      targetMuscle: 'Chest & Core',
      equipment: 'Bodyweight',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Paced reps with continuous tension for high caloric burn.',
    );
    const exSquat = Exercise(
      id: 'endo-2',
      name: 'Barbell Back Squat',
      targetMuscle: 'Quadriceps & Glutes',
      equipment: 'Barbell',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Deep range, moderate weight, short rest intervals.',
    );
    const exRow = Exercise(
      id: 'endo-3',
      name: 'Seated Cable Row',
      targetMuscle: 'Mid-Back & Rhomboids',
      equipment: 'Cable Machine',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'High-volume back rows to spike metabolic output.',
    );
    const exPress = Exercise(
      id: 'endo-4',
      name: 'Dumbbell Overhead Shoulder Press',
      targetMuscle: 'Deltoids',
      equipment: 'Dumbbells',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      tips: 'Continuous tempo overhead drive.',
    );

    return [
      const WorkoutRoutineDay(
        id: 'endo-day-1',
        routineId: '00000000-0000-0000-0000-000000000013',
        dayNumber: 1,
        title: 'Day 1: Metabolic Chest & High Reps',
        muscleGroups: ['Chest', 'Core'],
        exercises: [
          WorkoutDayExercise(id: 'edn-1', exercise: exPushup, orderIndex: 1, targetSets: 4, targetRepsRange: '15-20', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'endo-day-2',
        routineId: '00000000-0000-0000-0000-000000000013',
        dayNumber: 2,
        title: 'Day 2: Back Density & Cardio Core',
        muscleGroups: ['Back', 'Abs'],
        exercises: [
          WorkoutDayExercise(id: 'edn-2', exercise: exRow, orderIndex: 1, targetSets: 4, targetRepsRange: '12-15', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'endo-day-3',
        routineId: '00000000-0000-0000-0000-000000000013',
        dayNumber: 3,
        title: 'Day 3: High-Volume Leg Furnace',
        muscleGroups: ['Legs'],
        exercises: [
          WorkoutDayExercise(id: 'edn-3', exercise: exSquat, orderIndex: 1, targetSets: 5, targetRepsRange: '12-15', restSeconds: 60),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'endo-day-4',
        routineId: '00000000-0000-0000-0000-000000000013',
        dayNumber: 4,
        title: 'Day 4: Shoulder Sculpting & Burn',
        muscleGroups: ['Shoulders'],
        exercises: [
          WorkoutDayExercise(id: 'edn-4', exercise: exPress, orderIndex: 1, targetSets: 4, targetRepsRange: '12-15', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'endo-day-5',
        routineId: '00000000-0000-0000-0000-000000000013',
        dayNumber: 5,
        title: 'Day 5: Full Body Metabolic Circuit',
        muscleGroups: ['Full Body'],
        exercises: [
          WorkoutDayExercise(id: 'edn-5', exercise: exPushup, orderIndex: 1, targetSets: 3, targetRepsRange: '15', restSeconds: 30),
          WorkoutDayExercise(id: 'edn-6', exercise: exSquat, orderIndex: 2, targetSets: 3, targetRepsRange: '15', restSeconds: 30),
          WorkoutDayExercise(id: 'edn-7', exercise: exRow, orderIndex: 3, targetSets: 3, targetRepsRange: '15', restSeconds: 30),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'endo-day-6',
        routineId: '00000000-0000-0000-0000-000000000013',
        dayNumber: 6,
        title: 'Day 6: HIIT Legs & Upper Burn',
        muscleGroups: ['Legs', 'Arms'],
        exercises: [
          WorkoutDayExercise(id: 'edn-8', exercise: exSquat, orderIndex: 1, targetSets: 4, targetRepsRange: '15', restSeconds: 45),
          WorkoutDayExercise(id: 'edn-9', exercise: exPress, orderIndex: 2, targetSets: 3, targetRepsRange: '12', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'endo-day-7',
        routineId: '00000000-0000-0000-0000-000000000013',
        dayNumber: 7,
        title: 'Day 7: Active Cardio Walk & Rest',
        muscleGroups: ['Cardio', 'Rest'],
        isRestDay: true,
        exercises: [],
      ),
    ];
  }
}
