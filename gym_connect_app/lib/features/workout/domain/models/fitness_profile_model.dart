class UserFitnessProfile {
  final String userId;
  final String bodyType; // 'ectomorph', 'mesomorph', 'endomorph'
  final String fitnessGoal; // 'muscle_gain', 'fat_loss', 'strength', 'endurance', 'general_fitness'
  final String experienceLevel;
  final double? heightCm;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final int preferredDaysPerWeek;
  final DateTime? updatedAt;

  const UserFitnessProfile({
    required this.userId,
    this.bodyType = 'mesomorph',
    this.fitnessGoal = 'muscle_gain',
    this.experienceLevel = 'intermediate',
    this.heightCm,
    this.currentWeightKg,
    this.targetWeightKg,
    this.preferredDaysPerWeek = 6,
    this.updatedAt,
  });

  String get bodyTypeDisplayName {
    switch (bodyType.toLowerCase()) {
      case 'ectomorph':
        return 'Ectomorph (Lean Body)';
      case 'endomorph':
        return 'Endomorph (Metabolic Shred)';
      case 'mesomorph':
      default:
        return 'Mesomorph (Athletic Build)';
    }
  }

  String get bodyTypeSplitDescription {
    switch (bodyType.toLowerCase()) {
      case 'ectomorph':
        return '6-Day Lean Hypertrophy, V-Taper, Neck & Core Definiton';
      case 'endomorph':
        return 'High-Intensity Metabolic Shred & Compound Furnace';
      case 'mesomorph':
      default:
        return 'Athletic Power & Heavy Compound Progression';
    }
  }

  int get recommendedDailyCalories {
    switch (bodyType.toLowerCase()) {
      case 'ectomorph':
        return 2950; // Caloric surplus for fast metabolic rate
      case 'endomorph':
        return 2150; // Targeted deficit for fat loss & recomp
      case 'mesomorph':
      default:
        return 2650; // Lean mass maintenance & progressive overload
    }
  }

  int get recommendedProteinGrams {
    switch (bodyType.toLowerCase()) {
      case 'ectomorph':
        return 175;
      case 'endomorph':
        return 185;
      case 'mesomorph':
      default:
        return 165;
    }
  }

  double get recommendedWaterLiters {
    switch (bodyType.toLowerCase()) {
      case 'ectomorph':
        return 3.5;
      case 'endomorph':
        return 4.0;
      case 'mesomorph':
      default:
        return 3.5;
    }
  }

  factory UserFitnessProfile.fromJson(Map<String, dynamic> json) {
    return UserFitnessProfile(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      bodyType: (json['body_type'] as String?)?.toLowerCase() ?? 'mesomorph',
      fitnessGoal: (json['fitness_goal'] as String?)?.toLowerCase() ?? 'muscle_gain',
      experienceLevel: json['experience_level'] as String? ?? 'intermediate',
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      currentWeightKg: (json['current_weight_kg'] as num?)?.toDouble(),
      targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
      preferredDaysPerWeek: (json['preferred_days_per_week'] as num?)?.toInt() ?? 6,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'body_type': bodyType,
      'fitness_goal': fitnessGoal,
      'experience_level': experienceLevel,
      if (heightCm != null) 'height_cm': heightCm,
      if (currentWeightKg != null) 'current_weight_kg': currentWeightKg,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      'preferred_days_per_week': preferredDaysPerWeek,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  UserFitnessProfile copyWith({
    String? userId,
    String? bodyType,
    String? fitnessGoal,
    String? experienceLevel,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    int? preferredDaysPerWeek,
    DateTime? updatedAt,
  }) {
    return UserFitnessProfile(
      userId: userId ?? this.userId,
      bodyType: bodyType ?? this.bodyType,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      preferredDaysPerWeek: preferredDaysPerWeek ?? this.preferredDaysPerWeek,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
