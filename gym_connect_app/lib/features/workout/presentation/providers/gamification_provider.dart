import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/gamification_models.dart';

final gamificationProvider =
    NotifierProvider<GamificationNotifier, MemberGamificationData>(
        GamificationNotifier.new);

final leaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  final notifier = ref.read(gamificationProvider.notifier);
  return notifier.fetchLeaderboard();
});

class GamificationNotifier extends Notifier<MemberGamificationData> {
  SupabaseClient? _client;

  @override
  MemberGamificationData build() {
    try {
      _client = Supabase.instance.client;
    } catch (e) {
      debugPrint('GamificationNotifier: Supabase client unavailable: $e');
    }
    Future.microtask(() => loadGamification());
    return const MemberGamificationData(userId: 'local-member');
  }

  Future<void> loadGamification() async {
    final client = _client;
    if (client == null) return;

    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await client
          .from('member_gamification')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (res != null) {
        state = MemberGamificationData.fromJson(res);
      }
    } catch (e) {
      debugPrint('GamificationNotifier: loadGamification error: $e');
    }
  }

  Future<void> awardWorkoutCompletionPoints({int points = 100}) async {
    final updatedStreak = state.currentStreakDays + 1;
    final updatedPoints = state.totalPoints + points;

    state = MemberGamificationData(
      userId: state.userId,
      currentStreakDays: updatedStreak,
      longestStreakDays: updatedStreak > state.longestStreakDays
          ? updatedStreak
          : state.longestStreakDays,
      totalPoints: updatedPoints,
      weeklyPoints: state.weeklyPoints + points,
      rankTitle: MemberGamificationData.calculateRankTitle(updatedStreak),
    );

    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        await client.from('member_gamification').upsert({
          'user_id': userId,
          'current_streak_days': updatedStreak,
          'total_points': updatedPoints,
          'last_activity_date':
              DateTime.now().toIso8601String().split('T').first,
        }, onConflict: 'user_id');
      } catch (e) {
        debugPrint('GamificationNotifier: awardPoints error: $e');
      }
    }
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('member_gamification')
            .select('user_id, current_streak_days, total_points, profiles(full_name)')
            .order('total_points', ascending: false)
            .limit(10);

        if (res.isNotEmpty) {
          final currentUserId = client.auth.currentUser?.id;
          return List.generate(res.length, (i) {
            final row = res[i];
            final profile = row['profiles'] as Map<String, dynamic>?;
            return LeaderboardEntry(
              id: row['user_id'] as String? ?? 'user-$i',
              name: profile?['full_name'] as String? ?? 'Gym Warrior #${i + 1}',
              streakDays: (row['current_streak_days'] as int?) ?? 1,
              totalPoints: (row['total_points'] as int?) ?? 0,
              rank: i + 1,
              isCurrentUser: row['user_id'] == currentUserId,
            );
          });
        }
      } catch (e) {
        debugPrint('GamificationNotifier: fetchLeaderboard error: $e');
      }
    }

    // Default seeded leaderboard rankings for testability
    return [
      const LeaderboardEntry(id: 'u-1', name: 'Zaid Khan', streakDays: 14, totalPoints: 1850, rank: 1),
      const LeaderboardEntry(id: 'u-2', name: 'Bilal Ahmed', streakDays: 11, totalPoints: 1420, rank: 2),
      LeaderboardEntry(id: state.userId, name: 'You (Champion)', streakDays: state.currentStreakDays, totalPoints: state.totalPoints, rank: 3, isCurrentUser: true),
      const LeaderboardEntry(id: 'u-4', name: 'Hamza Malik', streakDays: 4, totalPoints: 720, rank: 4),
      const LeaderboardEntry(id: 'u-5', name: 'Ali Raza', streakDays: 3, totalPoints: 510, rank: 5),
    ];
  }
}
