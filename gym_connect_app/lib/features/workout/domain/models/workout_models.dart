enum OptimalCameraPlacement {
  machineHolder,
  floorLevel,
  freeStanding;

  static OptimalCameraPlacement fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'machine_holder':
        return OptimalCameraPlacement.machineHolder;
      case 'floor_level':
        return OptimalCameraPlacement.floorLevel;
      case 'free_standing':
      default:
        return OptimalCameraPlacement.freeStanding;
    }
  }

  String get dbValue {
    switch (this) {
      case OptimalCameraPlacement.machineHolder:
        return 'machine_holder';
      case OptimalCameraPlacement.floorLevel:
        return 'floor_level';
      case OptimalCameraPlacement.freeStanding:
        return 'free_standing';
    }
  }

  String get instructionMessage {
    switch (this) {
      case OptimalCameraPlacement.machineHolder:
        return '📱 Insert device into the Machine Holder for accurate AI tracking.';
      case OptimalCameraPlacement.floorLevel:
        return '📐 Place phone on the floor angled upward at 45° for full body capture.';
      case OptimalCameraPlacement.freeStanding:
        return '🧍 Prop phone upright at hip height 6-8 ft away.';
    }
  }
}

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
  final OptimalCameraPlacement optimalCameraPlacement;

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
    this.optimalCameraPlacement = OptimalCameraPlacement.freeStanding,
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
      optimalCameraPlacement: OptimalCameraPlacement.fromString(
        json['optimal_camera_placement'] as String?,
      ),
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
    OptimalCameraPlacement? optimalCameraPlacement,
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
      optimalCameraPlacement:
          optimalCameraPlacement ?? this.optimalCameraPlacement,
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
      'optimal_camera_placement': optimalCameraPlacement.dbValue,
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
  final String assignedTrack; // 'track_a' or 'track_b'
  final String? userId;
  final bool isAiGenerated;
  final String? bodyType;

  const WorkoutRoutine({
    required this.id,
    required this.title,
    required this.description,
    required this.targetGoal,
    this.durationDays = 90,
    this.assignedTrack = 'track_a',
    this.userId,
    this.isAiGenerated = false,
    this.bodyType = 'mesomorph',
  });

  bool get isTrackB => assignedTrack.toLowerCase() == 'track_b';

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    return WorkoutRoutine(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Custom Workout Routine',
      description: json['description'] as String? ?? '',
      targetGoal: json['target_goal'] as String? ?? 'general_fitness',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 90,
      assignedTrack: json['assigned_track'] as String? ?? 'track_a',
      userId: json['user_id'] as String?,
      isAiGenerated: (json['is_ai_generated'] as bool?) ?? false,
      bodyType: json['body_type'] as String? ?? 'mesomorph',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_goal': targetGoal,
      'duration_days': durationDays,
      'assigned_track': assignedTrack,
      'user_id': userId,
      'is_ai_generated': isAiGenerated,
      'body_type': bodyType,
    };
  }
}

class AiWorkoutGenerationResult {
  final bool success;
  final double bmi;
  final String assignedTrack; // 'track_a' or 'track_b'
  final String routingReason;
  final String routineId;
  final String? masterTemplateId;
  final int daysGenerated;
  final int exercisesMapped;
  final int swappedExercisesCount;
  final String routineTitle;
  final String? error;

  const AiWorkoutGenerationResult({
    required this.success,
    this.bmi = 23.0,
    this.assignedTrack = 'track_a',
    this.routingReason = '',
    required this.routineId,
    this.masterTemplateId,
    this.daysGenerated = 0,
    this.exercisesMapped = 0,
    this.swappedExercisesCount = 0,
    required this.routineTitle,
    this.error,
  });

  bool get isTrackB => assignedTrack.toLowerCase() == 'track_b';

  factory AiWorkoutGenerationResult.fromJson(Map<String, dynamic> json) {
    return AiWorkoutGenerationResult(
      success: (json['success'] as bool?) ?? true,
      bmi: (json['bmi'] as num?)?.toDouble() ?? 23.0,
      assignedTrack: json['assigned_track'] as String? ?? 'track_a',
      routingReason: json['routing_reason'] as String? ?? '',
      routineId: json['routine_id'] as String? ?? '',
      masterTemplateId: json['master_template_id'] as String?,
      daysGenerated: (json['days_generated'] as num?)?.toInt() ?? (json['days_assigned'] as num?)?.toInt() ?? 0,
      exercisesMapped: (json['exercises_mapped'] as num?)?.toInt() ?? 0,
      swappedExercisesCount: (json['swapped_exercises_count'] as num?)?.toInt() ?? 0,
      routineTitle: json['routine_title'] as String? ?? '90-Day Master Routine',
      error: json['error'] as String?,
    );
  }

  factory AiWorkoutGenerationResult.failure(String message) {
    return AiWorkoutGenerationResult(
      success: false,
      routineId: '',
      routineTitle: '',
      error: message,
    );
  }
}

class ExerciseSwapCandidate {
  final String exerciseId;
  final String name;
  final String targetMuscle;
  final String equipment;
  final String difficulty;
  final String? swapGroupId;
  final String? mlPoseExerciseType;
  final String? videoUrl;
  final String? sideVideoUrl;
  final String? thumbnailUrl;

  const ExerciseSwapCandidate({
    required this.exerciseId,
    required this.name,
    required this.targetMuscle,
    required this.equipment,
    this.difficulty = 'Intermediate',
    this.swapGroupId,
    this.mlPoseExerciseType,
    this.videoUrl,
    this.sideVideoUrl,
    this.thumbnailUrl,
  });

  factory ExerciseSwapCandidate.fromJson(Map<String, dynamic> json) {
    return ExerciseSwapCandidate(
      exerciseId: json['id'] as String? ?? json['exercise_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Alternative Exercise',
      targetMuscle: json['target_muscle'] as String? ?? 'Full Body',
      equipment: json['equipment'] as String? ?? 'Bodyweight',
      difficulty: json['difficulty'] as String? ?? 'Intermediate',
      swapGroupId: json['swap_group_id'] as String?,
      mlPoseExerciseType: json['ml_pose_exercise_type'] as String?,
      videoUrl: json['video_url'] as String?,
      sideVideoUrl: json['side_video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
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
