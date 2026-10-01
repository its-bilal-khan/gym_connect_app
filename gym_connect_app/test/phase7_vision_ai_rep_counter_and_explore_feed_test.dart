import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/gamification/data/joint_angle_calculator.dart';
import 'package:gym_connect_app/features/gamification/data/rep_counter_state_machine.dart';
import 'package:gym_connect_app/features/gamification/domain/models/models.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/explore_reels_provider.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/explore_reels_state.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/ai_rep_counter_sheet.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/explore_reels_carousel_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/explore_reels_grid_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/explore_reels_mini_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/explore_reels_sheet.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/explore_reels_teaser_card.dart';

class FakeExploreReelsNotifier extends ExploreReelsNotifier {
  final ExploreReelsState initialState;
  FakeExploreReelsNotifier(this.initialState);

  @override
  ExploreReelsState build() => initialState;
}

void main() {
  group('Phase 7: Joint Angle Biomechanics Math Engine Tests', () {
    test('Calculates perpendicular 90.0 degree angle correctly', () {
      const a = PosePoint(x: 0, y: 1);
      const b = PosePoint(x: 0, y: 0); // vertex
      const c = PosePoint(x: 1, y: 0);

      final angle = JointAngleCalculator.calculateAngle(a, b, c);
      expect(angle, 90.0);
    });

    test('Calculates straight line 180.0 degree angle correctly', () {
      const a = PosePoint(x: -1, y: 0);
      const b = PosePoint(x: 0, y: 0); // vertex
      const c = PosePoint(x: 1, y: 0);

      final angle = JointAngleCalculator.calculateAngle(a, b, c);
      expect(angle, 180.0);
    });

    test('Computes smoothed moving average angle correctly', () {
      final angles = [85.0, 90.0, 95.0];
      final smoothed = JointAngleCalculator.smoothedAngle(angles);
      expect(smoothed, 90.0);
    });
  });

  group('Phase 7: Finite-State Machine Auto Rep Counter Tests', () {
    test('Squats state machine tracks Down -> Up transitions and increments reps', () {
      final fsm = RepCounterStateMachine(
        movementType: ExerciseMovementType.squat,
        targetReps: 10,
      );

      expect(fsm.repCount, 0);

      // Standing tall
      var res = fsm.processAngle(175.0);
      expect(res.stage, RepStage.ready);
      expect(res.repCount, 0);

      // Deep squat flexion (< 90 deg)
      res = fsm.processAngle(85.0);
      expect(res.stage, RepStage.contracting);
      expect(res.statusText, 'Deep Squat ⬇️');
      expect(res.repCount, 0);

      // Rising up (> 165 deg)
      res = fsm.processAngle(168.0);
      expect(res.stage, RepStage.ready);
      expect(res.repCount, 1);
      expect(res.isNewRep, isTrue);
      expect(res.statusText, 'Rep Complete! ⬆️');
    });

    test('Pushups state machine tracks Chest Down -> Extension transitions', () {
      final fsm = RepCounterStateMachine(
        movementType: ExerciseMovementType.pushup,
        targetReps: 15,
      );

      // Plank position
      fsm.processAngle(165.0);
      expect(fsm.repCount, 0);

      // Lowering chest (< 85 deg)
      var res = fsm.processAngle(80.0);
      expect(res.stage, RepStage.contracting);
      expect(res.statusText, 'Chest Down ⬇️');

      // Pushing up (> 160 deg)
      res = fsm.processAngle(162.0);
      expect(res.repCount, 1);
      expect(res.isNewRep, isTrue);
    });

    test('Bicep Curls state machine tracks Peak Squeeze -> Arm Extension', () {
      final fsm = RepCounterStateMachine(
        movementType: ExerciseMovementType.bicepCurl,
        targetReps: 12,
      );

      // Extended arms
      fsm.processAngle(160.0);
      expect(fsm.repCount, 0);

      // Peak squeeze (< 45 deg)
      var res = fsm.processAngle(40.0);
      expect(res.stage, RepStage.contracting);
      expect(res.statusText, 'Squeeze Peak ⬆️');

      // Lowering back (> 150 deg)
      res = fsm.processAngle(155.0);
      expect(res.repCount, 1);
      expect(res.isNewRep, isTrue);
    });

    test('Pull-ups state machine tracks Chin Over Bar -> Dead Hang', () {
      final fsm = RepCounterStateMachine(
        movementType: ExerciseMovementType.pullup,
        targetReps: 8,
      );

      // Dead hang
      fsm.processAngle(160.0);
      expect(fsm.repCount, 0);

      // Chin over bar (< 65 deg)
      var res = fsm.processAngle(60.0);
      expect(res.stage, RepStage.contracting);
      expect(res.statusText, 'Chin Over Bar ⬆️');

      // Lowering to dead hang (> 155 deg)
      res = fsm.processAngle(158.0);
      expect(res.repCount, 1);
      expect(res.isNewRep, isTrue);
    });

    test('Identifies target reps reached condition', () {
      final fsm = RepCounterStateMachine(
        movementType: ExerciseMovementType.squat,
        targetReps: 2,
      );

      fsm.processAngle(80.0);
      fsm.processAngle(170.0); // Rep 1
      expect(fsm.isTargetReached, isFalse);

      fsm.processAngle(80.0);
      fsm.processAngle(170.0); // Rep 2
      expect(fsm.isTargetReached, isTrue);
    });
  });

  group('Phase 7: Explore Reels UI Components & Dual-View Tests', () {
    testWidgets('Renders AiRepCounterSheet with rep targets and biomechanics status', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AiRepCounterSheet(
                targetReps: 12,
              ),
            ),
          ),
        ),
      );

      expect(find.text('VISION AI REP COUNTER'), findsOneWidget);
      expect(find.text('0 / 12'), findsOneWidget);
      expect(find.text('REPS COMPLETED'), findsOneWidget);
      expect(find.text('FINISH & SAVE SET'), findsOneWidget);
      expect(find.byIcon(Icons.accessibility_new_rounded), findsOneWidget);
    });

    testWidgets('Renders ExploreReelsCarouselView with member handle and like controls', (tester) async {
      const reels = [
        WorkoutMicroReel(
          id: 'reel-1',
          tenantId: 't-1',
          userId: 'u-1',
          memberName: 'Bilal Khan',
          videoUrl: 'https://example.com/video1.mp4',
          durationSeconds: 65,
          routineTitle: 'Leg Day — 140kg Squats PR',
          streakDaysAtRecord: 42,
          likesCount: 28,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exploreReelsProvider.overrideWith(
              () => FakeExploreReelsNotifier(
                const ExploreReelsState(reels: reels),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExploreReelsCarouselView(reels: reels),
            ),
          ),
        ),
      );

      expect(find.text('Bilal Khan'), findsOneWidget);
      expect(find.text('Leg Day — 140kg Squats PR'), findsOneWidget);
      expect(find.text('🔥 42d'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('Renders ExploreReelsGridView fulfilling Rule 5 Dual-View standard', (tester) async {
      const reels = [
        WorkoutMicroReel(
          id: 'reel-1',
          tenantId: 't-1',
          userId: 'u-1',
          memberName: 'Bilal Khan',
          videoUrl: 'https://example.com/video1.mp4',
          durationSeconds: 65,
          routineTitle: 'Leg Day Squats',
          streakDaysAtRecord: 42,
          likesCount: 28,
        ),
        WorkoutMicroReel(
          id: 'reel-2',
          tenantId: 't-1',
          userId: 'u-2',
          memberName: 'Hamza Tariq',
          videoUrl: 'https://example.com/video2.mp4',
          durationSeconds: 45,
          routineTitle: 'Chest Press',
          streakDaysAtRecord: 18,
          likesCount: 15,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exploreReelsProvider.overrideWith(
              () => FakeExploreReelsNotifier(
                const ExploreReelsState(reels: reels, viewMode: ExploreReelsViewMode.grid),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExploreReelsGridView(reels: reels),
            ),
          ),
        ),
      );

      expect(find.text('Bilal Khan'), findsOneWidget);
      expect(find.text('Hamza Tariq'), findsOneWidget);
      expect(find.text('65s'), findsOneWidget);
      expect(find.text('45s'), findsOneWidget);
    });

    testWidgets('Renders ExploreReelsMiniView fulfilling Rule 7 Universal Mini View standard', (tester) async {
      const reels = [
        WorkoutMicroReel(
          id: 'reel-1',
          tenantId: 't-1',
          userId: 'u-1',
          memberName: 'Bilal Khan',
          videoUrl: 'https://example.com/video1.mp4',
          durationSeconds: 65,
          routineTitle: 'Leg Day Squats',
          streakDaysAtRecord: 42,
          likesCount: 35,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exploreReelsProvider.overrideWith(
              () => FakeExploreReelsNotifier(
                const ExploreReelsState(reels: reels),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExploreReelsMiniView(),
            ),
          ),
        ),
      );

      expect(find.text('EXPLORE FEED LIVE'), findsOneWidget);
      expect(find.text('1 Reels'), findsOneWidget);
      expect(find.text('Bilal Khan'), findsOneWidget);
      expect(find.text('❤️ 35'), findsOneWidget);
    });

    testWidgets('Renders ExploreReelsSheet with Rule 5 Dual-View toggle buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExploreReelsSheet(),
            ),
          ),
        ),
      );

      expect(find.text('GYM EXPLORE FEED'), findsOneWidget);
      expect(find.byIcon(Icons.view_carousel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    });

    testWidgets('Renders ExploreReelsTeaserCard on Member Today tab', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: ExploreReelsTeaserCard(),
            ),
          ),
        ),
      );

      expect(find.text('GYM EXPLORE FEED & REELS'), findsOneWidget);
      expect(find.text('Watch member workout highlights & set PRs'), findsOneWidget);
      expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
    });
  });
}
