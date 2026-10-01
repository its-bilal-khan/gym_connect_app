/// Domain model representing a member ranking in active monthly race or Hall of Fame.
class LeaderboardMember {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final int monthlyPoints;
  final int totalPoints;
  final int currentStreakDays;
  final int longestStreakDays;
  final int monthlyWorkoutsCompleted;
  final double streakMultiplier;
  final bool isEliteQualified;
  final int rank;
  final bool isCurrentUser;
  final int? lastMonthRank;

  const LeaderboardMember({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.monthlyPoints = 0,
    this.totalPoints = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.monthlyWorkoutsCompleted = 0,
    this.streakMultiplier = 1.00,
    this.isEliteQualified = false,
    this.rank = 0,
    this.isCurrentUser = false,
    this.lastMonthRank,
  });

  bool get isPodium => rank >= 1 && rank <= 3;

  String get rankTitle {
    if (currentStreakDays >= 60) return 'Legendary Titan 🔥';
    if (currentStreakDays >= 30) return 'Beast Mode Elite ⚡';
    if (currentStreakDays >= 14) return 'Iron Warrior 🛡️';
    return 'Rising Contender ⭐';
  }

  factory LeaderboardMember.fromJson(Map<String, dynamic> json, {String? currentUserId, int calculatedRank = 0}) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final uid = json['user_id'] as String? ?? json['id'] as String? ?? '';
    return LeaderboardMember(
      userId: uid,
      fullName: profile?['full_name'] as String? ?? json['full_name'] as String? ?? 'Gym Member',
      avatarUrl: profile?['avatar_url'] as String? ?? json['avatar_url'] as String?,
      monthlyPoints: (json['monthly_points'] as num?)?.toInt() ?? 0,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      currentStreakDays: (json['current_streak_days'] as num?)?.toInt() ?? 0,
      longestStreakDays: (json['longest_streak_days'] as num?)?.toInt() ?? 0,
      monthlyWorkoutsCompleted: (json['monthly_workouts_completed'] as num?)?.toInt() ?? 0,
      streakMultiplier: (json['streak_multiplier'] as num?)?.toDouble() ?? 1.00,
      isEliteQualified: json['is_elite_qualified'] as bool? ?? false,
      rank: (json['rank'] as num?)?.toInt() ?? calculatedRank,
      isCurrentUser: currentUserId != null && uid == currentUserId,
      lastMonthRank: (json['last_month_rank'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'monthly_points': monthlyPoints,
    'total_points': totalPoints,
    'current_streak_days': currentStreakDays,
    'longest_streak_days': longestStreakDays,
    'monthly_workouts_completed': monthlyWorkoutsCompleted,
    'streak_multiplier': streakMultiplier,
    'is_elite_qualified': isEliteQualified,
    'rank': rank,
    'is_current_user': isCurrentUser,
    'last_month_rank': lastMonthRank,
  };
}
