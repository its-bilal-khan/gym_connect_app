import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:gym_connect_app/features/gamification/data/rep_counter_state_machine.dart';
import 'package:gym_connect_app/features/gamification/data/tts_voice_coach_service.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/pose_painter.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/vision_ai_hud_overlay.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/ai_trainer_entry_button.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/workout_media_viewport.dart';

void main() {
  group('Vision AI Live Trainer: TTS Voice Coach Debounce Tests', () {
    test('Debouncing prevents rapid audio spam within cooldown period', () async {
      final tts = TtsVoiceCoachService();

      // First utterance succeeds
      final first = await tts.speak('Go lower');
      expect(first, isTrue);

      // Immediate second utterance fails due to debounce
      final immediateSecond = await tts.speak('Go lower');
      expect(immediateSecond, isFalse);
    });

    test('Reset debounce allows immediate speech', () async {
      final tts = TtsVoiceCoachService();
      await tts.speak('Keep your back straight');
      tts.resetDebounce();

      final second = await tts.speak('Full extension');
      expect(second, isTrue);
    });
  });

  group('Vision AI Live Trainer: Biomechanics Posture & Voice Feedback Tests', () {
    test('Half-repping squat for > 1 second triggers bad posture and voice prompt', () async {
      String? voiceAlert;
      final fsm = RepCounterStateMachine(
        movementType: ExerciseMovementType.squat,
        targetReps: 10,
        onVoiceFeedback: (prompt) => voiceAlert = prompt,
      );

      // User starts at 170 deg (standing)
      fsm.processAngle(170.0);
      expect(fsm.isBadPosture, isFalse);

      // User descends to 110 deg (half-rep, above 90 deg)
      fsm.processAngle(110.0);
      // Wait over 1 second in bad posture range
      await Future.delayed(const Duration(milliseconds: 1050));
      final result = fsm.processAngle(110.0);

      expect(fsm.isBadPosture, isTrue);
      expect(result.isBadPosture, isTrue);
      expect(voiceAlert, 'Go lower');

      // User now breaks parallel (< 90 deg)
      final deepResult = fsm.processAngle(80.0);
      expect(fsm.isBadPosture, isFalse);
      expect(deepResult.isBadPosture, isFalse);
    });

    test('Pushup half-rep triggers chest to floor coaching', () async {
      String? voiceAlert;
      final fsm = RepCounterStateMachine(
        movementType: ExerciseMovementType.pushup,
        targetReps: 15,
        onVoiceFeedback: (prompt) => voiceAlert = prompt,
      );

      fsm.processAngle(170.0);
      fsm.processAngle(115.0);
      await Future.delayed(const Duration(milliseconds: 1050));
      fsm.processAngle(115.0);

      expect(fsm.isBadPosture, isTrue);
      expect(voiceAlert, 'Chest to floor');
    });
  });

  group('Vision AI Live Trainer: PosePainter Visual Feedback Tests', () {
    test('PosePainter uses correctColor when posture is good', () {
      final pose = Pose(landmarks: {
        PoseLandmarkType.leftHip: PoseLandmark(type: PoseLandmarkType.leftHip, x: 100, y: 100, z: 0, likelihood: 0.9),
        PoseLandmarkType.leftKnee: PoseLandmark(type: PoseLandmarkType.leftKnee, x: 100, y: 200, z: 0, likelihood: 0.9),
      });

      final painter = PosePainter(
        pose: pose,
        isBadPosture: false,
        correctColor: const Color(0xFFCCFF00),
        wrongColor: Colors.redAccent,
      );

      expect(painter.correctColor, const Color(0xFFCCFF00));
      expect(painter.isBadPosture, isFalse);
    });

    test('PosePainter triggers red lines when isBadPosture is true', () {
      final pose = Pose(landmarks: {
        PoseLandmarkType.leftHip: PoseLandmark(type: PoseLandmarkType.leftHip, x: 100, y: 100, z: 0, likelihood: 0.9),
        PoseLandmarkType.leftKnee: PoseLandmark(type: PoseLandmarkType.leftKnee, x: 100, y: 200, z: 0, likelihood: 0.9),
      });

      final painter = PosePainter(
        pose: pose,
        isBadPosture: true,
        correctColor: const Color(0xFFCCFF00),
        wrongColor: Colors.redAccent,
      );

      expect(painter.wrongColor, Colors.redAccent);
      expect(painter.isBadPosture, isTrue);
    });
  });

  group('Vision AI Live Trainer: UX Flow & Viewport Tests', () {
    testWidgets('AiTrainerEntryButton renders with Start Live AI Trainer text', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: AiTrainerEntryButton(onPressed: () => tapped = true),
          ),
        ),
      );

      expect(find.text('Start Live AI Trainer'), findsOneWidget);
      await tester.tap(find.text('Start Live AI Trainer'));
      expect(tapped, isTrue);
    });

    testWidgets('VisionAiHudOverlay renders reps and status indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: VisionAiHudOverlay(
              repCount: 7,
              targetReps: 12,
              currentAngle: 85.0,
              statusText: 'Deep Squat',
              isBadPosture: false,
              onStop: () {},
              onToggleCamera: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('LIVE AI'), findsOneWidget);
      expect(find.text('DEEP SQUAT'), findsOneWidget);
      expect(find.text('7 / 12'), findsOneWidget);
      expect(find.textContaining('85°'), findsOneWidget);
      expect(find.text('EXIT'), findsOneWidget);
    });

    testWidgets('WorkoutMediaViewport renders video with AI Trainer Entry Button below video', (tester) async {
      const exercise = Exercise(
        id: 'ex-01',
        name: 'Barbell Back Squat',
        targetMuscle: 'Quadriceps',
        equipment: 'Barbell',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
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
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AiTrainerEntryButton), findsOneWidget);
      expect(find.text('Start Live AI Trainer'), findsOneWidget);

      // Tap entry button -> pushes full-screen Live AI Trainer route
      await tester.tap(find.byType(AiTrainerEntryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('INITIALIZING AI VISION STREAM...'), findsOneWidget);
    });
  });
}
