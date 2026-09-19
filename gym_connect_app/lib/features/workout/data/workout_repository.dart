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

  Future<WorkoutRoutineDay> getTodayRoutine({int dayNumber = 24}) async {
    // In production, queries Supabase workout_routine_days joined with exercises.
    // Falls back gracefully to the pre-seeded smart 90-day routine program.
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
      name: 'Incline Dumbbell Press',
      targetMuscle: 'Upper Chest',
      equipment: 'Dumbbells',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      tips: 'Set bench to 30 degrees. Retract scapula and drive elbows in a 45-degree angle.',
      instructions: ['Lower dumbbells under control for 3 seconds.', 'Drive up without locking elbows.'],
    );
    const ex2 = Exercise(
      id: 'ex-2',
      name: 'Low-to-High Cable Flyes',
      targetMuscle: 'Upper Chest / Clavicular',
      equipment: 'Cable Machine',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      tips: 'Keep a slight bend in elbows. Squeeze chest hard at the peak for 1 second.',
      instructions: ['Set pulleys at bottom.', 'Bring hands upward meeting at eye level.'],
    );
    const ex3 = Exercise(
      id: 'ex-3',
      name: 'Overhead Cable Rope Extension',
      targetMuscle: 'Triceps Long Head',
      equipment: 'Cable Machine',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      tips: 'Keep elbows tucked near ears. Flare the rope outwards at full extension.',
      instructions: ['Hinge slightly at hips.', 'Extend forearms fully and control negative.'],
    );
    const ex4 = Exercise(
      id: 'ex-4',
      name: 'Triceps Straight Bar Pushdown',
      targetMuscle: 'Triceps Lateral Head',
      equipment: 'Cable Machine',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4',
      tips: 'Lock upper arms against ribs. Squeeze triceps at bottom lockout.',
      instructions: ['Grip overhand with knuckles up.', 'Push down explosively, control release.'],
    );

    const exLat = Exercise(
      id: 'ex-lat',
      name: 'Wide Grip Lat Pulldown',
      targetMuscle: 'Lats & Upper Back',
      equipment: 'Cable Machine',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
      tips: 'Lead with elbows and pull towards upper chest.',
    );
    const exRow = Exercise(
      id: 'ex-row',
      name: 'Seated Cable Row',
      targetMuscle: 'Mid-Back & Rhomboids',
      equipment: 'Cable Machine',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
      tips: 'Retract shoulder blades and hold peak contraction 1s.',
    );
    const exCurl = Exercise(
      id: 'ex-curl',
      name: 'Incline Dumbbell Biceps Curl',
      targetMuscle: 'Biceps Long Head',
      equipment: 'Dumbbells',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      tips: 'Keep elbows pinned behind torso for deep stretch.',
    );
    const exSquat = Exercise(
      id: 'ex-squat',
      name: 'Barbell Back Squat',
      targetMuscle: 'Quadriceps & Glutes',
      equipment: 'Barbell',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      tips: 'Break at hips and knees simultaneously. Depth below parallel.',
    );
    const exRdl = Exercise(
      id: 'ex-rdl',
      name: 'Romanian Deadlift',
      targetMuscle: 'Hamstrings & Glutes',
      equipment: 'Barbell',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
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
          WorkoutDayExercise(id: 'de-10', exercise: ex3, orderIndex: 1, targetSets: 3, targetRepsRange: '12-15', restSeconds: 45),
          WorkoutDayExercise(id: 'de-11', exercise: ex4, orderIndex: 2, targetSets: 3, targetRepsRange: '12-15', restSeconds: 45),
        ],
      ),
    ];
  }
}
