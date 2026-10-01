import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/ai_camera_placement_prompt.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/human_alignment_silhouette.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';

void main() {
  group('Vision AI: Optimal Camera Placement Model Tests', () {
    test('OptimalCameraPlacement parsing and instruction messages', () {
      expect(
        OptimalCameraPlacement.fromString('machine_holder'),
        OptimalCameraPlacement.machineHolder,
      );
      expect(
        OptimalCameraPlacement.fromString('floor_level'),
        OptimalCameraPlacement.floorLevel,
      );
      expect(
        OptimalCameraPlacement.fromString('free_standing'),
        OptimalCameraPlacement.freeStanding,
      );
      expect(
        OptimalCameraPlacement.fromString('unknown_val'),
        OptimalCameraPlacement.freeStanding,
      );

      expect(
        OptimalCameraPlacement.machineHolder.instructionMessage,
        '📱 Insert device into the Machine Holder for accurate AI tracking.',
      );
    });

    test('Exercise model serializes and deserializes optimal_camera_placement', () {
      const exercise = Exercise(
        id: 'ex-lat-pulldown',
        name: 'Lat Pulldown Machine',
        targetMuscle: 'Back',
        equipment: 'Cable Machine',
        optimalCameraPlacement: OptimalCameraPlacement.machineHolder,
      );

      final json = exercise.toJson();
      expect(json['optimal_camera_placement'], 'machine_holder');

      final reconstructed = Exercise.fromJson(json);
      expect(reconstructed.optimalCameraPlacement, OptimalCameraPlacement.machineHolder);
    });
  });

  group('Vision AI: Camera Placement Prompt & Silhouette Widget Tests', () {
    testWidgets('AiCameraPlacementPrompt renders prompt message and dismisses on tap', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: AiCameraPlacementPrompt(
              placement: OptimalCameraPlacement.machineHolder,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(
        find.text('📱 Insert device into the Machine Holder for accurate AI tracking.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, isTrue);
    });

    testWidgets('HumanAlignmentSilhouette renders dashed guide and alignment label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: const Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: HumanAlignmentSilhouette(),
            ),
          ),
        ),
      );

      expect(find.text('ALIGN BODY IN FRAME'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
