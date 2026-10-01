import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/workout/domain/models/fitness_profile_model.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/ai_workout_metric_inputs.dart';

void main() {
  group('Phase 2 AI Workout Engine - Domain & Silent BMI Tests', () {
    test('Silent BMI Calculation and Track A vs Track B Routing Logic', () {
      // Test 1: Heavyweight / Overweight member (Daniyal, 95kg, 175cm)
      final profileTrackB = UserFitnessProfile(
        userId: 'user-daniyal',
        currentWeightKg: 95.0,
        heightCm: 175.0,
        age: 28,
        experienceLevel: 'beginner',
        assignedWorkoutTrack: 'track_b',
        medicalInjuries: const ['knee'],
      );

      expect(profileTrackB.bmi, isNotNull);
      expect(profileTrackB.bmi!, closeTo(31.02, 0.05));
      expect(profileTrackB.isTrackB, isTrue);
      expect(profileTrackB.trackDisplayName, contains('Track B'));

      // Test 2: Standard athletic member (Usman, 72kg, 178cm)
      final profileTrackA = UserFitnessProfile(
        userId: 'user-usman',
        currentWeightKg: 72.0,
        heightCm: 178.0,
        age: 25,
        experienceLevel: 'intermediate',
        assignedWorkoutTrack: 'track_a',
      );

      expect(profileTrackA.bmi, isNotNull);
      expect(profileTrackA.bmi!, closeTo(22.72, 0.05));
      expect(profileTrackA.isTrackB, isFalse);
      expect(profileTrackA.trackDisplayName, contains('Track A'));
    });

    test('UserFitnessProfile JSON serialization with Phase 1 & 2 columns', () {
      final json = {
        'user_id': 'test-uuid-1',
        'body_type': 'endomorph',
        'fitness_goal': 'fat_loss',
        'experience_level': 'beginner',
        'age': 32,
        'height_cm': 180.0,
        'current_weight_kg': 92.5,
        'assigned_workout_track': 'track_b',
        'current_step_target': 8000,
        'consecutive_target_misses': 1,
        'medical_injuries': ['lower_back', 'knee'],
        'current_workout_routine_id': 'routine-999',
        'profile_completed': true,
      };

      final profile = UserFitnessProfile.fromJson(json);
      expect(profile.userId, 'test-uuid-1');
      expect(profile.bodyType, 'endomorph');
      expect(profile.age, 32);
      expect(profile.assignedWorkoutTrack, 'track_b');
      expect(profile.currentStepTarget, 8000);
      expect(profile.consecutiveTargetMisses, 1);
      expect(profile.medicalInjuries, containsAll(['lower_back', 'knee']));
      expect(profile.currentWorkoutRoutineId, 'routine-999');
      expect(profile.profileCompleted, isTrue);
      expect(profile.isTrackB, isTrue);

      final serialized = profile.toJson();
      expect(serialized['assigned_workout_track'], 'track_b');
      expect(serialized['age'], 32);
      expect(serialized['medical_injuries'], containsAll(['lower_back', 'knee']));
      expect(serialized['current_workout_routine_id'], 'routine-999');
    });

    test('AiWorkoutGenerationResult JSON parsing and failure handling', () {
      final successJson = {
        'success': true,
        'bmi': 31.02,
        'assigned_track': 'track_b',
        'routing_reason': 'Silent BMI check indicates elevated joint stress.',
        'routine_id': 'routine-user-123',
        'master_template_id': 'template-master-b',
        'days_assigned': 7,
        'exercises_mapped': 18,
        'swapped_exercises_count': 2,
        'routine_title': 'Master 90-Day Low-Impact Foundation (Track B) (Personalized)',
      };

      final result = AiWorkoutGenerationResult.fromJson(successJson);
      expect(result.success, isTrue);
      expect(result.assignedTrack, 'track_b');
      expect(result.isTrackB, isTrue);
      expect(result.routineId, 'routine-user-123');
      expect(result.masterTemplateId, 'template-master-b');
      expect(result.daysGenerated, 7);
      expect(result.exercisesMapped, 18);
      expect(result.swappedExercisesCount, 2);
      expect(result.routineTitle, contains('Track B'));

      final failure = AiWorkoutGenerationResult.failure('No master template found');
      expect(failure.success, isFalse);
      expect(failure.error, 'No master template found');
    });

    test('Hierarchical flow: target_body_type + BMI calculates correct Track and dual-condition query', () {
      // Simulation of RPC logic for dual-condition query:
      // Strict Rule 9 & Liability Logic:
      // Users with age >= maxAllowedAiAge are completely blocked from automated AI routines (returns null)
      // Users with weight >= 90kg or BMI >= 28.0 are routed to Track B
      // Otherwise, routed to Track A
      String? resolveTrack({
        required double weightKg,
        required double heightCm,
        required int age,
        int maxAllowedAiAge = 55,
      }) {
        if (age >= maxAllowedAiAge) {
          return null; // Blocked for facility liability protection
        }
        final heightM = heightCm / 100.0;
        final bmi = weightKg / (heightM * heightM);
        if (weightKg >= 90.0 || bmi >= 28.0) {
          return 'track_b';
        }
        return 'track_a';
      }

      // Case 1: V-Shape target with normal BMI (75kg, 180cm, 24yo -> BMI 23.15)
      final vShapeTrack = resolveTrack(weightKg: 75.0, heightCm: 180.0, age: 24);
      expect(vShapeTrack, 'track_a');

      // Case 2: V-Shape target with high BMI / overweight (94kg, 175cm, 30yo -> BMI 30.7)
      final vShapeHeavyTrack = resolveTrack(weightKg: 94.0, heightCm: 175.0, age: 30);
      expect(vShapeHeavyTrack, 'track_b');

      // Case 3: Heavyweight target with normal/athletic BMI (82kg, 185cm, 26yo -> BMI 23.96)
      final hwTrackA = resolveTrack(weightKg: 82.0, heightCm: 185.0, age: 26);
      expect(hwTrackA, 'track_a');

      // Case 4: Heavyweight target with high bodyweight (105kg, 180cm, 35yo -> BMI 32.4)
      final hwTrackB = resolveTrack(weightKg: 105.0, heightCm: 180.0, age: 35);
      expect(hwTrackB, 'track_b');

      // Case 5: Facility Liability Protection: Senior age >= 55 is blocked from automated AI routines
      final seniorBlocked = resolveTrack(weightKg: 75.0, heightCm: 175.0, age: 60);
      expect(seniorBlocked, isNull);
    });
  });

  group('Phase 2 UI Widgets - AiWorkoutMetricInputs', () {
    testWidgets('AiWorkoutMetricInputs displays Liability Restriction badge when age >= maxAllowedAiAge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiWorkoutMetricInputs(
                currentWeight: 75.0,
                currentHeight: 175.0,
                age: 58,
                maxAllowedAiAge: 55,
                selectedInjuries: const [],
                onWeightChanged: (_) {},
                onHeightChanged: (_) {},
                onAgeChanged: (_) {},
                onToggleInjury: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify Liability Restriction badge appears and Track A/B is not routed
      expect(find.textContaining('LIABILITY RESTRICTION (AGE 55+)'), findsOneWidget);
      expect(find.textContaining('Automated AI workouts blocked for safety'), findsOneWidget);
      expect(find.textContaining('TRACK B ROUTING'), findsNothing);
      expect(find.textContaining('TRACK A ROUTING'), findsNothing);
    });

    testWidgets('AiWorkoutMetricInputs displays Track B warning when weight >= 90kg', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiWorkoutMetricInputs(
                currentWeight: 95.0,
                currentHeight: 175.0,
                age: 26,
                maxAllowedAiAge: 55,
                selectedInjuries: const ['knee'],
                onWeightChanged: (_) {},
                onHeightChanged: (_) {},
                onAgeChanged: (_) {},
                onToggleInjury: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify Track B Routing badge appears
      expect(find.textContaining('TRACK B ROUTING'), findsOneWidget);
      expect(find.textContaining('High-impact jumps & spinal loads purged'), findsOneWidget);
      expect(find.text('95 kg'), findsOneWidget);
      expect(find.text('175 cm'), findsOneWidget);
      expect(find.text('26 yrs'), findsOneWidget);
      expect(find.text('KNEE'), findsOneWidget);
    });

    testWidgets('AiWorkoutMetricInputs displays Track A badge when weight < 90kg and normal BMI', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiWorkoutMetricInputs(
                currentWeight: 72.0,
                currentHeight: 178.0,
                age: 24,
                maxAllowedAiAge: 55,
                selectedInjuries: const [],
                onWeightChanged: (_) {},
                onHeightChanged: (_) {},
                onAgeChanged: (_) {},
                onToggleInjury: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify Track A Routing badge appears
      expect(find.textContaining('TRACK A ROUTING'), findsOneWidget);
      expect(find.textContaining('Progressive compound overload enabled'), findsOneWidget);
      expect(find.text('72 kg'), findsOneWidget);
    });
  });
}
