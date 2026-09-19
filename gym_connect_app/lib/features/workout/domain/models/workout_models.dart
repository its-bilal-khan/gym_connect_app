class Exercise {
  final String id;
  final String name;
  final String targetMuscle;
  final String equipment;
  final String difficulty;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String tips;
  final List<String> instructions;

  const Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.equipment,
    this.difficulty = 'Intermediate',
    this.videoUrl,
    this.thumbnailUrl,
    this.tips = 'Maintain core tension and controlled eccentric tempo.',
    this.instructions = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Exercise',
      targetMuscle: json['target_muscle'] as String? ?? 'Full Body',
      equipment: json['equipment'] as String? ?? 'Bodyweight',
      difficulty: json['difficulty'] as String? ?? 'Intermediate',
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      tips: json['tips'] as String? ?? 'Keep controlled tempo.',
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class WorkoutDayExercise {
  final String id;
  final Exercise exercise;
  final int orderIndex;
  final int targetSets;
  final String targetRepsRange;
  final int restSeconds;
  final String? notes;

  const WorkoutDayExercise({
    required this.id,
    required this.exercise,
    required this.orderIndex,
    this.targetSets = 3,
    this.targetRepsRange = '8-12',
    this.restSeconds = 60,
    this.notes,
  });
}

class WorkoutRoutineDay {
  final String id;
  final String routineId;
  final int dayNumber;
  final String title;
  final List<String> muscleGroups;
  final bool isRestDay;
  final List<WorkoutDayExercise> exercises;

  const WorkoutRoutineDay({
    required this.id,
    required this.routineId,
    required this.dayNumber,
    required this.title,
    required this.muscleGroups,
    this.isRestDay = false,
    this.exercises = const [],
  });
}

class WorkoutRoutine {
  final String id;
  final String title;
  final String description;
  final String targetGoal;
  final int durationDays;

  const WorkoutRoutine({
    required this.id,
    required this.title,
    required this.description,
    required this.targetGoal,
    this.durationDays = 90,
  });
}

class WorkoutSetRecord {
  final int setNumber;
  final int targetReps;
  final int actualReps;
  final double weightKg;
  final bool isCompleted;
  final bool isPersonalRecord;

  const WorkoutSetRecord({
    required this.setNumber,
    required this.targetReps,
    required this.actualReps,
    required this.weightKg,
    this.isCompleted = false,
    this.isPersonalRecord = false,
  });

  WorkoutSetRecord copyWith({
    int? setNumber,
    int? targetReps,
    int? actualReps,
    double? weightKg,
    bool? isCompleted,
    bool? isPersonalRecord,
  }) {
    return WorkoutSetRecord(
      setNumber: setNumber ?? this.setNumber,
      targetReps: targetReps ?? this.targetReps,
      actualReps: actualReps ?? this.actualReps,
      weightKg: weightKg ?? this.weightKg,
      isCompleted: isCompleted ?? this.isCompleted,
      isPersonalRecord: isPersonalRecord ?? this.isPersonalRecord,
    );
  }
}
