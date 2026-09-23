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

  Future<WorkoutRoutineDay> getTodayRoutine({int dayNumber = 1}) async {
    final client = _supabase;
    if (client != null) {
      try {
        final data = await client
            .from('workout_routine_days')
            .select('*, workout_day_exercises(*, exercises(*))')
            .eq('day_number', dayNumber)
            .limit(1)
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

          if (dayExercises.isNotEmpty) {
            return WorkoutRoutineDay(
              id: data['id'] as String? ?? 'day-$dayNumber',
              routineId: data['routine_id'] as String? ?? 'routine-1',
              dayNumber: dayNumber,
              title: data['title'] as String? ?? 'Day $dayNumber Workout',
              muscleGroups: (data['muscle_groups'] as List?)?.map((e) => e.toString()).toList() ?? ['Full Body'],
              isRestDay: (data['is_rest_day'] as bool?) ?? false,
              exercises: dayExercises,
            );
          }
        }
      } catch (e) {
        debugPrint('WorkoutRepository: Supabase fetch error, using local fallback: $e');
      }
    }

    final catalog = _getDefaultRoutineDays();
    final index = (dayNumber - 1) % catalog.length;
    return catalog[index];
  }

  Future<List<WorkoutRoutineDay>> get90DayCalendar() async {
    final catalog = _getDefaultRoutineDays();
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

  List<WorkoutRoutineDay> _getDefaultRoutineDays() {
    const ex1 = Exercise(
      id: 'ex-1',
      name: 'Full Range Push-Up Form',
      targetMuscle: 'Chest & Core',
      equipment: 'Bodyweight',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Keep elbows tucked at 45 degrees. Lower chest to floor and lock out at top.',
      instructions: ['Place hands slightly wider than shoulders.', 'Lower under control for 2 seconds.', 'Push up explosively while bracing core.'],
    );
    const ex2 = Exercise(
      id: 'ex-2',
      name: 'Dumbbell Overhead Shoulder Press',
      targetMuscle: 'Anterior & Lateral Deltoids',
      equipment: 'Dumbbells',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Press directly overhead without arching lower back. Control the descent.',
      instructions: ['Hold dumbbells at ear level with 90-degree elbows.', 'Drive upward until arms are straight.', 'Lower slowly to start position.'],
    );
    const ex3 = Exercise(
      id: 'ex-3',
      name: 'Standing Biceps Dumbbell Curl',
      targetMuscle: 'Biceps Brachii',
      equipment: 'Dumbbells',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Keep elbows pinned to your sides. Supinate wrists at the top for maximum peak contraction.',
      instructions: ['Stand with feet shoulder-width apart.', 'Curl dumbbells upward while keeping torso still.', 'Squeeze biceps hard for 1 second at top.'],
    );
    const ex4 = Exercise(
      id: 'ex-4',
      name: 'Barbell Back Squat',
      targetMuscle: 'Quadriceps & Glutes',
      equipment: 'Barbell',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Break at hips and knees simultaneously. Keep chest proud and squat below parallel.',
      instructions: ['Position bar across upper traps.', 'Descend until hips are below knee crease.', 'Drive through heels to stand back up.'],
    );

    const exLat = Exercise(
      id: 'ex-lat',
      name: 'Wide Grip Lat Pulldown',
      targetMuscle: 'Lats & Upper Back',
      equipment: 'Cable Machine',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
      tips: 'Lead with elbows and pull towards upper chest.',
    );
    const exRow = Exercise(
      id: 'ex-row',
      name: 'Seated Cable Row',
      targetMuscle: 'Mid-Back & Rhomboids',
      equipment: 'Cable Machine',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Retract shoulder blades and hold peak contraction 1s.',
    );
    const exCurl = Exercise(
      id: 'ex-curl',
      name: 'Incline Dumbbell Biceps Curl',
      targetMuscle: 'Biceps Long Head',
      equipment: 'Dumbbells',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      tips: 'Keep elbows pinned behind torso for deep stretch.',
    );
    const exSquat = Exercise(
      id: 'ex-squat',
      name: 'Barbell Back Squat',
      targetMuscle: 'Quadriceps & Glutes',
      equipment: 'Barbell',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Break at hips and knees simultaneously. Depth below parallel.',
    );
    const exRdl = Exercise(
      id: 'ex-rdl',
      name: 'Romanian Deadlift',
      targetMuscle: 'Hamstrings & Glutes',
      equipment: 'Barbell',
      videoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
      sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: 'Hinge back with hips, maintaining neutral spine.',
    );

    return [
      const WorkoutRoutineDay(
        id: 'day-template-1',
        routineId: 'routine-90-hypertrophy',
        dayNumber: 1,
        title: 'Day 1: Chest & Triceps Blitz',
        muscleGroups: ['Chest', 'Triceps'],
        exercises: [
          WorkoutDayExercise(id: 'de-1', exercise: ex1, orderIndex: 1, targetSets: 4, targetRepsRange: '8-10', restSeconds: 60),
          WorkoutDayExercise(id: 'de-2', exercise: ex2, orderIndex: 2, targetSets: 3, targetRepsRange: '12-15', restSeconds: 45),
          WorkoutDayExercise(id: 'de-3', exercise: ex3, orderIndex: 3, targetSets: 4, targetRepsRange: '10-12', restSeconds: 60),
          WorkoutDayExercise(id: 'de-4', exercise: ex4, orderIndex: 4, targetSets: 3, targetRepsRange: '12-15', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'day-template-2',
        routineId: 'routine-90-hypertrophy',
        dayNumber: 2,
        title: 'Day 2: Back & Biceps Power',
        muscleGroups: ['Back', 'Biceps'],
        exercises: [
          WorkoutDayExercise(id: 'de-5', exercise: exLat, orderIndex: 1, targetSets: 4, targetRepsRange: '8-12', restSeconds: 60),
          WorkoutDayExercise(id: 'de-6', exercise: exRow, orderIndex: 2, targetSets: 4, targetRepsRange: '10-12', restSeconds: 60),
          WorkoutDayExercise(id: 'de-7', exercise: exCurl, orderIndex: 3, targetSets: 3, targetRepsRange: '12-15', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'day-template-3',
        routineId: 'routine-90-hypertrophy',
        dayNumber: 3,
        title: 'Day 3: Quads, Hamstrings & Calves',
        muscleGroups: ['Legs'],
        exercises: [
          WorkoutDayExercise(id: 'de-8', exercise: exSquat, orderIndex: 1, targetSets: 4, targetRepsRange: '6-8', restSeconds: 90),
          WorkoutDayExercise(id: 'de-9', exercise: exRdl, orderIndex: 2, targetSets: 3, targetRepsRange: '10-12', restSeconds: 75),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'day-template-4',
        routineId: 'routine-90-hypertrophy',
        dayNumber: 4,
        title: 'Day 4: Shoulders & Core Surge',
        muscleGroups: ['Shoulders', 'Core'],
        exercises: [
          WorkoutDayExercise(id: 'de-10', exercise: ex2, orderIndex: 1, targetSets: 4, targetRepsRange: '8-10', restSeconds: 60),
          WorkoutDayExercise(id: 'de-11', exercise: ex1, orderIndex: 2, targetSets: 3, targetRepsRange: '12-15', restSeconds: 45),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'day-template-5',
        routineId: 'routine-90-hypertrophy',
        dayNumber: 5,
        title: 'Day 5: Full Upper Body Pump',
        muscleGroups: ['Chest', 'Shoulders', 'Arms'],
        exercises: [
          WorkoutDayExercise(id: 'de-12', exercise: ex1, orderIndex: 1, targetSets: 3, targetRepsRange: '10-12', restSeconds: 60),
          WorkoutDayExercise(id: 'de-13', exercise: ex2, orderIndex: 2, targetSets: 3, targetRepsRange: '8-10', restSeconds: 60),
          WorkoutDayExercise(id: 'de-14', exercise: ex3, orderIndex: 3, targetSets: 3, targetRepsRange: '10-12', restSeconds: 60),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'day-template-6',
        routineId: 'routine-90-hypertrophy',
        dayNumber: 6,
        title: 'Day 6: Lower Body Power',
        muscleGroups: ['Legs', 'Calves'],
        exercises: [
          WorkoutDayExercise(id: 'de-15', exercise: exSquat, orderIndex: 1, targetSets: 4, targetRepsRange: '8-10', restSeconds: 75),
        ],
      ),
      const WorkoutRoutineDay(
        id: 'day-template-7',
        routineId: 'routine-90-hypertrophy',
        dayNumber: 7,
        title: 'Day 7: Active Recovery & Mobility',
        muscleGroups: ['Mobility'],
        isRestDay: true,
        exercises: [],
      ),
    ];
  }
}
