import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/workout/presentation/providers/gamification_provider.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/ai_nutrition_fuel_card.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/calorie_calculator_sheet.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/confetti_celebration_dialog.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/goal_onboarding_dialog.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/gym_leaderboard_sheet.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/weight_stepper_widget.dart';

void main() {
  group('Gamification & Streak Tests', () {
    test('GamificationNotifier awards points and increments streak', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(gamificationProvider);
      expect(initial.currentStreakDays, 5);

      await container.read(gamificationProvider.notifier).awardWorkoutCompletionPoints(points: 100);

      final updated = container.read(gamificationProvider);
      expect(updated.currentStreakDays, 6);
      expect(updated.totalPoints, initial.totalPoints + 100);
    });

    test('LeaderboardProvider fetches ranked entries', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final entries = await container.read(leaderboardProvider.future);
      expect(entries.isNotEmpty, isTrue);
      expect(entries.first.rank, 1);
      expect(entries.first.name, 'Zaid Khan');
    });
  });

  group('WeightStepperWidget Direct Typing & Stepper Tests', () {
    testWidgets('allows direct typing in addition to +/- stepper clicks', (tester) async {
      double current = 74.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => WeightStepperWidget(
                label: 'CURRENT',
                value: current,
                unit: 'KG',
                onChanged: (v) => setState(() => current = v),
              ),
            ),
          ),
        ),
      );

      expect(find.text('CURRENT'), findsOneWidget);
      expect(find.text('KG'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '82');
      await tester.pump();
      expect(current, 82.0);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(current, 83.0);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(current, 82.0);
    });
  });

  group('Goal Onboarding & Nutrition Engine Tests', () {
    testWidgets('GoalOnboardingDialog renders body type choices and calorie calculator launcher', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoalOnboardingDialog(),
            ),
          ),
        ),
      );

      expect(find.text('GENETICS & TARGET PHYSIQUE'), findsOneWidget);
      expect(find.text('CALCULATE DAILY CALORIES & MACROS'), findsOneWidget);
      expect(find.text('ECTOMORPH'), findsOneWidget);
      expect(find.text('MESOMORPH'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pump();
      expect(find.text('ENDOMORPH'), findsOneWidget);
      expect(find.text('SAVE & TUNE AI TRAINER'), findsOneWidget);
    });

    testWidgets('AiNutritionFuelCard renders metrics and handles tap', (tester) async {
      bool recalibrated = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiNutritionFuelCard(
              targetCalories: 2750,
              proteinGrams: 165,
              waterLiters: 3.6,
              bmi: 24.5,
              onRecalibrate: () => recalibrated = true,
            ),
          ),
        ),
      );

      expect(find.text('AI NUTRITION & FUEL TARGET'), findsOneWidget);
      expect(find.text('2750 kcal'), findsOneWidget);
      expect(find.text('165g'), findsOneWidget);
      expect(find.text('3.6L'), findsOneWidget);

      await tester.tap(find.byType(AiNutritionFuelCard));
      expect(recalibrated, isTrue);
    });

    testWidgets('CalorieCalculatorSheet renders activity chips and applies target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalorieCalculatorSheet(
              initialWeight: 75,
              initialHeight: 180,
              initialAge: 25,
            ),
          ),
        ),
      );

      expect(find.text('CLINICAL CALORIE CALCULATOR'), findsOneWidget);
      expect(find.text('Maintain weight'), findsOneWidget);
      expect(find.text('Mild weight loss'), findsOneWidget);
      expect(find.textContaining('DAILY TARGET'), findsOneWidget);
    });
  });

  group('Leaderboard & Confetti Celebration Tests', () {
    testWidgets('GymLeaderboardSheet renders rankings and user stats', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GymLeaderboardSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('GYM LEADERBOARD'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('Zaid Khan'), findsOneWidget);
      expect(find.textContaining('YOUR STREAK:'), findsOneWidget);
    });

    testWidgets('ConfettiCelebrationDialog renders metrics and handles return', (tester) async {
      bool closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfettiCelebrationDialog(
              totalSets: 16,
              totalVolumeKg: 3450,
              durationMinutes: 48,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('WORKOUT CRUSHED!'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('3450 kg'), findsOneWidget);
      expect(find.text('48m'), findsOneWidget);
      expect(find.text('CLAIM & RETURN TO HUB'), findsOneWidget);

      await tester.tap(find.text('CLAIM & RETURN TO HUB'));
      await tester.pump();
      expect(closed, isTrue);
    });
  });
}
