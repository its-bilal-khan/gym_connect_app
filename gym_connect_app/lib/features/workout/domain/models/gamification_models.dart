class MemberGamificationData {
  final String userId;
  final int currentStreakDays;
  final int longestStreakDays;
  final int totalPoints;
  final int weeklyPoints;
  final String rankTitle;

  const MemberGamificationData({
    required this.userId,
    this.currentStreakDays = 5,
    this.longestStreakDays = 12,
    this.totalPoints = 850,
    this.weeklyPoints = 250,
    this.rankTitle = 'Iron Warrior',
  });

  factory MemberGamificationData.fromJson(Map<String, dynamic> json) {
    final streak = (json['current_streak_days'] as int?) ?? 1;
    return MemberGamificationData(
      userId: json['user_id'] as String? ?? '',
      currentStreakDays: streak,
      longestStreakDays: (json['longest_streak_days'] as int?) ?? streak,
      totalPoints: (json['total_points'] as int?) ?? 0,
      weeklyPoints: (json['weekly_points'] as int?) ?? 0,
      rankTitle: calculateRankTitle(streak),
    );
  }

  static String calculateRankTitle(int streak) {
    if (streak >= 30) return 'Legendary Titan';
    if (streak >= 14) return 'Beast Mode Elite';
    if (streak >= 7) return 'Iron Warrior';
    return 'Rising Contender';
  }
}

class LeaderboardEntry {
  final String id;
  final String name;
  final int streakDays;
  final int totalPoints;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.streakDays,
    required this.totalPoints,
    required this.rank,
    this.isCurrentUser = false,
  });
}
