import 'package:flutter/material.dart';

/// BMI classification categories matching Google Search BMI health metrics.
enum BmiCategory {
  underweight(
    label: 'Underweight',
    rangeLabel: '<18.5',
    color: Color(0xFF38BDF8), // Google Sky Blue
    minBmi: 0.0,
    maxBmi: 18.5,
  ),
  normal(
    label: 'Normal',
    rangeLabel: '18.5–25',
    color: Color(0xFF4ADE80), // Google Emerald Green
    minBmi: 18.5,
    maxBmi: 25.0,
  ),
  overweight(
    label: 'Overweight',
    rangeLabel: '25–30',
    color: Color(0xFFFACC15), // Google Warm Amber
    minBmi: 25.0,
    maxBmi: 30.0,
  ),
  obese(
    label: 'Obese',
    rangeLabel: '≥30',
    color: Color(0xFFF87171), // Google Coral Red
    minBmi: 30.0,
    maxBmi: 100.0,
  );

  final String label;
  final String rangeLabel;
  final Color color;
  final double minBmi;
  final double maxBmi;

  const BmiCategory({
    required this.label,
    required this.rangeLabel,
    required this.color,
    required this.minBmi,
    required this.maxBmi,
  });

  static BmiCategory fromBmi(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25.0) return BmiCategory.normal;
    if (bmi < 30.0) return BmiCategory.overweight;
    return BmiCategory.obese;
  }
}

/// Pure domain engine for BMI calculations and Google-style unit conversions.
abstract final class BmiCalculatorEngine {
  /// Calculate BMI using metric units (kg, cm).
  static double calculateMetric({
    required double weightKg,
    required double heightCm,
  }) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Calculate BMI using imperial units (lbs, total inches).
  static double calculateImperial({
    required double weightLbs,
    required double heightInches,
  }) {
    if (heightInches <= 0) return 0.0;
    final bmi = 703.0 * weightLbs / (heightInches * heightInches);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Unit conversion: kg to lbs
  static double kgToLbs(double kg) => (kg * 2.20462).roundToDouble();

  /// Unit conversion: lbs to kg
  static double lbsToKg(double lbs) => (lbs / 2.20462).roundToDouble();

  /// Unit conversion: cm to total inches
  static double cmToInches(double cm) => (cm / 2.54).roundToDouble();

  /// Unit conversion: total inches to cm
  static double inchesToCm(double inches) => (inches * 2.54).roundToDouble();

  /// Formats inches as feet'inches" (e.g. 66 inches -> 5'6")
  static String formatFeetInches(double totalInches) {
    final rounded = totalInches.round();
    final feet = rounded ~/ 12;
    final inches = rounded % 12;
    return "$feet'$inches\"";
  }
}
