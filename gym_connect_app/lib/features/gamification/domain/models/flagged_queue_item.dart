/// Domain model for moderation queue items requiring gym owner audit and potential clawback.
class FlaggedQueueItem {
  final String id;
  final String tenantId;
  final String userId;
  final String? memberName;
  final String proofType; // 'diet_photo', 'workout_video', 'manual_steps'
  final String proofUrl;
  final int pointsAwarded;
  final String status; // 'pending_review', 'approved', 'deducted'
  final String? flaggedReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const FlaggedQueueItem({
    required this.id,
    required this.tenantId,
    required this.userId,
    this.memberName,
    required this.proofType,
    required this.proofUrl,
    required this.pointsAwarded,
    this.status = 'pending_review',
    this.flaggedReason,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
  });

  bool get isPending => status == 'pending_review';
  bool get isDeducted => status == 'deducted';
  bool get isApproved => status == 'approved';

  factory FlaggedQueueItem.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return FlaggedQueueItem(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      memberName: profile?['full_name'] as String? ?? json['member_name'] as String?,
      proofType: json['proof_type'] as String? ?? 'diet_photo',
      proofUrl: json['proof_url'] as String? ?? '',
      pointsAwarded: (json['points_awarded'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending_review',
      flaggedReason: json['flagged_reason'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'user_id': userId,
    'proof_type': proofType,
    'proof_url': proofUrl,
    'points_awarded': pointsAwarded,
    'status': status,
    'flagged_reason': flaggedReason,
    'reviewed_by': reviewedBy,
  };
}
