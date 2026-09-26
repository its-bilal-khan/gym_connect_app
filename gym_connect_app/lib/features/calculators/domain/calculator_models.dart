/// Activity multiplier labels and values for TDEE calculation.
enum ActivityLevel {
  sedentary('Sedentary', 'Little or no exercise', 1.2),
  lightlyActive('Lightly Active', 'Exercise 1-3 days/week', 1.375),
  moderatelyActive('Moderately Active', 'Exercise 3-5 days/week', 1.55),
  veryActive('Very Active', 'Hard exercise 6-7 days/week', 1.725),
  extremelyActive('Extremely Active', 'Hard daily exercise + physical job', 1.9);

  final String label;
  final String description;
  final double multiplier;
  const ActivityLevel(this.label, this.description, this.multiplier);
}

enum Gender { male, female }

enum UnitSystem { metric, imperial }

enum CalorieGoal {
  lose('Lose Weight', -500),
  maintain('Maintain Weight', 0),
  gain('Gain Weight', 500);

  final String label;
  final int offset;
  const CalorieGoal(this.label, this.offset);
}

class CalorieInput {
  final Gender gender;
  final UnitSystem unitSystem;
  final double weightKg;
  final double heightCm;
  final int age;
  final ActivityLevel activityLevel;
  final CalorieGoal goal;

  const CalorieInput({
    required this.gender,
    required this.unitSystem,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.activityLevel,
    this.goal = CalorieGoal.maintain,
  });
}

class CalorieResult {
  final int bmr;
  final int tdee;
  final int targetCalories;
  final int protein;
  final int carbs;
  final int fat;

  const CalorieResult({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class MacroResult {
  final int totalCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int proteinCalories;
  final int carbsCalories;
  final int fatCalories;
  final double proteinPct;
  final double carbsPct;
  final double fatPct;

  const MacroResult({
    required this.totalCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.proteinCalories,
    required this.carbsCalories,
    required this.fatCalories,
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
  });
}

/// Mifflin-St Jeor equation for BMR + TDEE calculation.
class CalorieCalculatorEngine {
  static CalorieResult calculate(CalorieInput input) {
    // Mifflin-St Jeor Equation
    double bmr;
    if (input.gender == Gender.male) {
      bmr = (10 * input.weightKg) +
          (6.25 * input.heightCm) -
          (5 * input.age) +
          5;
    } else {
      bmr = (10 * input.weightKg) +
          (6.25 * input.heightCm) -
          (5 * input.age) -
          161;
    }

    final tdee = bmr * input.activityLevel.multiplier;
    final targetCalories = tdee + input.goal.offset;

    // Macro split: 30% protein, 40% carbs, 30% fat
    final proteinCal = targetCalories * 0.30;
    final carbsCal = targetCalories * 0.40;
    final fatCal = targetCalories * 0.30;

    return CalorieResult(
      bmr: bmr.round(),
      tdee: tdee.round(),
      targetCalories: targetCalories.round(),
      protein: (proteinCal / 4).round(), // 4 cal per gram
      carbs: (carbsCal / 4).round(), // 4 cal per gram
      fat: (fatCal / 9).round(), // 9 cal per gram
    );
  }

  static MacroResult calculateMacros({
    required int totalCalories,
    required double proteinPct,
    required double carbsPct,
    required double fatPct,
  }) {
    final proteinCal = totalCalories * proteinPct / 100;
    final carbsCal = totalCalories * carbsPct / 100;
    final fatCal = totalCalories * fatPct / 100;

    return MacroResult(
      totalCalories: totalCalories,
      proteinGrams: (proteinCal / 4).round(),
      carbsGrams: (carbsCal / 4).round(),
      fatGrams: (fatCal / 9).round(),
      proteinCalories: proteinCal.round(),
      carbsCalories: carbsCal.round(),
      fatCalories: fatCal.round(),
      proteinPct: proteinPct,
      carbsPct: carbsPct,
      fatPct: fatPct,
    );
  }

  /// Convert imperial to metric helpers
  static double lbsToKg(double lbs) => lbs * 0.453592;
  static double kgToLbs(double kg) => kg / 0.453592;
  static double feetInchesToCm(int feet, int inches) =>
      (feet * 30.48) + (inches * 2.54);
  static (int, int) cmToFeetInches(double cm) {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return (feet, inches);
  }
}
