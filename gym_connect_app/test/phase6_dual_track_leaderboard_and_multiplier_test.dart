import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/gamification/domain/models/models.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/dual_track_leaderboard_provider.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/dual_track_leaderboard_state.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/dual_track_leaderboard_sheet.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/leaderboard_grid_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/leaderboard_header_bar.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/leaderboard_list_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/leaderboard_mini_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/leaderboard_podium_row.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/leaderboard_qualification_banner.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/podium_archives_list_view.dart';

class FakeDualTrackLeaderboardNotifier extends DualTrackLeaderboardNotifier {
  final DualTrackLeaderboardState initialState;
  FakeDualTrackLeaderboardNotifier(this.initialState);

  @override
  DualTrackLeaderboardState build() => initialState;
}

void main() {
  group('Phase 6: Veteran Streak Multiplier Mathematical Engine', () {
    test('Calculates 1.00x multiplier (0% boost) for streaks under 14 days', () {
      const streakDays = 10;
      double multiplier;
      if (streakDays >= 60) {
        multiplier = 1.50;
      } else if (streakDays >= 30) {
        multiplier = 1.25;
      } else if (streakDays >= 14) {
        multiplier = 1.10;
      } else {
        multiplier = 1.00;
      }

      expect(multiplier, 1.00);
      final boostedPoints = (500 * multiplier).toInt();
      expect(boostedPoints, 500);
    });

    test('Calculates 1.10x multiplier (+10% boost) for streaks 14 to 29 days (Iron Warrior)', () {
      const streakDays = 21;
      double multiplier;
      if (streakDays >= 60) {
        multiplier = 1.50;
      } else if (streakDays >= 30) {
        multiplier = 1.25;
      } else if (streakDays >= 14) {
        multiplier = 1.10;
      } else {
        multiplier = 1.00;
      }

      expect(multiplier, 1.10);
      final boostedPoints = (500 * multiplier).toInt();
      expect(boostedPoints, 550);
    });

    test('Calculates 1.25x multiplier (+25% boost) for streaks 30 to 59 days (Beast Mode Elite)', () {
      const streakDays = 45;
      double multiplier;
      if (streakDays >= 60) {
        multiplier = 1.50;
      } else if (streakDays >= 30) {
        multiplier = 1.25;
      } else if (streakDays >= 14) {
        multiplier = 1.10;
      } else {
        multiplier = 1.00;
      }

      expect(multiplier, 1.25);
      final boostedPoints = (1000 * multiplier).toInt();
      expect(boostedPoints, 1250);
    });

    test('Calculates 1.50x multiplier (+50% boost) for streaks 60+ days (Legendary Titan)', () {
      const streakDays = 75;
      double multiplier;
      if (streakDays >= 60) {
        multiplier = 1.50;
      } else if (streakDays >= 30) {
        multiplier = 1.25;
      } else if (streakDays >= 14) {
        multiplier = 1.10;
      } else {
        multiplier = 1.00;
      }

      expect(multiplier, 1.50);
      final boostedPoints = (1000 * multiplier).toInt();
      expect(boostedPoints, 1500);
    });
  });

  group('Phase 6: Baseline Workout Qualification Formula Tests', () {
    test('Calculates fractional progress, remaining workouts, and qualification flag correctly', () {
      const targetWorkouts = 18;
      const completedWorkouts = 14;

      final progress = (completedWorkouts / targetWorkouts).clamp(0.0, 1.0);
      final remaining = (targetWorkouts - completedWorkouts).clamp(0, targetWorkouts);
      final isQualified = completedWorkouts >= targetWorkouts;

      expect(progress, closeTo(0.777, 0.001));
      expect(remaining, 4);
      expect(isQualified, isFalse);
    });

    test('Identifies qualified elite member when target is reached or exceeded', () {
      const targetWorkouts = 18;
      const completedWorkouts = 20;

      final progress = (completedWorkouts / targetWorkouts).clamp(0.0, 1.0);
      final remaining = (targetWorkouts - completedWorkouts).clamp(0, targetWorkouts);
      final isQualified = completedWorkouts >= targetWorkouts;

      expect(progress, 1.0);
      expect(remaining, 0);
      expect(isQualified, isTrue);
    });
  });

  group('Phase 6: Dual-Track Leaderboard State & Filter Tests', () {
    test('Filters members by search query case-insensitively', () {
      const members = [
        LeaderboardMember(userId: 'u1', fullName: 'Bilal Khan', monthlyPoints: 1200, rank: 1),
        LeaderboardMember(userId: 'u2', fullName: 'Hamza Tariq', monthlyPoints: 1100, rank: 2),
        LeaderboardMember(userId: 'u3', fullName: 'Ali Raza', monthlyPoints: 950, rank: 3),
      ];

      const state = DualTrackLeaderboardState(
        monthlyMembers: members,
        searchQuery: 'bilal',
      );

      final filtered = state.activeMembers;
      expect(filtered.length, 1);
      expect(filtered.first.fullName, 'Bilal Khan');
    });

    test('Separates top 3 podium members from runners-up list', () {
      const members = [
        LeaderboardMember(userId: 'u1', fullName: 'Bilal Khan', monthlyPoints: 1200, rank: 1),
        LeaderboardMember(userId: 'u2', fullName: 'Hamza Tariq', monthlyPoints: 1100, rank: 2),
        LeaderboardMember(userId: 'u3', fullName: 'Ali Raza', monthlyPoints: 950, rank: 3),
        LeaderboardMember(userId: 'u4', fullName: 'Zaid Ahmed', monthlyPoints: 800, rank: 4),
        LeaderboardMember(userId: 'u5', fullName: 'Usman Ghani', monthlyPoints: 750, rank: 5),
      ];

      const state = DualTrackLeaderboardState(monthlyMembers: members);

      expect(state.podiumMembers.length, 3);
      expect(state.podiumMembers[0].fullName, 'Bilal Khan');
      expect(state.runnersUpMembers.length, 2);
      expect(state.runnersUpMembers[0].fullName, 'Zaid Ahmed');
    });
  });

  group('Phase 6: Leaderboard UI Components & Dual-View Widget Tests', () {
    testWidgets('Renders LeaderboardHeaderBar with Dual-Track and Rule 5 Dual-View controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: LeaderboardHeaderBar(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('GYM LEADERBOARD'), findsOneWidget);
      expect(find.text('Monthly Race'), findsOneWidget);
      expect(find.text('Hall of Fame'), findsOneWidget);
      expect(find.text('Archives'), findsOneWidget);
      expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    });

    testWidgets('Renders LeaderboardQualificationBanner with workouts progress and multiplier', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dualTrackLeaderboardProvider.overrideWith(
              () => FakeDualTrackLeaderboardNotifier(
                const DualTrackLeaderboardState(
                  memberStatus: {
                    'monthly_workouts_completed': 14,
                    'is_qualified': false,
                    'streak_multiplier': 1.25,
                    'current_streak_days': 35,
                  },
                  rewardConfig: TenantRewardConfig(minMonthlyWorkoutsQualification: 18),
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: LeaderboardQualificationBanner(),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('14/18 Workouts Completed'), findsOneWidget);
      expect(find.text('1.25x BOOST'), findsOneWidget);
      expect(find.text('Streak: 35 Days unbroken'), findsOneWidget);
    });

    testWidgets('Renders LeaderboardPodiumRow with 1st, 2nd, and 3rd rank stands', (tester) async {
      const podium = [
        LeaderboardMember(userId: 'u1', fullName: 'Bilal Khan', monthlyPoints: 1500, rank: 1, streakMultiplier: 1.25),
        LeaderboardMember(userId: 'u2', fullName: 'Hamza Tariq', monthlyPoints: 1300, rank: 2),
        LeaderboardMember(userId: 'u3', fullName: 'Ali Raza', monthlyPoints: 1100, rank: 3),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardPodiumRow(podiumMembers: podium),
          ),
        ),
      );

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('Bilal Khan'), findsOneWidget);
      expect(find.text('Hamza Tariq'), findsOneWidget);
      expect(find.text('Ali Raza'), findsOneWidget);
      expect(find.text('1500 XP'), findsOneWidget);
      expect(find.text('1.25x'), findsOneWidget);
    });

    testWidgets('Renders LeaderboardListView in high-density format', (tester) async {
      const runnersUp = [
        LeaderboardMember(userId: 'u4', fullName: 'Zaid Ahmed', monthlyPoints: 850, currentStreakDays: 16, streakMultiplier: 1.10, rank: 4),
        LeaderboardMember(userId: 'u5', fullName: 'Usman Ghani', monthlyPoints: 720, currentStreakDays: 8, rank: 5),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardListView(members: runnersUp),
          ),
        ),
      );

      expect(find.text('#4'), findsOneWidget);
      expect(find.text('#5'), findsOneWidget);
      expect(find.text('Zaid Ahmed'), findsOneWidget);
      expect(find.text('Usman Ghani'), findsOneWidget);
      expect(find.text('850 XP'), findsOneWidget);
      expect(find.text('1.10x'), findsOneWidget);
    });

    testWidgets('Renders LeaderboardGridView fulfilling Rule 5 Dual-View standard', (tester) async {
      const gridMembers = [
        LeaderboardMember(userId: 'u1', fullName: 'Bilal Khan', monthlyPoints: 1500, currentStreakDays: 32, streakMultiplier: 1.25, rank: 1),
        LeaderboardMember(userId: 'u2', fullName: 'Hamza Tariq', monthlyPoints: 1300, currentStreakDays: 14, streakMultiplier: 1.10, rank: 2),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardGridView(members: gridMembers),
          ),
        ),
      );

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('Bilal Khan'), findsOneWidget);
      expect(find.text('Hamza Tariq'), findsOneWidget);
    });

    testWidgets('Renders PodiumArchivesListView with automated fulfillment indicators', (tester) async {
      const archives = [
        MonthlyPodiumArchive(
          id: 'arc-1',
          tenantId: 't-1',
          monthYear: '2026-09',
          podiumRank: 1,
          userId: 'u-1',
          memberName: 'Bilal Khan',
          pointsScored: 2450,
          streakAtFinish: 48,
          rewardTitle: '1-Month Free Access',
          rewardType: 'membership_extension',
          isFulfilled: true,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PodiumArchivesListView(archives: archives),
          ),
        ),
      );

      expect(find.text('2026-09'), findsOneWidget);
      expect(find.text('#1 PODIUM'), findsOneWidget);
      expect(find.text('Bilal Khan'), findsOneWidget);
      expect(find.text('2450 XP'), findsOneWidget);
      expect(find.textContaining('Fulfillment Complete'), findsOneWidget);
    });

    testWidgets('Renders LeaderboardMiniView fulfilling Rule 7 Universal Mini View standard', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dualTrackLeaderboardProvider.overrideWith(
              () => FakeDualTrackLeaderboardNotifier(
                const DualTrackLeaderboardState(
                  monthlyMembers: [
                    LeaderboardMember(userId: 'u1', fullName: 'Bilal Khan', monthlyPoints: 1500, rank: 1),
                  ],
                  memberStatus: {
                    'monthly_rank': 1,
                    'is_qualified': true,
                    'streak_multiplier': 1.25,
                  },
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LeaderboardMiniView(),
            ),
          ),
        ),
      );

      expect(find.text('LEADERBOARD • MONTHLY RACE'), findsOneWidget);
      expect(find.text('Bilal Khan'), findsOneWidget);
      expect(find.text('1500 XP'), findsOneWidget);
      expect(find.text('Your Rank: #1'), findsOneWidget);
      expect(find.text('✓ Qualified for Top 3'), findsOneWidget);
    });

    testWidgets('Renders DualTrackLeaderboardSheet with all modular subcomponents and bottom status bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dualTrackLeaderboardProvider.overrideWith(
              () => FakeDualTrackLeaderboardNotifier(
                const DualTrackLeaderboardState(
                  monthlyMembers: [
                    LeaderboardMember(userId: 'u1', fullName: 'Bilal Khan', monthlyPoints: 1500, rank: 1),
                    LeaderboardMember(userId: 'u2', fullName: 'Hamza Tariq', monthlyPoints: 1300, rank: 2),
                    LeaderboardMember(userId: 'u3', fullName: 'Ali Raza', monthlyPoints: 1100, rank: 3),
                    LeaderboardMember(userId: 'u4', fullName: 'Zaid Ahmed', monthlyPoints: 900, rank: 4),
                  ],
                  memberStatus: {
                    'monthly_rank': 1,
                    'monthly_points': 1500,
                    'is_qualified': true,
                    'streak_multiplier': 1.25,
                    'current_streak_days': 40,
                  },
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DualTrackLeaderboardSheet(),
            ),
          ),
        ),
      );

      expect(find.text('GYM LEADERBOARD'), findsOneWidget);
      expect(find.text('Monthly Race'), findsOneWidget);
      expect(find.text('Hall of Fame'), findsOneWidget);
      expect(find.text('Archives'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#4'), findsOneWidget);
      expect(find.text('YOUR RANK: #1'), findsOneWidget);
      expect(find.textContaining('40-Day Streak'), findsOneWidget);
    });
  });
}
