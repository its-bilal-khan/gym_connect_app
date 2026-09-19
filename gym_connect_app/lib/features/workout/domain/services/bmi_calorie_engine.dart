enum Gender { male, female }

enum ActivityLevel {
  sedentary(1.2, 'Sedentary (Little/no exercise)'),
  light(1.375, 'Light (Exercise 1-3 times/week)'),
  moderate(1.55, 'Moderate (Exercise 4-5 times/week)'),
  intense(1.725, 'Intense (Daily hard training)');

  final double multiplier;
  final String label;
  const ActivityLevel(this.multiplier, this.label);
}

class CalorieTier {
  final String title;
  final String pace;
  final int calories;
  final int percentage;
  final bool isDeficit;

  const CalorieTier({
    required this.title,
    required this.pace,
    required this.calories,
    required this.percentage,
    required this.isDeficit,
  });
}

class NutritionCalculationResult {
  final double bmi;
  final String bmiCategory;
  final int maintenanceCalories;
  final int targetCalories;
  final int proteinGrams;
  final double waterLiters;
  final List<CalorieTier> lossTiers;
  final List<CalorieTier> gainTiers;

  const NutritionCalculationResult({
    required this.bmi,
    required this.bmiCategory,
    required this.maintenanceCalories,
    required this.targetCalories,
    required this.proteinGrams,
    required this.waterLiters,
    this.lossTiers = const [],
    this.gainTiers = const [],
  });
}

class BmiCalorieEngine {
  static double calculateBmi(double weightKg, double heightCm) {
    if (heightCm <= 0 || weightKg <= 0) return 22.0;
    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);
    return double.parse(bmi.toStringAsFixed(1));
  }

  static String getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal / Lean Athletic';
    if (bmi < 30.0) return 'Muscular / Overweight';
    return 'Heavy Bulk / High Mass';
  }

  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required Gender gender,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears);
    return gender == Gender.male ? base + 5 : base - 161;
  }

  static NutritionCalculationResult calculate({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required Gender gender,
    ActivityLevel activityLevel = ActivityLevel.moderate,
    String goal = 'muscle_gain',
  }) {
    final bmi = calculateBmi(weightKg, heightCm);
    final bmiCategory = getBmiCategory(bmi);
    final bmr = calculateBmr(weightKg: weightKg, heightCm: heightCm, ageYears: ageYears, gender: gender);
    final maintenance = (bmr * activityLevel.multiplier).round();

    int targetCalories = maintenance;
    double proteinMultiplier = 1.8;

    if (goal == 'muscle_gain' || goal == 'hypertrophy') {
      targetCalories = maintenance + 350;
      proteinMultiplier = 2.0;
    } else if (goal == 'fat_loss' || goal == 'fat_shred') {
      targetCalories = maintenance - 450;
      proteinMultiplier = 2.2;
    } else if (goal == 'strength') {
      targetCalories = maintenance + 150;
      proteinMultiplier = 1.8;
    }

    final m = maintenance;
    int pct(int cal) => m > 0 ? ((cal / m) * 100).round() : 100;

    final lossTiers = [
      CalorieTier(title: 'Maintain weight', pace: 'Current weight', calories: m, percentage: 100, isDeficit: false),
      CalorieTier(title: 'Mild weight loss', pace: '0.25 kg/week', calories: m - 250, percentage: pct(m - 250), isDeficit: true),
      CalorieTier(title: 'Weight loss', pace: '0.5 kg/week', calories: m - 500, percentage: pct(m - 500), isDeficit: true),
      CalorieTier(title: 'Extreme weight loss', pace: '1 kg/week', calories: m - 1000, percentage: pct(m - 1000), isDeficit: true),
    ];

    final gainTiers = [
      CalorieTier(title: 'Maintain weight', pace: 'Current weight', calories: m, percentage: 100, isDeficit: false),
      CalorieTier(title: 'Mild weight gain', pace: '0.25 kg/week', calories: m + 250, percentage: pct(m + 250), isDeficit: false),
      CalorieTier(title: 'Weight gain / Hypertrophy', pace: '0.5 kg/week', calories: m + 500, percentage: pct(m + 500), isDeficit: false),
      CalorieTier(title: 'Extreme muscle bulk', pace: '1 kg/week', calories: m + 1000, percentage: pct(m + 1000), isDeficit: false),
    ];

    final proteinGrams = (weightKg * proteinMultiplier).round();
    final waterLiters = double.parse((weightKg * 0.045).toStringAsFixed(1));

    return NutritionCalculationResult(
      bmi: bmi,
      bmiCategory: bmiCategory,
      maintenanceCalories: maintenance,
      targetCalories: targetCalories,
      proteinGrams: proteinGrams,
      waterLiters: waterLiters,
      lossTiers: lossTiers,
      gainTiers: gainTiers,
    );
  }
}
