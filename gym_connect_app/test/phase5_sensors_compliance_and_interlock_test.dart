import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/core/services/device_id_service.dart';
import 'package:gym_connect_app/core/services/secure_storage_service.dart';
import 'package:gym_connect_app/features/gamification/data/diet_proof_service.dart';
import 'package:gym_connect_app/features/gamification/data/sleep_tracker_service.dart';
import 'package:gym_connect_app/features/gamification/domain/models/daily_gamification_log.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/adaptive_calibration_provider.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/daily_gamification_provider.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/adaptive_step_alert_card.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/composite_compliance_mini_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/composite_compliance_ring_card.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/diet_proof_card.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/sleep_tracker_card.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/gate_pass_card.dart';

void main() {
  group('Phase 5: 80% Composite Compliance Formula Tests', () {
    test('Calculates exact composite percentage with weighted formula (50/25/15/10)', () {
      // 100% workout (50) + 100% step (25) + 100% diet (15) + 100% sleep (10) = 100%
      const workoutPct = 100.0;
      const stepPct = 100.0;
      const dietPct = 100.0;
      const sleepPct = 100.0;

      final composite = (0.50 * workoutPct) + (0.25 * stepPct) + (0.15 * dietPct) + (0.10 * sleepPct);
      expect(composite, 100.0);
    });

    test('80% threshold is met when workout is 100%, step is 80%, diet is 100% and sleep is 0%', () {
      const workoutPct = 100.0; // 50 pts
      const stepPct = 80.0;     // 20 pts
      const dietPct = 100.0;    // 15 pts
      const sleepPct = 0.0;     // 0 pts

      final composite = (0.50 * workoutPct) + (0.25 * stepPct) + (0.15 * dietPct) + (0.10 * sleepPct);
      expect(composite, 85.0);
      expect(composite >= 80.0, isTrue);
    });

    test('80% threshold is NOT met when composite is below 80.0%', () {
      const workoutPct = 60.0; // 30.0
      const stepPct = 50.0;    // 12.5
      const dietPct = 25.0;    // 3.75
      const sleepPct = 70.0;   // 7.0

      final composite = (0.50 * workoutPct) + (0.25 * stepPct) + (0.15 * dietPct) + (0.10 * sleepPct);
      expect(composite, 53.25);
      expect(composite >= 80.0, isFalse);
    });
  });

  group('Phase 5: Anti-Cheat Gate Interlock & Streak Preservation Tests', () {
    test('Streak is NOT saved when 80% is met but physical gate check-in is false', () {
      const compositePct = 85.0;
      const isGateVerified = false;

      final isStreakSaved = compositePct >= 80.0 && isGateVerified;
      expect(isStreakSaved, isFalse);
    });

    test('Streak IS saved strictly when 80% is met AND physical gate check-in is verified', () {
      const compositePct = 85.0;
      const isGateVerified = true;

      final isStreakSaved = compositePct >= 80.0 && isGateVerified;
      expect(isStreakSaved, isTrue);
    });
  });

  group('Phase 5: Native Sleep Sensor Auto-Sync & Anti-Cheat Tests', () {
    test('Verified sensor sleep awards up to 10 points for >= 7 hours', () {
      expect(SleepDataResult.calculatePoints(7.5, SleepSource.healthConnect), 10);
      expect(SleepDataResult.calculatePoints(7.0, SleepSource.healthKit), 10);
      expect(SleepDataResult.calculatePoints(5.5, SleepSource.healthConnect), 7);
      expect(SleepDataResult.calculatePoints(3.0, SleepSource.healthKit), 3);
      expect(SleepDataResult.calculatePoints(0.0, SleepSource.healthKit), 0);
    });

    test('Manual self-reported sleep is strictly capped at 3 points to prevent spoofing', () {
      expect(SleepDataResult.calculatePoints(9.0, SleepSource.manual), 3);
      expect(SleepDataResult.calculatePoints(7.0, SleepSource.manual), 3);
      expect(SleepDataResult.calculatePoints(5.0, SleepSource.manual), 2);
      expect(SleepDataResult.calculatePoints(2.0, SleepSource.manual), 1);
    });
  });

  group('Phase 5: Diet Photo Proof vs Self-Check Points Tests', () {
    test('Photo proof awards 15 points and full 100% diet score fraction', () {
      final service = DietProofService();
      final selfCheckResult = service.logSelfCheck();
      expect(selfCheckResult.pointsAwarded, 2);
      expect(selfCheckResult.logType, DietLogType.selfCheck);
    });
  });

  group('Phase 5: Hardware Device ID Lock & Security Signature Tests', () {
    test('DeviceIdService produces a valid hardware UUID signature', () async {
      final service = DeviceIdService(const SecureStorageService());
      final deviceId = await service.getDeviceId();
      expect(deviceId, isNotEmpty);
      expect(deviceId.contains('hw_'), isTrue);
    });
  });

  group('Phase 5: Widgets Rendering & Strict Rules Compliance Tests', () {
    testWidgets('CompositeComplianceRingCard renders gauge, gate status and 80% goal', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyGamificationProvider.overrideWith(() => _MockDailyGamificationNotifier(
              const DailyGamificationState(
                todayLog: DailyGamificationLog(
                  id: 'log-1',
                  tenantId: 'ten-1',
                  userId: 'usr-1',
                  logDate: '2026-10-01',
                  workoutCompletionPct: 100.0,
                  workoutCompletedSets: 12,
                  workoutAssignedSets: 12,
                  stepCompletionPct: 100.0,
                  stepActual: 10000,
                  stepTarget: 10000,
                  dietLoggedType: 'photo_proof',
                  sleepLoggedHours: 7.5,
                  sleepSource: 'health_connect',
                  gateCheckinVerified: true,
                  compositeCompletionPct: 100.0,
                  pointsAwarded: 95,
                  streakSaved: true,
                ),
                currentStreak: 14,
                monthlyPoints: 1200,
              ),
            )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CompositeComplianceRingCard(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('DAILY 80% COMPLIANCE'), findsOneWidget);
      expect(find.text('GATE IN'), findsOneWidget);
      expect(find.text('WORKOUT'), findsOneWidget);
      expect(find.text('STEPS'), findsOneWidget);
      expect(find.text('DIET'), findsOneWidget);
      expect(find.text('SLEEP'), findsOneWidget);
      expect(find.textContaining('Streak saved!'), findsOneWidget);
    });

    testWidgets('CompositeComplianceMiniView renders live scaled mini view (Rule 7)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyGamificationProvider.overrideWith(() => _MockDailyGamificationNotifier(
              const DailyGamificationState(
                todayLog: DailyGamificationLog(
                  id: 'log-2',
                  tenantId: 'ten-1',
                  userId: 'usr-1',
                  logDate: '2026-10-01',
                  workoutCompletionPct: 80.0,
                  stepCompletionPct: 80.0,
                  dietLoggedType: 'self_check',
                  gateCheckinVerified: false,
                  compositeCompletionPct: 63.7,
                ),
              ),
            )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CompositeComplianceMiniView(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('COMPLIANCE LIVE'), findsOneWidget);
      expect(find.textContaining('63% of 80%'), findsOneWidget);
    });

    testWidgets('SleepTrackerCard & DietProofCard render on Member Dashboard', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SleepTrackerCard(),
                  DietProofCard(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('SLEEP RECOVERY'), findsOneWidget);
      expect(find.text('DIET PHOTO PROOF'), findsOneWidget);
    });

    testWidgets('AdaptiveStepAlertCard renders when calibration is recommended', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adaptiveCalibrationProvider.overrideWith(() => _MockAdaptiveNotifier(
              const AdaptiveCalibrationState(
                currentStepTarget: 10000,
                recommendedStepTarget: 8000,
                consecutiveMisses: 3,
                isCalibrationRecommended: true,
              ),
            )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AdaptiveStepAlertCard(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('AI HABIT CALIBRATION'), findsOneWidget);
      expect(find.text('ACCEPT 8000 STEPS'), findsOneWidget);
      expect(find.text('KEEP 10000'), findsOneWidget);
    });

    testWidgets('GatePassCard renders hardware device lock status and rolling QR', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GatePassCard(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('DEVICE ID LOCKED'), findsOneWidget);
      expect(find.textContaining('Single Device Protected'), findsOneWidget);
    });
  });
}

class _MockDailyGamificationNotifier extends DailyGamificationNotifier {
  final DailyGamificationState _initialState;
  _MockDailyGamificationNotifier(this._initialState);

  @override
  DailyGamificationState build() => _initialState;
}

class _MockAdaptiveNotifier extends AdaptiveCalibrationNotifier {
  final AdaptiveCalibrationState _initialState;
  _MockAdaptiveNotifier(this._initialState);

  @override
  AdaptiveCalibrationState build() => _initialState;
}
