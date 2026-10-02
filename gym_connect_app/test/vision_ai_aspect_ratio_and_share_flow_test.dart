import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/gamification/data/rep_counter_state_machine.dart';
import 'package:gym_connect_app/features/gamification/data/tts_voice_coach_service.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/vision_ai_hud_overlay.dart';
import 'package:gym_connect_app/features/workout/presentation/screens/workout_completion_share_screen.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/workout_share_action_bar.dart';

void main() {
  group('Vision AI Diagnostics & Audio TTS Fixes', () {
    test('RepCounterStateMachine detects half-rep and emits Missed Rep diagnostic', () {
      String? missedPrompt;
      final machine = RepCounterStateMachine(
        movementType: ExerciseMovementType.squat,
        onRepMissed: (reason) => missedPrompt = reason,
      );

      // User stands tall (170°)
      machine.processAngle(170.0);
      expect(machine.repCount, 0);

      // User initiates squat descent but only reaches 115° (doesn't hit 90° target)
      machine.processAngle(130.0);
      machine.processAngle(115.0);
      expect(machine.repCount, 0);

      // User stands back up to 168° without hitting depth
      final res = machine.processAngle(168.0);

      expect(missedPrompt, 'Missed: Did not go low enough!');
      expect(res.missedRepReason, 'Missed: Did not go low enough!');
      expect(machine.activeMissedRepReason, 'Missed: Did not go low enough!');
      expect(machine.repCount, 0);
    });

    test('TtsVoiceCoachService speaks immediately when force is true', () async {
      final spoken = <String>[];
      final tts = TtsVoiceCoachService(
        customSpeak: (phrase) async => spoken.add(phrase),
        ttsCooldownSeconds: 5.0,
      );

      // Initial speech
      await tts.speak('Go lower');
      expect(spoken, ['Go lower']);

      // Without force, immediate speech within 5s cooldown is blocked
      final blocked = await tts.speak('Go lower');
      expect(blocked, isFalse);
      expect(spoken.length, 1);

      // With force: true, immediate speech for missed rep bypasses cooldown
      final forced = await tts.speak('Did not go low enough', force: true);
      expect(forced, isTrue);
      expect(spoken, ['Go lower', 'Did not go low enough']);
    });

    testWidgets('VisionAiHudOverlay renders bold red missed rep diagnostic banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: const Scaffold(
            body: VisionAiHudOverlay(
              repCount: 3,
              targetReps: 10,
              currentAngle: 110.0,
              statusText: 'MISSED: DID NOT GO LOW ENOUGH!',
              isBadPosture: true,
              missedRepReason: 'Missed: Did not go low enough!',
              onStop: _noop,
              onToggleCamera: _noop,
            ),
          ),
        ),
      );

      expect(find.text('MISSED: DID NOT GO LOW ENOUGH!'), findsWidgets);
    });
  });

  group('Workout Completion Share Screen Flow', () {
    testWidgets('WorkoutCompletionShareScreen renders action buttons and stats', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorkoutCompletionShareScreen(
              routineTitle: 'Leg Day Annihilation',
              totalSets: 16,
              totalReps: 140,
              durationMinutes: 52,
            ),
          ),
        ),
      );

      expect(find.text('WORKOUT RECORDED! 🎥'), findsOneWidget);
      expect(find.text('SHARE TO COMMUNITY FEED'), findsOneWidget);
      expect(find.text('SAVE TO MY PROFILE'), findsOneWidget);
      expect(find.text('Skip & Return to Hub'), findsOneWidget);
      expect(find.byType(WorkoutShareActionBar), findsOneWidget);
    });
  });
}

void _noop() {}
