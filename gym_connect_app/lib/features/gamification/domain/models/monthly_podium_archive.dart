/// Domain model representing historical monthly podium records and reward fulfillments.
class MonthlyPodiumArchive {
  final String id;
  final String tenantId;
  final String monthYear; // 'YYYY-MM'
  final int podiumRank; // 1, 2, 3
  final String userId;
  final String? memberName;
  final int pointsScored;
  final int streakAtFinish;
  final String rewardTitle;
  final String rewardType;
  final int rewardValue;
  final bool isFulfilled;
  final String? subscriptionIdExtended;
  final String? invoiceIdGenerated;
  final DateTime? fulfilledAt;
  final DateTime? createdAt;

  const MonthlyPodiumArchive({
    required this.id,
    required this.tenantId,
    required this.monthYear,
    required this.podiumRank,
    required this.userId,
    this.memberName,
    required this.pointsScored,
    required this.streakAtFinish,
    required this.rewardTitle,
    required this.rewardType,
    this.rewardValue = 30,
    this.isFulfilled = false,
    this.subscriptionIdExtended,
    this.invoiceIdGenerated,
    this.fulfilledAt,
    this.createdAt,
  });

  factory MonthlyPodiumArchive.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return MonthlyPodiumArchive(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      monthYear: json['month_year'] as String? ?? '',
      podiumRank: (json['podium_rank'] as num?)?.toInt() ?? 1,
      userId: json['user_id'] as String? ?? '',
      memberName: profile?['full_name'] as String? ?? json['member_name'] as String?,
      pointsScored: (json['points_scored'] as num?)?.toInt() ?? 0,
      streakAtFinish: (json['streak_at_finish'] as num?)?.toInt() ?? 0,
      rewardTitle: json['reward_title'] as String? ?? 'Podium Prize',
      rewardType: json['reward_type'] as String? ?? 'membership_extension',
      rewardValue: (json['reward_value'] as num?)?.toInt() ?? 30,
      isFulfilled: json['is_fulfilled'] as bool? ?? false,
      subscriptionIdExtended: json['subscription_id_extended'] as String?,
      invoiceIdGenerated: json['invoice_id_generated'] as String?,
      fulfilledAt: DateTime.tryParse(json['fulfilled_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'month_year': monthYear,
    'podium_rank': podiumRank,
    'user_id': userId,
    'points_scored': pointsScored,
    'streak_at_finish': streakAtFinish,
    'reward_title': rewardTitle,
    'reward_type': rewardType,
    'reward_value': rewardValue,
    'is_fulfilled': isFulfilled,
    'subscription_id_extended': subscriptionIdExtended,
    'invoice_id_generated': invoiceIdGenerated,
  };
}
