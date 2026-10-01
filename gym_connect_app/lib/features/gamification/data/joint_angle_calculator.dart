import 'dart:math' as math;

class PosePoint {
  final double x;
  final double y;
  final double confidence;

  const PosePoint({required this.x, required this.y, this.confidence = 1.0});
}

/// Pure Dart biomechanics angle calculator for 2D/3D pose landmarks.
class JointAngleCalculator {
  /// Calculates the interior angle (in degrees) between three points:
  /// [a] first joint, [b] vertex joint, [c] third joint.
  /// Example for Squats: [a] = Hip, [b] = Knee, [c] = Ankle.
  static double calculateAngle(PosePoint a, PosePoint b, PosePoint c) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x);
    var angle = radians.abs() * (180.0 / math.pi);

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }

    return double.parse(angle.toStringAsFixed(1));
  }

  /// Calculates a smooth moving average of recent angles to prevent jitter.
  static double smoothedAngle(List<double> recentAngles) {
    if (recentAngles.isEmpty) return 0.0;
    final sum = recentAngles.fold(0.0, (prev, val) => prev + val);
    return double.parse((sum / recentAngles.length).toStringAsFixed(1));
  }
}
