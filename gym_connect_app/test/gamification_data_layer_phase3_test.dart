import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/gamification/domain/models/models.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/providers.dart';

void main() {
  group('Phase 3 Domain Models - JSON & Logic Tests', () {
    test('DailyGamificationLog parses correctly and computes 80% threshold', () {
      final json = {
        'id': 'log-123',
        'tenant_id': 'tenant-456',
        'user_id': 'user-789',
        'log_date': '2026-10-01',
        'workout_assigned_sets': 16,
        'workout_completed_sets': 16,
        'workout_completion_pct': 100.0,
        'step_target': 10000,
        'step_actual': 8500,
        'step_completion_pct': 85.0,
        'step_source': 'live_pedometer',
        'diet_logged_type': 'photo_proof',
        'diet_proof_url': 'https://gym.co/meal.jpg',
        'sleep_logged_hours': 7.5,
        'sleep_source': 'healthkit',
        'sleep_asleep_minutes': 450,
        'gate_checkin_verified': true,
        'composite_completion_pct': 92.5,
        'points_awarded': 95,
        'penalty_deducted': 0,
        'is_unexcused_absence': false,
        'streak_saved': true,
        'created_at': '2026-10-01T10:00:00Z',
      };

      final model = DailyGamificationLog.fromJson(json);

      expect(model.id, 'log-123');
      expect(model.tenantId, 'tenant-456');
      expect(model.userId, 'user-789');
      expect(model.isCompositeGoalMet, isTrue);
      expect(model.hasActivePenalty, isFalse);
      expect(model.gateCheckinVerified, isTrue);
      expect(model.streakSaved, isTrue);

      final exported = model.toJson();
      expect(exported['composite_completion_pct'], 92.5);
      expect(exported['points_awarded'], 95);
    });

    test('DailyGamificationLog flags penalty and sub-80% failure', () {
      final json = {
        'tenant_id': 'tenant-456',
        'user_id': 'user-789',
        'log_date': '2026-10-01',
        'composite_completion_pct': 45.0,
        'penalty_deducted': 10,
        'is_unexcused_absence': true,
        'streak_saved': false,
      };

      final model = DailyGamificationLog.fromJson(json);

      expect(model.isCompositeGoalMet, isFalse);
      expect(model.hasActivePenalty, isTrue);
      expect(model.streakSaved, isFalse);
    });

    test('LeaderboardMember parses profile join and computes titles and podium rank', () {
      final json = {
        'user_id': 'user-1',
        'monthly_points': 1450,
        'total_points': 5800,
        'current_streak_days': 45,
        'longest_streak_days': 75,
        'monthly_workouts_completed': 20,
        'streak_multiplier': 1.25,
        'is_elite_qualified': true,
        'profiles': {
          'id': 'user-1',
          'full_name': 'Ali Hassan',
          'avatar_url': 'https://gym.co/ali.png',
        },
      };

      final member = LeaderboardMember.fromJson(json, currentUserId: 'user-1', calculatedRank: 2);

      expect(member.userId, 'user-1');
      expect(member.fullName, 'Ali Hassan');
      expect(member.rank, 2);
      expect(member.isPodium, isTrue);
      expect(member.isCurrentUser, isTrue);
      expect(member.streakMultiplier, 1.25);
      expect(member.isEliteQualified, isTrue);
      expect(member.rankTitle, 'Beast Mode Elite ⚡');
    });

    test('LeaderboardMember ranks and rankTitle progression', () {
      const titan = LeaderboardMember(userId: '1', fullName: 'Titan', currentStreakDays: 65, rank: 1);
      const warrior = LeaderboardMember(userId: '2', fullName: 'Warrior', currentStreakDays: 15, rank: 4);
      const contender = LeaderboardMember(userId: '3', fullName: 'Contender', currentStreakDays: 5, rank: 8);

      expect(titan.rankTitle, 'Legendary Titan 🔥');
      expect(titan.isPodium, isTrue);
      expect(warrior.rankTitle, 'Iron Warrior 🛡️');
      expect(warrior.isPodium, isFalse);
      expect(contender.rankTitle, 'Rising Contender ⭐');
      expect(contender.isPodium, isFalse);
    });

    test('WorkoutMicroReel serializes and handles defaults', () {
      final json = {
        'id': 'reel-001',
        'tenant_id': 'tenant-1',
        'user_id': 'user-10',
        'video_url': 'https://gym.co/reels/vid.mp4',
        'duration_seconds': 75,
        'routine_title': 'Heavy Deadlift PR Set',
        'streak_days_at_record': 28,
        'is_public_explore': true,
        'is_flagged': false,
        'likes_count': 14,
      };

      final reel = WorkoutMicroReel.fromJson(json);

      expect(reel.id, 'reel-001');
      expect(reel.durationSeconds, 75);
      expect(reel.routineTitle, 'Heavy Deadlift PR Set');
      expect(reel.isPublicExplore, isTrue);
      expect(reel.isFlagged, isFalse);

      final exported = reel.toJson();
      expect(exported['id'], 'reel-001');
      expect(exported['likes_count'], 14);
    });

    test('FlaggedQueueItem correctly flags review states', () {
      final json = {
        'id': 'queue-99',
        'tenant_id': 'tenant-1',
        'user_id': 'user-10',
        'proof_type': 'diet_photo',
        'proof_url': 'https://gym.co/fraud/photo.jpg',
        'points_awarded': 15,
        'status': 'pending_review',
        'flagged_reason': 'Suspicious blank photo',
      };

      final item = FlaggedQueueItem.fromJson(json);

      expect(item.id, 'queue-99');
      expect(item.pointsAwarded, 15);
      expect(item.isPending, isTrue);
      expect(item.isDeducted, isFalse);
      expect(item.isApproved, isFalse);
    });

    test('TenantRewardConfig parses default fallback and custom tiers', () {
      final emptyConfig = TenantRewardConfig.fromJson({});

      expect(emptyConfig.rank1Title, '1-Month Free Access');
      expect(emptyConfig.rank1Type, 'membership_extension');
      expect(emptyConfig.rank1Value, 30);
      expect(emptyConfig.minMonthlyWorkoutsQualification, 18);
      expect(emptyConfig.tier1Multiplier, 1.10);
      expect(emptyConfig.tier3Multiplier, 1.50);

      final customJson = {
        'leaderboard_rewards': {
          'rank_1': {'title': 'VIP Gold Pass (2 Months)', 'type': 'membership_extension', 'value': 60},
          'rank_2': {'title': 'IsoWhey 5lb Tub', 'type': 'custom_reward', 'value': 'tub'},
          'rank_3': {'title': '25% Renewal Voucher', 'type': 'discount_voucher', 'value': 25},
        },
        'min_monthly_workouts_qualification': 22,
        'veteran_multiplier_config': {
          'tier_1_days': 10,
          'tier_1_multiplier': 1.15,
          'tier_2_days': 25,
          'tier_2_multiplier': 1.30,
          'tier_3_days': 50,
          'tier_3_multiplier': 1.60,
        },
      };

      final customConfig = TenantRewardConfig.fromJson(customJson);
      expect(customConfig.rank1Title, 'VIP Gold Pass (2 Months)');
      expect(customConfig.rank1Value, 60);
      expect(customConfig.minMonthlyWorkoutsQualification, 22);
      expect(customConfig.tier3Multiplier, 1.60);
    });

    test('MonthlyPodiumArchive parses historical fulfillment records', () {
      final json = {
        'id': 'archive-001',
        'tenant_id': 'tenant-1',
        'month_year': '2026-09',
        'podium_rank': 1,
        'user_id': 'user-winner',
        'points_scored': 2400,
        'streak_at_finish': 30,
        'reward_title': '1-Month Free Access',
        'reward_type': 'membership_extension',
        'reward_value': 30,
        'is_fulfilled': true,
        'subscription_id_extended': 'sub-uuid-123',
        'invoice_id_generated': 'inv-uuid-456',
        'fulfilled_at': '2026-10-01T00:00:00Z',
      };

      final archive = MonthlyPodiumArchive.fromJson(json);

      expect(archive.id, 'archive-001');
      expect(archive.monthYear, '2026-09');
      expect(archive.podiumRank, 1);
      expect(archive.isFulfilled, isTrue);
      expect(archive.invoiceIdGenerated, 'inv-uuid-456');
    });
  });

  group('Phase 3 Riverpod State & Notifier Tests', () {
    test('DailyGamificationState copyWith maintains state immutability', () {
      const state = DailyGamificationState(
        currentStreak: 7,
        monthlyPoints: 350,
        streakMultiplier: 1.10,
        isEliteQualified: true,
      );

      final updated = state.copyWith(
        currentStreak: 8,
        monthlyPoints: 450,
      );

      expect(updated.currentStreak, 8);
      expect(updated.monthlyPoints, 450);
      expect(updated.streakMultiplier, 1.10);
      expect(updated.isEliteQualified, isTrue);
    });

    test('AdaptiveCalibrationState detects 3 consecutive misses and suggests calibration', () {
      const normalState = AdaptiveCalibrationState(
        currentStepTarget: 10000,
        consecutiveMisses: 2,
        isCalibrationRecommended: false,
      );
      expect(normalState.isCalibrationRecommended, isFalse);

      final recommendedState = normalState.copyWith(
        consecutiveMisses: 3,
        isCalibrationRecommended: true,
        recommendedStepTarget: 6000,
      );
      expect(recommendedState.isCalibrationRecommended, isTrue);
      expect(recommendedState.recommendedStepTarget, 6000);
    });
  });
}
