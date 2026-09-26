import 'package:flutter/foundation.dart';

enum MemberAccountStatus {
  active,
  expired,
  frozen,
  pendingPayment,
}

enum MemberDuesStatus {
  paid,
  unpaid,
  overdue,
  partial,
}

@immutable
class GymMember {
  final String id;
  final String tenantId;
  final String memberCode;
  final String fullName;
  final String phone;
  final String email;
  final String? avatarUrl;
  final MemberAccountStatus status;
  final String planName;
  final DateTime joinDate;
  final DateTime expiryDate;
  final double duesAmount;
  final MemberDuesStatus duesStatus;
  final String? emergencyContact;
  final String? notes;
  final String tempPassword;

  // Deep Fitness Diagnostics & Telemetry
  final String assignedProtocol;
  final String targetGoal;
  final int currentStreakDays;
  final int totalCheckIns;
  final DateTime? lastCheckIn;
  final int currentRoutineDay;
  final String fitnessLevel;

  // Financial Health & Audit Telemetry
  final DateTime? lastPaymentDate;
  final String lastScanGate;
  final String updatedByStaff;
  final String? freezeReason;

  const GymMember({
    required this.id,
    required this.tenantId,
    required this.memberCode,
    required this.fullName,
    required this.phone,
    required this.email,
    this.avatarUrl,
    this.status = MemberAccountStatus.active,
    this.planName = 'Annual VIP Access',
    required this.joinDate,
    required this.expiryDate,
    this.duesAmount = 0.0,
    this.duesStatus = MemberDuesStatus.paid,
    this.emergencyContact,
    this.notes,
    this.tempPassword = 'Gym@2026',
    this.assignedProtocol = 'Mesomorph: Athletic Power & V-Taper',
    this.targetGoal = 'Hypertrophy & V-Taper',
    this.currentStreakDays = 1,
    this.totalCheckIns = 1,
    this.lastCheckIn,
    this.currentRoutineDay = 1,
    this.fitnessLevel = 'Intermediate',
    this.lastPaymentDate,
    this.lastScanGate = 'ESP32 Wi-Fi Turnstile Relay (Main Gate)',
    this.updatedByStaff = 'Owner / Reception Workstation',
    this.freezeReason,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now()) || status == MemberAccountStatus.expired;
  bool get isDuesOverdue => duesAmount > 0 && duesStatus != MemberDuesStatus.paid;
  bool get hasActiveStreak => currentStreakDays >= 3;
  bool get isFrozen => status == MemberAccountStatus.frozen;

  /// Actionable Alert: Member plan expires in next 7 days
  bool get isExpiringSoon {
    if (isExpired || isFrozen) return false;
    final diffHours = expiryDate.difference(DateTime.now()).inHours;
    return diffHours >= 0 && diffHours <= (7 * 24);
  }

  int get daysUntilExpiry {
    final diffHours = expiryDate.difference(DateTime.now()).inHours;
    return (diffHours / 24.0).ceil();
  }

  String get statusDisplay {
    if (isFrozen) return 'FROZEN';
    if (isExpired) return 'EXPIRED';
    switch (status) {
      case MemberAccountStatus.active:
        return 'ACTIVE';
      case MemberAccountStatus.expired:
        return 'EXPIRED';
      case MemberAccountStatus.frozen:
        return 'FROZEN';
      case MemberAccountStatus.pendingPayment:
        return 'PENDING';
    }
  }

  String get duesStatusDisplay {
    if (duesAmount <= 0) return 'PAID';
    switch (duesStatus) {
      case MemberDuesStatus.paid:
        return 'PAID';
      case MemberDuesStatus.unpaid:
        return 'UNPAID';
      case MemberDuesStatus.overdue:
        return 'OVERDUE';
      case MemberDuesStatus.partial:
        return 'PARTIAL';
    }
  }

  GymMember copyWith({
    String? id,
    String? tenantId,
    String? memberCode,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    MemberAccountStatus? status,
    String? planName,
    DateTime? joinDate,
    DateTime? expiryDate,
    double? duesAmount,
    MemberDuesStatus? duesStatus,
    String? emergencyContact,
    String? notes,
    String? tempPassword,
    String? assignedProtocol,
    String? targetGoal,
    int? currentStreakDays,
    int? totalCheckIns,
    DateTime? lastCheckIn,
    int? currentRoutineDay,
    String? fitnessLevel,
    DateTime? lastPaymentDate,
    String? lastScanGate,
    String? updatedByStaff,
    String? freezeReason,
  }) {
    return GymMember(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      memberCode: memberCode ?? this.memberCode,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      planName: planName ?? this.planName,
      joinDate: joinDate ?? this.joinDate,
      expiryDate: expiryDate ?? this.expiryDate,
      duesAmount: duesAmount ?? this.duesAmount,
      duesStatus: duesStatus ?? this.duesStatus,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      notes: notes ?? this.notes,
      tempPassword: tempPassword ?? this.tempPassword,
      assignedProtocol: assignedProtocol ?? this.assignedProtocol,
      targetGoal: targetGoal ?? this.targetGoal,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      totalCheckIns: totalCheckIns ?? this.totalCheckIns,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      currentRoutineDay: currentRoutineDay ?? this.currentRoutineDay,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      lastScanGate: lastScanGate ?? this.lastScanGate,
      updatedByStaff: updatedByStaff ?? this.updatedByStaff,
      freezeReason: freezeReason ?? this.freezeReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'member_code': memberCode,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'status': status.name,
      'plan_name': planName,
      'join_date': joinDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'dues_amount': duesAmount,
      'dues_status': duesStatus.name,
      'emergency_contact': emergencyContact,
      'notes': notes,
      'temp_password': tempPassword,
      'assigned_protocol': assignedProtocol,
      'target_goal': targetGoal,
      'current_streak_days': currentStreakDays,
      'total_check_ins': totalCheckIns,
      'last_check_in': lastCheckIn?.toIso8601String(),
      'current_routine_day': currentRoutineDay,
      'fitness_level': fitnessLevel,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'last_scan_gate': lastScanGate,
      'updated_by_staff': updatedByStaff,
      'freeze_reason': freezeReason,
    };
  }

  factory GymMember.fromJson(Map<String, dynamic> json) {
    MemberAccountStatus parseStatus(String? val) {
      if (val == null) return MemberAccountStatus.active;
      final lower = val.toLowerCase().replaceAll('_', '');
      if (lower.contains('expir')) return MemberAccountStatus.expired;
      if (lower.contains('froz')) return MemberAccountStatus.frozen;
      if (lower.contains('pend')) return MemberAccountStatus.pendingPayment;
      return MemberAccountStatus.active;
    }

    MemberDuesStatus parseDues(String? val, double amount) {
      if (amount <= 0) return MemberDuesStatus.paid;
      if (val == null) return MemberDuesStatus.unpaid;
      final lower = val.toLowerCase();
      if (lower.contains('paid') && !lower.contains('unpaid')) return MemberDuesStatus.paid;
      if (lower.contains('overdue')) return MemberDuesStatus.overdue;
      if (lower.contains('part')) return MemberDuesStatus.partial;
      return MemberDuesStatus.unpaid;
    }

    final double duesVal = (json['dues_amount'] as num?)?.toDouble() ?? 0.0;

    return GymMember(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      memberCode: json['member_code'] as String? ?? 'GC-M-000',
      fullName: json['full_name'] as String? ?? 'Unnamed Member',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      status: parseStatus(json['status'] as String?),
      planName: json['plan_name'] as String? ?? 'Standard Gym Access',
      joinDate: json['join_date'] != null
          ? DateTime.tryParse(json['join_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString()) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      duesAmount: duesVal,
      duesStatus: parseDues(json['dues_status'] as String?, duesVal),
      emergencyContact: json['emergency_contact'] as String?,
      notes: json['notes'] as String?,
      tempPassword: json['temp_password'] as String? ?? 'Gym@2026',
      assignedProtocol: json['assigned_protocol'] as String? ?? 'Mesomorph: Athletic Power & V-Taper',
      targetGoal: json['target_goal'] as String? ?? 'Hypertrophy & Conditioning',
      currentStreakDays: (json['current_streak_days'] as num?)?.toInt() ?? 0,
      totalCheckIns: (json['total_check_ins'] as num?)?.toInt() ?? 0,
      lastCheckIn: json['last_check_in'] != null ? DateTime.tryParse(json['last_check_in'].toString()) : null,
      currentRoutineDay: (json['current_routine_day'] as num?)?.toInt() ?? 1,
      fitnessLevel: json['fitness_level'] as String? ?? 'Intermediate',
      lastPaymentDate: json['last_payment_date'] != null ? DateTime.tryParse(json['last_payment_date'].toString()) : null,
      lastScanGate: json['last_scan_gate'] as String? ?? 'ESP32 Wi-Fi Turnstile Relay (Main Gate)',
      updatedByStaff: json['updated_by_staff'] as String? ?? 'Owner / Reception Workstation',
      freezeReason: json['freeze_reason'] as String?,
    );
  }
}
