import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/gamification/data/rep_counter_state_machine.dart';
import 'package:gym_connect_app/features/gamification/data/tts_voice_coach_service.dart';
import 'package:gym_connect_app/features/gamification/domain/models/vision_ai_config.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/vision_ai_config_provider.dart';
import 'package:gym_connect_app/features/super_admin/presentation/desktop/widgets/vision_ai_scope_selector.dart';
import 'package:gym_connect_app/features/super_admin/presentation/desktop/widgets/vision_ai_slider_group.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/ai_trainer_entry_button.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/workout_media_viewport.dart';

void main() {
  group('Vision AI Live Trainer: Strict Rule 9 Dynamic Config Tests', () {
    test('State machine uses dynamic squat_depth_angle instead of hardcoded 90.0', () {
      // Configure strict squat depth at 78.0 degrees
      const strictConfig = VisionAiConfig(squatDepthAngle: 78.0);
      final fsm = RepCounterStateMachine(
        movementType: ExerciseMovementType.squat,
        targetReps: 5,
        config: strictConfig,
      );

      fsm.processAngle(170.0);

      // 85 degrees (standard 90 deg would pass, but strict 78 deg must NOT pass)
      final res85 = fsm.processAngle(85.0);
      expect(res85.stage, isNot(RepStage.contracting));
      expect(fsm.repCount, 0);

      // Descend below strict 78.0 threshold to 75.0
      final res75 = fsm.processAngle(75.0);
      expect(res75.stage, RepStage.contracting);
      expect(res75.statusText, contains('Deep Squat'));

      // Ascend to standing (170 deg) -> Rep completes
      final resUp = fsm.processAngle(170.0);
      expect(resUp.isNewRep, isTrue);
      expect(fsm.repCount, 1);
    });

    test('State machine uses dynamic bad_posture_trigger_ms instead of hardcoded 1000ms', () async {
      String? voiceAlert;
      // Fast alert: 400ms delay
      const fastConfig = VisionAiConfig(badPostureTriggerMs: 400);
      final fsm = RepCounterStateMachine(
        movementType: ExerciseMovementType.squat,
        targetReps: 5,
        config: fastConfig,
        onVoiceFeedback: (prompt) => voiceAlert = prompt,
      );

      fsm.processAngle(170.0);
      fsm.processAngle(110.0);

      // Wait 450ms (well below default 1000ms, but exceeding 400ms threshold)
      await Future.delayed(const Duration(milliseconds: 450));
      final res = fsm.processAngle(110.0);

      expect(fsm.isBadPosture, isTrue);
      expect(res.isBadPosture, isTrue);
      expect(voiceAlert, 'Go lower');
    });

    test('State machine uses dynamic pushup_depth_angle instead of hardcoded 85.0', () {
      // Stricter pushup depth at 70.0 degrees
      const strictPushupConfig = VisionAiConfig(pushupDepthAngle: 70.0);
      final fsm = RepCounterStateMachine(
        movementType: ExerciseMovementType.pushup,
        targetReps: 10,
        config: strictPushupConfig,
      );

      fsm.processAngle(170.0);

      // 80 degrees (would pass standard 85.0, but fails strict 70.0)
      final res80 = fsm.processAngle(80.0);
      expect(res80.stage, isNot(RepStage.contracting));

      // 65 degrees (breaks strict threshold)
      final res65 = fsm.processAngle(65.0);
      expect(res65.stage, RepStage.contracting);
    });

    test('TTS Voice Coach honors dynamic cooldown setting', () async {
      final tts = TtsVoiceCoachService(ttsCooldownSeconds: 1.0);

      final first = await tts.speak('Go lower');
      expect(first, isTrue);

      // Immediate attempt blocked
      final blocked = await tts.speak('Push through');
      expect(blocked, isFalse);

      // Wait 1.1s (clearing dynamic 1.0s cooldown)
      await Future.delayed(const Duration(milliseconds: 1100));
      final allowed = await tts.speak('Push through');
      expect(allowed, isTrue);
    });
  });

  group('Vision AI Live Trainer: Feature Toggle UI Enforcement', () {
    const testExercise = Exercise(
      id: 'ex-bench',
      name: 'Flat Barbell Bench Press',
      targetMuscle: 'Chest',
      equipment: 'Barbell',
      videoUrl: 'https://example.com/demo.mp4',
    );

    testWidgets('Live AI Trainer button is completely HIDDEN when is_live_trainer_enabled is false', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Explicitly set feature flag to disabled
      container.read(visionAiConfigProvider.notifier).setConfig(
            const VisionAiConfig(isLiveTrainerEnabled: false),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const Scaffold(
              body: WorkoutMediaViewport(
                exercise: testExercise,
                targetReps: 10,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Button must NOT exist in the widget tree
      expect(find.byType(AiTrainerEntryButton), findsNothing);
      expect(find.text('Start Live AI Trainer'), findsNothing);
    });

    testWidgets('Live AI Trainer button is VISIBLE when is_live_trainer_enabled is true', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(visionAiConfigProvider.notifier).setConfig(
            const VisionAiConfig(isLiveTrainerEnabled: true),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
            ),
            home: const Scaffold(
              body: WorkoutMediaViewport(
                exercise: testExercise,
                targetReps: 10,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AiTrainerEntryButton), findsOneWidget);
      expect(find.text('Start Live AI Trainer'), findsOneWidget);
    });
  });

  group('Vision AI Live Trainer: Super Admin Workstation Config Widgets', () {
    testWidgets('VisionAiSliderGroup renders all 5 sliders with labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: VisionAiSliderGroup(
                config: const VisionAiConfig(),
                onSquatDepthChanged: (_) {},
                onPushupDepthChanged: (_) {},
                onBadPostureDelayChanged: (_) {},
                onTtsCooldownChanged: (_) {},
                onMicroClipDurationChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('SQUAT DEPTH STRICTNESS (PARALLEL ANGLE)'), findsOneWidget);
      expect(find.text('PUSHUP DEPTH THRESHOLD'), findsOneWidget);
      expect(find.text('BAD POSTURE ALERT DELAY'), findsOneWidget);
      expect(find.text('VOICE COACH AUDIO COOLDOWN'), findsOneWidget);
      expect(find.text('SET 1 MICRO-CLIP DURATION'), findsOneWidget);
      expect(find.text('90°'), findsOneWidget);
      expect(find.text('1000 ms'), findsOneWidget);
    });

    testWidgets('VisionAiScopeSelector renders switches and tenant dropdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: VisionAiScopeSelector(
              selectedTenantId: null,
              tenants: const [],
              config: const VisionAiConfig(isLiveTrainerEnabled: true, allowTenantOverride: true),
              onTenantSelected: (_) {},
              onToggleLiveTrainer: (_) {},
              onToggleAllowOverride: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('LIVE AI TRAINER MASTER ENGINE'), findsOneWidget);
      expect(find.text('ALLOW TENANT OVERRIDES (RULE 9)'), findsOneWidget);
      expect(find.text('🌐 GLOBAL SYSTEM (ALL TENANTS)'), findsOneWidget);
    });
  });
}
