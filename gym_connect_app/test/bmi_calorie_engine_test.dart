import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/workout/domain/services/bmi_calorie_engine.dart';

void main() {
  group('BmiCalorieEngine Tests', () {
    test('calculateBmi calculates correct BMI and category', () {
      final bmi = BmiCalorieEngine.calculateBmi(74, 175);
      expect(bmi, 24.2);
      expect(BmiCalorieEngine.getBmiCategory(bmi), 'Normal / Lean Athletic');

      final obeseBmi = BmiCalorieEngine.calculateBmi(105, 175);
      expect(obeseBmi, 34.3);
      expect(BmiCalorieEngine.getBmiCategory(obeseBmi), 'Heavy Bulk / High Mass');
    });

    test('Mifflin-St Jeor BMR and TDEE calculations for male', () {
      final result = BmiCalorieEngine.calculate(
        weightKg: 74,
        heightCm: 175,
        ageYears: 24,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderate,
        goal: 'muscle_gain',
      );

      expect(result.bmi, 24.2);
      expect(result.maintenanceCalories, greaterThan(2400));
      expect(result.targetCalories, result.maintenanceCalories + 350);
      expect(result.proteinGrams, (74 * 2.0).round());
      expect(result.waterLiters, 3.3);
    });

    test('Mifflin-St Jeor BMR and TDEE calculations for female', () {
      final result = BmiCalorieEngine.calculate(
        weightKg: 60,
        heightCm: 165,
        ageYears: 25,
        gender: Gender.female,
        activityLevel: ActivityLevel.moderate,
        goal: 'fat_loss',
      );

      expect(result.bmi, 22.0);
      expect(result.targetCalories, result.maintenanceCalories - 450);
      expect(result.proteinGrams, (60 * 2.2).round());
    });

    test('CalorieTier calculations match clinical calorie calculator benchmarks', () {
      final result = BmiCalorieEngine.calculate(
        weightKg: 65,
        heightCm: 180,
        ageYears: 25,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderate,
      );

      expect(result.lossTiers.length, 4);
      expect(result.lossTiers[0].title, 'Maintain weight');
      expect(result.lossTiers[0].percentage, 100);
      expect(result.lossTiers[1].title, 'Mild weight loss');
      expect(result.lossTiers[1].pace, '0.25 kg/week');
      expect(result.lossTiers[1].calories, result.maintenanceCalories - 250);
      expect(result.lossTiers[2].title, 'Weight loss');
      expect(result.lossTiers[2].pace, '0.5 kg/week');
      expect(result.lossTiers[2].calories, result.maintenanceCalories - 500);
      expect(result.lossTiers[3].title, 'Extreme weight loss');
      expect(result.lossTiers[3].pace, '1 kg/week');
      expect(result.lossTiers[3].calories, result.maintenanceCalories - 1000);

      expect(result.gainTiers.length, 4);
      expect(result.gainTiers[1].title, 'Mild weight gain');
      expect(result.gainTiers[1].calories, result.maintenanceCalories + 250);
      expect(result.gainTiers[2].title, 'Weight gain / Hypertrophy');
      expect(result.gainTiers[2].calories, result.maintenanceCalories + 500);
      expect(result.gainTiers[3].title, 'Extreme muscle bulk');
      expect(result.gainTiers[3].calories, result.maintenanceCalories + 1000);
    });
  });
}
