import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/profile_quest_card.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/diet_meal_swap_sheet.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/injury_checkbox_matrix.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/medical_injury_filter_dialog.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/rapid_goal_selector.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/rapid_onboarding_sheet.dart';

void main() {
  group('Phase 4: Rapid 3-Question Onboarding Sheet Tests', () {
    testWidgets('RapidOnboardingSheet renders 3 questions and default Track A badge', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RapidOnboardingSheet(),
            ),
          ),
        ),
      );

      expect(find.text('RAPID 30-SECOND SETUP'), findsOneWidget);
      expect(find.text('CURRENT WEIGHT'), findsOneWidget);
      expect(find.text('TARGET PHYSIQUE GOAL'), findsOneWidget);
      expect(find.text('YOUR AGE'), findsOneWidget);
      expect(find.textContaining('ROUTING: TRACK A'), findsOneWidget);
      expect(find.text('1-TAP LAUNCH PROTOCOL'), findsOneWidget);
    });

    testWidgets('RapidOnboardingSheet switches to Track B when weight >= 90kg', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RapidOnboardingSheet(),
            ),
          ),
        ),
      );

      // Default weight is 75 kg. Increment 15 times to reach 90 kg
      final addIcon = find.byIcon(Icons.add_circle_outline_rounded).first;
      for (int i = 0; i < 15; i++) {
        await tester.tap(addIcon);
        await tester.pump();
      }

      expect(find.text('90.0 KG'), findsOneWidget);
      expect(find.textContaining('ROUTING: TRACK B'), findsOneWidget);
    });

    testWidgets('RapidOnboardingSheet blocks AI workouts and displays trainer consultation prompt for age >= maxAllowedAiAge', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RapidOnboardingSheet(),
            ),
          ),
        ),
      );

      // Default age is 25. Increment 30 times to reach 55
      final addAgeIcon = find.byIcon(Icons.add_circle_outline_rounded).last;
      for (int i = 0; i < 30; i++) {
        await tester.tap(addAgeIcon);
        await tester.pump();
      }

      // Verify Safety Notice badge appears and button changes to CONSULT PHYSICAL TRAINER
      expect(find.textContaining('SAFETY NOTICE: In-person certified trainer evaluation required for age 55+'), findsOneWidget);
      expect(find.text('CONSULT PHYSICAL TRAINER'), findsOneWidget);
      expect(find.byIcon(Icons.health_and_safety_rounded), findsWidgets);

      // Tap CONSULT PHYSICAL TRAINER and verify safety dialog opens
      await tester.tap(find.text('CONSULT PHYSICAL TRAINER'));
      await tester.pumpAndSettle();

      expect(find.text('IN-PERSON TRAINER EVALUATION REQUIRED'), findsOneWidget);
      expect(find.textContaining('Facility Liability & Cardiovascular Safety Protection'), findsOneWidget);
      expect(find.text('I UNDERSTAND & WILL CONSULT TRAINER'), findsOneWidget);
    });

    testWidgets('RapidGoalSelector handles goal selection', (tester) async {
      String selected = 'v_shape';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => RapidGoalSelector(
                selectedGoal: selected,
                onSelect: (g) => setState(() => selected = g),
                accent: Colors.greenAccent,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Lean & Shred'), findsOneWidget);
      expect(find.text('Athletic V-Taper'), findsOneWidget);
      expect(find.text('Mass & Power'), findsOneWidget);

      await tester.tap(find.text('Lean & Shred'));
      await tester.pump();
      expect(selected, 'lean_slim');
    });
  });

  group('Phase 4: Medical Injury Screening & Quest Tests', () {
    testWidgets('MedicalInjuryFilterDialog renders height, injuries, and +50 XP badge', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MedicalInjuryFilterDialog(),
            ),
          ),
        ),
      );

      expect(find.text('+50 BONUS XP'), findsOneWidget);
      expect(find.text('HEALTH & INJURY SCREENING'), findsOneWidget);
      expect(find.text('YOUR HEIGHT'), findsOneWidget);
      expect(find.text('MEDICAL INJURIES (SELECT ALL THAT APPLY)'), findsOneWidget);
      expect(find.text('Lower Back Pain / Disc Strain'), findsOneWidget);
      expect(find.text('Knee Joint / Meniscus Tenderness'), findsOneWidget);
      expect(find.text('SAVE & CLAIM 50 BONUS PTS'), findsOneWidget);
    });

    testWidgets('InjuryCheckboxMatrix toggles injury states', (tester) async {
      final selected = <String>{};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => InjuryCheckboxMatrix(
                selectedInjuries: selected,
                onToggle: (key) => setState(() {
                  if (selected.contains(key)) {
                    selected.remove(key);
                  } else {
                    selected.add(key);
                  }
                }),
                accent: Colors.cyanAccent,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Shoulder Impingement / Rotator Cuff'), findsOneWidget);
      await tester.tap(find.text('Shoulder Impingement / Rotator Cuff'));
      await tester.pump();
      expect(selected.contains('shoulder_pain'), isTrue);
    });

    testWidgets('ProfileQuestCard renders quest invitation with bonus points badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileQuestCard(),
          ),
        ),
      );

      expect(find.text('+50 BONUS XP'), findsOneWidget);
      expect(find.text('PROFILE QUEST'), findsOneWidget);
      expect(find.textContaining('Screen injuries & dimensions'), findsOneWidget);
      expect(find.byIcon(Icons.stars_rounded), findsOneWidget);
    });
  });

  group('Phase 4: 1-Tap Diet Meal Swap Tests', () {
    testWidgets('DietMealSwapSheet renders alternatives and 0 PT PENALTY badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DietMealSwapSheet(
              originalItem: 'Rolled Oats (100g)',
              category: 'Clean Carbs',
            ),
          ),
        ),
      );

      expect(find.text('1-TAP DIET & MEAL SWAP'), findsOneWidget);
      expect(find.text('0 PT PENALTY'), findsOneWidget);
      expect(find.textContaining('Substitute "Rolled Oats (100g)"'), findsOneWidget);
      expect(find.text('Sweet Potato (250g)'), findsOneWidget);
      expect(find.text('Brown Basmati Rice (180g)'), findsOneWidget);
      expect(find.text('Quinoa Bowl (200g)'), findsOneWidget);
      expect(find.text('SWAP'), findsWidgets);
    });
  });
}
