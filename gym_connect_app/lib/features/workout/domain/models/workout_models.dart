class Exercise {
  final String id;
  final String name;
  final String targetMuscle;
  final String equipment;
  final String difficulty;
  final String? videoUrl;
  final String? sideVideoUrl;
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
    this.sideVideoUrl,
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
      sideVideoUrl: json['side_video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      tips: json['tips'] as String? ?? 'Keep controlled tempo.',
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? targetMuscle,
    String? equipment,
    String? difficulty,
    String? videoUrl,
    String? sideVideoUrl,
    String? thumbnailUrl,
    String? tips,
    List<String>? instructions,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      videoUrl: videoUrl ?? this.videoUrl,
      sideVideoUrl: sideVideoUrl ?? this.sideVideoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      tips: tips ?? this.tips,
      instructions: instructions ?? this.instructions,
    );
  }

  Map<String, dynamic> toJson({String? tenantId, bool isGlobal = true}) {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'target_muscle': targetMuscle,
      'equipment': equipment,
      'difficulty': difficulty,
      'video_url': videoUrl,
      'side_video_url': sideVideoUrl,
      'thumbnail_url': thumbnailUrl,
      'tips': tips,
      'instructions': instructions,
      'is_global': isGlobal,
    };
    if (tenantId != null) {
      map['tenant_id'] = tenantId;
    }
    return map;
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

  WorkoutDayExercise copyWith({
    String? id,
    Exercise? exercise,
    int? orderIndex,
    int? targetSets,
    String? targetRepsRange,
    int? restSeconds,
    String? notes,
  }) {
    return WorkoutDayExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      orderIndex: orderIndex ?? this.orderIndex,
      targetSets: targetSets ?? this.targetSets,
      targetRepsRange: targetRepsRange ?? this.targetRepsRange,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
    );
  }
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

  WorkoutRoutineDay copyWith({
    String? id,
    String? routineId,
    int? dayNumber,
    String? title,
    List<String>? muscleGroups,
    bool? isRestDay,
    List<WorkoutDayExercise>? exercises,
  }) {
    return WorkoutRoutineDay(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      isRestDay: isRestDay ?? this.isRestDay,
      exercises: exercises ?? this.exercises,
    );
  }
}

class BodyTypeInfo {
  final String key; // 'ectomorph', 'mesomorph', 'endomorph'
  final String title;
  final String subtitle;
  final String description;
  final String targetPhysique;
  final String? imageUrl;
  final List<String> galleryImages;
  final String defaultImageAsset;

  const BodyTypeInfo({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.targetPhysique,
    this.imageUrl,
    this.galleryImages = const [],
    required this.defaultImageAsset,
  });

  List<String> get allImages {
    final list = <String>[];
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      list.add(imageUrl!.trim());
    }
    for (final img in galleryImages) {
      final clean = img.trim();
      if (clean.isNotEmpty && !list.contains(clean)) {
        list.add(clean);
      }
    }
    return list;
  }

  BodyTypeInfo copyWith({
    String? title,
    String? subtitle,
    String? description,
    String? targetPhysique,
    String? imageUrl,
    List<String>? galleryImages,
  }) {
    return BodyTypeInfo(
      key: key,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      targetPhysique: targetPhysique ?? this.targetPhysique,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      defaultImageAsset: defaultImageAsset,
    );
  }
}

class FullWeeklyProtocolResult {
  final String routineId;
  final String title;
  final String description;
  final String bodyType;
  final String? subtitle;
  final String? targetPhysique;
  final String? imageUrl;
  final List<String> galleryImages;
  final String? tenantId;
  final bool isCustomTenantOverride;
  final List<WorkoutRoutineDay> days;

  const FullWeeklyProtocolResult({
    required this.routineId,
    required this.title,
    required this.description,
    required this.bodyType,
    this.subtitle,
    this.targetPhysique,
    this.imageUrl,
    this.galleryImages = const [],
    this.tenantId,
    required this.isCustomTenantOverride,
    required this.days,
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
