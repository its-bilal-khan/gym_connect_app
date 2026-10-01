/// Immutable domain model representing Super Admin & Tenant-configurable Vision AI settings.
class VisionAiConfig {
  final bool isLiveTrainerEnabled;
  final double squatDepthAngle;
  final double pushupDepthAngle;
  final int badPostureTriggerMs;
  final double ttsCooldownSeconds;
  final int microClipDurationSec;
  final bool allowTenantOverride;

  const VisionAiConfig({
    this.isLiveTrainerEnabled = true,
    this.squatDepthAngle = 90.0,
    this.pushupDepthAngle = 85.0,
    this.badPostureTriggerMs = 1000,
    this.ttsCooldownSeconds = 3.2,
    this.microClipDurationSec = 8,
    this.allowTenantOverride = true,
  });

  factory VisionAiConfig.fromJson(Map<String, dynamic> json) {
    return VisionAiConfig(
      isLiveTrainerEnabled: json['is_live_trainer_enabled'] as bool? ?? true,
      squatDepthAngle: (json['squat_depth_angle'] as num?)?.toDouble() ?? 90.0,
      pushupDepthAngle: (json['pushup_depth_angle'] as num?)?.toDouble() ?? 85.0,
      badPostureTriggerMs: (json['bad_posture_trigger_ms'] as num?)?.toInt() ?? 1000,
      ttsCooldownSeconds: (json['tts_cooldown_seconds'] as num?)?.toDouble() ?? 3.2,
      microClipDurationSec: (json['micro_clip_duration_sec'] as num?)?.toInt() ?? 8,
      allowTenantOverride: json['allow_tenant_override'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_live_trainer_enabled': isLiveTrainerEnabled,
        'squat_depth_angle': squatDepthAngle,
        'pushup_depth_angle': pushupDepthAngle,
        'bad_posture_trigger_ms': badPostureTriggerMs,
        'tts_cooldown_seconds': ttsCooldownSeconds,
        'micro_clip_duration_sec': microClipDurationSec,
        'allow_tenant_override': allowTenantOverride,
      };

  VisionAiConfig copyWith({
    bool? isLiveTrainerEnabled,
    double? squatDepthAngle,
    double? pushupDepthAngle,
    int? badPostureTriggerMs,
    double? ttsCooldownSeconds,
    int? microClipDurationSec,
    bool? allowTenantOverride,
  }) {
    return VisionAiConfig(
      isLiveTrainerEnabled: isLiveTrainerEnabled ?? this.isLiveTrainerEnabled,
      squatDepthAngle: squatDepthAngle ?? this.squatDepthAngle,
      pushupDepthAngle: pushupDepthAngle ?? this.pushupDepthAngle,
      badPostureTriggerMs: badPostureTriggerMs ?? this.badPostureTriggerMs,
      ttsCooldownSeconds: ttsCooldownSeconds ?? this.ttsCooldownSeconds,
      microClipDurationSec: microClipDurationSec ?? this.microClipDurationSec,
      allowTenantOverride: allowTenantOverride ?? this.allowTenantOverride,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionAiConfig &&
          runtimeType == other.runtimeType &&
          isLiveTrainerEnabled == other.isLiveTrainerEnabled &&
          squatDepthAngle == other.squatDepthAngle &&
          pushupDepthAngle == other.pushupDepthAngle &&
          badPostureTriggerMs == other.badPostureTriggerMs &&
          ttsCooldownSeconds == other.ttsCooldownSeconds &&
          microClipDurationSec == other.microClipDurationSec &&
          allowTenantOverride == other.allowTenantOverride;

  @override
  int get hashCode => Object.hash(
        isLiveTrainerEnabled,
        squatDepthAngle,
        pushupDepthAngle,
        badPostureTriggerMs,
        ttsCooldownSeconds,
        microClipDurationSec,
        allowTenantOverride,
      );
}
