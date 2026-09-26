import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFF09090B);
  static const Color surface = Color(0xFF18181B);
  static Color _activeAccent = const Color(0xFFCCFF00);

  /// Dynamically reflects the currently active tenant brand accent color at runtime.
  static Color get primaryAccent => _activeAccent;
  static Color get primary => _activeAccent;

  /// Updates the active brand accent color system-wide at runtime.
  static void setPrimaryAccent(Color color) {
    _activeAccent = color;
  }

  /// Retrieves the dynamically active accent color from the current Theme context.
  static Color accent(BuildContext context) => Theme.of(context).colorScheme.primary;

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color border = Color(0xFF27272A);
}
