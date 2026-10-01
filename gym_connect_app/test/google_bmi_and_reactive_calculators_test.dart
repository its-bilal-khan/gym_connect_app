import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/calculators/domain/bmi_models.dart';
import 'package:gym_connect_app/features/calculators/domain/calculator_models.dart';

void main() {
  group('Google-Style BMI Calculator Engine Tests', () {
    test('Exact match for Google screenshot values (5\'6", 180 lb -> 29.0 Overweight)', () {
      final bmi = BmiCalculatorEngine.calculateImperial(
        weightLbs: 180,
        heightInches: 66, // 5'6"
      );
      expect(bmi, 29.0);

      final category = BmiCategory.fromBmi(bmi);
      expect(category, BmiCategory.overweight);
      expect(category.label, 'Overweight');
      expect(category.rangeLabel, '25–30');
    });

    test('Metric BMI calculation accuracy', () {
      // 70 kg, 1.75 m -> 70 / (1.75 * 1.75) = 22.86 -> 22.9
      final bmi = BmiCalculatorEngine.calculateMetric(
        weightKg: 70,
        heightCm: 175,
      );
      expect(bmi, 22.9);

      final category = BmiCategory.fromBmi(bmi);
      expect(category, BmiCategory.normal);
      expect(category.label, 'Normal');
      expect(category.rangeLabel, '18.5–25');
    });

    test('Clinical category boundary tests', () {
      // Underweight < 18.5
      expect(BmiCategory.fromBmi(17.8), BmiCategory.underweight);
      expect(BmiCategory.fromBmi(18.4), BmiCategory.underweight);

      // Normal 18.5 - 25.0
      expect(BmiCategory.fromBmi(18.5), BmiCategory.normal);
      expect(BmiCategory.fromBmi(24.9), BmiCategory.normal);

      // Overweight 25.0 - 30.0
      expect(BmiCategory.fromBmi(25.0), BmiCategory.overweight);
      expect(BmiCategory.fromBmi(29.9), BmiCategory.overweight);

      // Obese >= 30.0
      expect(BmiCategory.fromBmi(30.0), BmiCategory.obese);
      expect(BmiCategory.fromBmi(38.5), BmiCategory.obese);
    });

    test('Bidirectional Google unit conversions and string formatting', () {
      expect(BmiCalculatorEngine.formatFeetInches(66), "5'6\"");
      expect(BmiCalculatorEngine.formatFeetInches(72), "6'0\"");
      expect(BmiCalculatorEngine.formatFeetInches(69), "5'9\"");

      // 180 lbs -> ~82 kg
      final kg = BmiCalculatorEngine.lbsToKg(180);
      expect(kg, closeTo(81.6, 0.5));

      // 82 kg -> ~181 lbs
      final lbs = BmiCalculatorEngine.kgToLbs(kg);
      expect(lbs, closeTo(180, 1.0));

      // 66 inches -> ~168 cm
      final cm = BmiCalculatorEngine.inchesToCm(66);
      expect(cm, closeTo(167.6, 0.5));
    });
  });

  group('Reactive Calorie & Macro Calculator Engine Tests', () {
    test('CalorieCalculatorEngine accurately computes BMR, TDEE, and macros', () {
      const input = CalorieInput(
        gender: Gender.male,
        unitSystem: UnitSystem.metric,
        weightKg: 75,
        heightCm: 175,
        age: 25,
        activityLevel: ActivityLevel.moderatelyActive,
        goal: CalorieGoal.maintain,
      );

      final result = CalorieCalculatorEngine.calculate(input);
      // BMR: 10*75 + 6.25*175 - 5*25 + 5 = 750 + 1093.75 - 125 + 5 = 1723.75 -> 1724
      expect(result.bmr, 1724);
      expect(result.tdee, (1723.75 * 1.55).round());
      expect(result.targetCalories, result.tdee);
      expect(result.protein, (result.targetCalories * 0.30 / 4).round());
      expect(result.carbs, (result.targetCalories * 0.40 / 4).round());
      expect(result.fat, (result.targetCalories * 0.30 / 9).round());
    });

    test('MacroCalculatorEngine calculates custom and preset ratios reactively', () {
      final result = CalorieCalculatorEngine.calculateMacros(
        totalCalories: 2000,
        proteinPct: 40,
        carbsPct: 40,
        fatPct: 20,
      );

      expect(result.totalCalories, 2000);
      expect(result.proteinGrams, (800 / 4).round()); // 200g
      expect(result.carbsGrams, (800 / 4).round()); // 200g
      expect(result.fatGrams, (400 / 9).round()); // 44g
    });
  });
}
