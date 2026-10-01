/// Domain model representing a member's daily 80% composite task audit log.
class DailyGamificationLog {
  final String? id;
  final String tenantId;
  final String userId;
  final String logDate;
  final String? deviceIdUsed;
  final int workoutAssignedSets;
  final int workoutCompletedSets;
  final double workoutCompletionPct;
  final int stepTarget;
  final int stepActual;
  final double stepCompletionPct;
  final String stepSource;
  final String dietLoggedType;
  final String? dietProofUrl;
  final double sleepLoggedHours;
  final String sleepSource;
  final int sleepAsleepMinutes;
  final bool gateCheckinVerified;
  final double compositeCompletionPct;
  final int pointsAwarded;
  final int penaltyDeducted;
  final bool isUnexcusedAbsence;
  final bool streakSaved;
  final String? notes;
  final DateTime? createdAt;

  const DailyGamificationLog({
    this.id,
    required this.tenantId,
    required this.userId,
    required this.logDate,
    this.deviceIdUsed,
    this.workoutAssignedSets = 0,
    this.workoutCompletedSets = 0,
    this.workoutCompletionPct = 0.0,
    this.stepTarget = 10000,
    this.stepActual = 0,
    this.stepCompletionPct = 0.0,
    this.stepSource = 'live_pedometer',
    this.dietLoggedType = 'none',
    this.dietProofUrl,
    this.sleepLoggedHours = 0.0,
    this.sleepSource = 'none',
    this.sleepAsleepMinutes = 0,
    this.gateCheckinVerified = false,
    this.compositeCompletionPct = 0.0,
    this.pointsAwarded = 0,
    this.penaltyDeducted = 0,
    this.isUnexcusedAbsence = false,
    this.streakSaved = false,
    this.notes,
    this.createdAt,
  });

  bool get isCompositeGoalMet => compositeCompletionPct >= 80.0;
  bool get hasActivePenalty => penaltyDeducted > 0 || isUnexcusedAbsence;

  factory DailyGamificationLog.fromJson(Map<String, dynamic> json) {
    return DailyGamificationLog(
      id: json['id'] as String?,
      tenantId: json['tenant_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      logDate: json['log_date'] as String? ?? '',
      deviceIdUsed: json['device_id_used'] as String?,
      workoutAssignedSets: (json['workout_assigned_sets'] as num?)?.toInt() ?? 0,
      workoutCompletedSets: (json['workout_completed_sets'] as num?)?.toInt() ?? 0,
      workoutCompletionPct: (json['workout_completion_pct'] as num?)?.toDouble() ?? 0.0,
      stepTarget: (json['step_target'] as num?)?.toInt() ?? 10000,
      stepActual: (json['step_actual'] as num?)?.toInt() ?? 0,
      stepCompletionPct: (json['step_completion_pct'] as num?)?.toDouble() ?? 0.0,
      stepSource: json['step_source'] as String? ?? 'live_pedometer',
      dietLoggedType: json['diet_logged_type'] as String? ?? 'none',
      dietProofUrl: json['diet_proof_url'] as String?,
      sleepLoggedHours: (json['sleep_logged_hours'] as num?)?.toDouble() ?? 0.0,
      sleepSource: json['sleep_source'] as String? ?? 'none',
      sleepAsleepMinutes: (json['sleep_asleep_minutes'] as num?)?.toInt() ?? 0,
      gateCheckinVerified: json['gate_checkin_verified'] as bool? ?? false,
      compositeCompletionPct: (json['composite_completion_pct'] as num?)?.toDouble() ?? 0.0,
      pointsAwarded: (json['points_awarded'] as num?)?.toInt() ?? 0,
      penaltyDeducted: (json['penalty_deducted'] as num?)?.toInt() ?? 0,
      isUnexcusedAbsence: json['is_unexcused_absence'] as bool? ?? false,
      streakSaved: json['streak_saved'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'tenant_id': tenantId,
    'user_id': userId,
    'log_date': logDate,
    'device_id_used': deviceIdUsed,
    'workout_assigned_sets': workoutAssignedSets,
    'workout_completed_sets': workoutCompletedSets,
    'workout_completion_pct': workoutCompletionPct,
    'step_target': stepTarget,
    'step_actual': stepActual,
    'step_completion_pct': stepCompletionPct,
    'step_source': stepSource,
    'diet_logged_type': dietLoggedType,
    'diet_proof_url': dietProofUrl,
    'sleep_logged_hours': sleepLoggedHours,
    'sleep_source': sleepSource,
    'sleep_asleep_minutes': sleepAsleepMinutes,
    'gate_checkin_verified': gateCheckinVerified,
    'composite_completion_pct': compositeCompletionPct,
    'points_awarded': pointsAwarded,
    'penalty_deducted': penaltyDeducted,
    'is_unexcused_absence': isUnexcusedAbsence,
    'streak_saved': streakSaved,
    'notes': notes,
  };
}
