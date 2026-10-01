/// Domain model representing a Gym Tenant's custom leaderboard rewards and rules.
class TenantRewardConfig {
  final String rank1Title;
  final String rank1Type; // 'membership_extension', 'discount_voucher', 'custom_reward'
  final dynamic rank1Value;
  final String rank2Title;
  final String rank2Type;
  final dynamic rank2Value;
  final String rank3Title;
  final String rank3Type;
  final dynamic rank3Value;
  final int minMonthlyWorkoutsQualification;
  final int tier1Days;
  final double tier1Multiplier;
  final int tier2Days;
  final double tier2Multiplier;
  final int tier3Days;
  final double tier3Multiplier;

  const TenantRewardConfig({
    this.rank1Title = '1-Month Free Access',
    this.rank1Type = 'membership_extension',
    this.rank1Value = 30,
    this.rank2Title = '50% Off Next Renewal',
    this.rank2Type = 'discount_voucher',
    this.rank2Value = 50,
    this.rank3Title = 'Free Whey Shaker & Tub',
    this.rank3Type = 'custom_reward',
    this.rank3Value = 'merch',
    this.minMonthlyWorkoutsQualification = 18,
    this.tier1Days = 14,
    this.tier1Multiplier = 1.10,
    this.tier2Days = 30,
    this.tier2Multiplier = 1.25,
    this.tier3Days = 60,
    this.tier3Multiplier = 1.50,
  });

  factory TenantRewardConfig.fromJson(Map<String, dynamic> json) {
    final rewards = (json['leaderboard_rewards'] as Map<String, dynamic>?) ?? {};
    final r1 = (rewards['rank_1'] as Map<String, dynamic>?) ?? {};
    final r2 = (rewards['rank_2'] as Map<String, dynamic>?) ?? {};
    final r3 = (rewards['rank_3'] as Map<String, dynamic>?) ?? {};

    final tiers = (json['veteran_multiplier_config'] as Map<String, dynamic>?) ?? {};

    return TenantRewardConfig(
      rank1Title: r1['title'] as String? ?? '1-Month Free Access',
      rank1Type: r1['type'] as String? ?? 'membership_extension',
      rank1Value: r1['value'] ?? 30,
      rank2Title: r2['title'] as String? ?? '50% Off Next Renewal',
      rank2Type: r2['type'] as String? ?? 'discount_voucher',
      rank2Value: r2['value'] ?? 50,
      rank3Title: r3['title'] as String? ?? 'Free Whey Shaker & Tub',
      rank3Type: r3['type'] as String? ?? 'custom_reward',
      rank3Value: r3['value'] ?? 'merch',
      minMonthlyWorkoutsQualification: (json['min_monthly_workouts_qualification'] as num?)?.toInt() ?? 18,
      tier1Days: (tiers['tier_1_days'] as num?)?.toInt() ?? 14,
      tier1Multiplier: (tiers['tier_1_multiplier'] as num?)?.toDouble() ?? 1.10,
      tier2Days: (tiers['tier_2_days'] as num?)?.toInt() ?? 30,
      tier2Multiplier: (tiers['tier_2_multiplier'] as num?)?.toDouble() ?? 1.25,
      tier3Days: (tiers['tier_3_days'] as num?)?.toInt() ?? 60,
      tier3Multiplier: (tiers['tier_3_multiplier'] as num?)?.toDouble() ?? 1.50,
    );
  }

  Map<String, dynamic> toJson() => {
    'leaderboard_rewards': {
      'rank_1': {'title': rank1Title, 'type': rank1Type, 'value': rank1Value},
      'rank_2': {'title': rank2Title, 'type': rank2Type, 'value': rank2Value},
      'rank_3': {'title': rank3Title, 'type': rank3Type, 'value': rank3Value},
    },
    'min_monthly_workouts_qualification': minMonthlyWorkoutsQualification,
    'veteran_multiplier_config': {
      'tier_1_days': tier1Days,
      'tier_1_multiplier': tier1Multiplier,
      'tier_2_days': tier2Days,
      'tier_2_multiplier': tier2Multiplier,
      'tier_3_days': tier3Days,
      'tier_3_multiplier': tier3Multiplier,
    },
  };
}
