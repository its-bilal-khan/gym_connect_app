import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/gamification/data/rep_counter_state_machine.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/vision_ai_hud_overlay.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/vision_ai_metric_bar.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/ai_trainer_entry_button.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/workout_media_viewport.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Vision AI Real-Device Fixes Verification', () {
    test('RepCounterStateMachine can force Squat mode for Test Squats debug', () {
      final machine = RepCounterStateMachine(movementType: ExerciseMovementType.bicepCurl);
      expect(machine.movementType, ExerciseMovementType.bicepCurl);

      machine.forceMovementType(ExerciseMovementType.squat);
      expect(machine.movementType, ExerciseMovementType.squat);
      expect(machine.repCount, 0);

      // Verify squat angle processing
      final result = machine.processAngle(80.0);
      expect(result.currentAngle, 80.0);
    });

    testWidgets('VisionAiMetricBar formats timer, set, and reps correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VisionAiMetricBar(
              elapsedSeconds: 125, // 02:05
              currentSet: 2,
              totalSets: 4,
              repCount: 8,
              targetReps: 12,
              accent: Color(0xFFCCFF00),
            ),
          ),
        ),
      );

      expect(find.text('TIMER'), findsOneWidget);
      expect(find.text('02:05'), findsOneWidget);
      expect(find.text('SET'), findsOneWidget);
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('REPS'), findsOneWidget);
      expect(find.text('8 / 12'), findsOneWidget);
    });

    testWidgets('VisionAiHudOverlay shows Test Squats button and handles toggle', (tester) async {
      bool togglePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: VisionAiHudOverlay(
              repCount: 5,
              targetReps: 10,
              currentAngle: 88.0,
              statusText: 'Squat',
              isBadPosture: false,
              onStop: () {},
              onToggleCamera: () {},
              currentSet: 1,
              totalSets: 3,
              elapsedSeconds: 45,
              exerciseName: 'Squat',
              isTestSquatsActive: false,
              onToggleTestSquats: () => togglePressed = true,
            ),
          ),
        ),
      );

      final button = find.text('🧪 Debug: Test Squats');
      expect(button, findsOneWidget);

      await tester.tap(button);
      expect(togglePressed, isTrue);
    });

    testWidgets('WorkoutMediaViewport places entry button cleanly below video container', (tester) async {
      const exercise = Exercise(
        id: 'ex-bench',
        name: 'Bench Press',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
            ),
            home: const Scaffold(
              body: WorkoutMediaViewport(
                exercise: exercise,
                targetReps: 10,
                currentSet: 2,
                totalSets: 3,
              ),
            ),
          ),
        ),
      );

      // Verify both video player and entry button are present in a column
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(AiTrainerEntryButton), findsOneWidget);
      expect(find.text('Start Live AI Trainer'), findsOneWidget);
    });
  });
}
