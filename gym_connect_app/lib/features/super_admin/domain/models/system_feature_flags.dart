/// Domain model representing resolved enterprise module feature flags.
class SystemFeatureFlags {
  final bool aiWorkouts;
  final bool gamification;
  final bool dietLogs;
  final bool clinicalTools;
  final int maxAllowedAiAge;
  final Map<String, bool> allowTenantOverrides;

  const SystemFeatureFlags({
    this.aiWorkouts = true,
    this.gamification = true,
    this.dietLogs = true,
    this.clinicalTools = true,
    this.maxAllowedAiAge = 55,
    this.allowTenantOverrides = const {},
  });

  bool isEnabled(String featureKey) {
    switch (featureKey) {
      case 'ai_workouts':
        return aiWorkouts;
      case 'gamification':
        return gamification;
      case 'diet_logs':
        return dietLogs;
      case 'clinical_tools':
        return clinicalTools;
      default:
        return true;
    }
  }

  bool isFeatureEnabled(String featureKey) => isEnabled(featureKey);

  bool canTenantOverride(String featureKey) {
    return allowTenantOverrides[featureKey] ?? false;
  }

  factory SystemFeatureFlags.fromJson(Map<String, dynamic> json) {
    final overrides = <String, bool>{};
    if (json['allow_tenant_overrides'] is Map) {
      (json['allow_tenant_overrides'] as Map).forEach((k, v) {
        overrides[k.toString()] = v == true;
      });
    }

    return SystemFeatureFlags(
      aiWorkouts: json['ai_workouts'] as bool? ?? true,
      gamification: json['gamification'] as bool? ?? true,
      dietLogs: json['diet_logs'] as bool? ?? true,
      clinicalTools: json['clinical_tools'] as bool? ?? true,
      maxAllowedAiAge: (json['max_allowed_ai_age'] as num?)?.toInt() ??
          ((json['ai_workout_config'] as Map?)?['max_allowed_ai_age'] as num?)?.toInt() ??
          55,
      allowTenantOverrides: overrides,
    );
  }

  Map<String, dynamic> toJson() => {
        'ai_workouts': aiWorkouts,
        'gamification': gamification,
        'diet_logs': dietLogs,
        'clinical_tools': clinicalTools,
        'max_allowed_ai_age': maxAllowedAiAge,
        'allow_tenant_overrides': allowTenantOverrides,
      };

  SystemFeatureFlags copyWith({
    bool? aiWorkouts,
    bool? gamification,
    bool? dietLogs,
    bool? clinicalTools,
    int? maxAllowedAiAge,
    Map<String, bool>? allowTenantOverrides,
  }) {
    return SystemFeatureFlags(
      aiWorkouts: aiWorkouts ?? this.aiWorkouts,
      gamification: gamification ?? this.gamification,
      dietLogs: dietLogs ?? this.dietLogs,
      clinicalTools: clinicalTools ?? this.clinicalTools,
      maxAllowedAiAge: maxAllowedAiAge ?? this.maxAllowedAiAge,
      allowTenantOverrides:
          allowTenantOverrides ?? this.allowTenantOverrides,
    );
  }
}

/// Global system configuration setting managed exclusively by Super Admin.
class GlobalSystemConfig {
  final String key;
  final Map<String, dynamic> value;
  final bool allowTenantOverride;
  final String? description;
  final DateTime? updatedAt;

  const GlobalSystemConfig({
    required this.key,
    required this.value,
    this.allowTenantOverride = false,
    this.description,
    this.updatedAt,
  });

  factory GlobalSystemConfig.fromJson(Map<String, dynamic> json) {
    return GlobalSystemConfig(
      key: json['key'] as String? ?? '',
      value: (json['value'] as Map<String, dynamic>?) ?? {},
      allowTenantOverride: json['allow_tenant_override'] as bool? ?? false,
      description: json['description'] as String?,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'allow_tenant_override': allowTenantOverride,
        'description': description,
        'updated_at': updatedAt?.toIso8601String(),
      };

  GlobalSystemConfig copyWith({
    String? key,
    Map<String, dynamic>? value,
    bool? allowTenantOverride,
    String? description,
    DateTime? updatedAt,
  }) {
    return GlobalSystemConfig(
      key: key ?? this.key,
      value: value ?? this.value,
      allowTenantOverride:
          allowTenantOverride ?? this.allowTenantOverride,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
