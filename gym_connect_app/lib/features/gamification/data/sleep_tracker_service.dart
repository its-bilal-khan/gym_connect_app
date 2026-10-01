import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

enum SleepSource { healthKit, healthConnect, manual, none }

class SleepDataResult {
  final double hours;
  final int asleepMinutes;
  final SleepSource source;
  final int pointsAwarded;
  final bool isSensorVerified;

  const SleepDataResult({
    required this.hours,
    required this.asleepMinutes,
    required this.source,
    required this.pointsAwarded,
    required this.isSensorVerified,
  });

  static int calculatePoints(double hours, SleepSource source) {
    if (source == SleepSource.healthKit || source == SleepSource.healthConnect) {
      if (hours >= 7.0) return 10;
      if (hours >= 5.0) return 7;
      if (hours > 0.0) return 3;
      return 0;
    }
    // Anti-cheat: manual entry is capped at 3 points
    if (hours >= 7.0) return 3;
    if (hours >= 5.0) return 2;
    if (hours > 0.0) return 1;
    return 0;
  }
}

final sleepTrackerServiceProvider = Provider<SleepTrackerService>((ref) {
  return SleepTrackerService();
});

class SleepTrackerService {
  final Health? _health;

  SleepTrackerService([Health? health])
      : _health = health ?? (!kIsWeb && (Platform.isAndroid || Platform.isIOS) ? Health() : null);

  static const List<HealthDataType> _sleepTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_IN_BED,
  ];

  Future<SleepDataResult> fetchSensorSleep() async {
    if (_health == null || kIsWeb) {
      return const SleepDataResult(
        hours: 0.0,
        asleepMinutes: 0,
        source: SleepSource.none,
        pointsAwarded: 0,
        isSensorVerified: false,
      );
    }

    try {
      final now = DateTime.now();
      final startTime = DateTime(now.year, now.month, now.day - 1, 18, 0);
      final endTime = DateTime(now.year, now.month, now.day, 14, 0);

      final hasPerm = await _health.hasPermissions(_sleepTypes);
      if (hasPerm != true) {
        final granted = await _health.requestAuthorization(_sleepTypes);
        if (!granted) {
          return const SleepDataResult(
            hours: 0.0,
            asleepMinutes: 0,
            source: SleepSource.none,
            pointsAwarded: 0,
            isSensorVerified: false,
          );
        }
      }

      final data = await _health.getHealthDataFromTypes(
        types: _sleepTypes,
        startTime: startTime,
        endTime: endTime,
      );

      int totalMinutes = 0;
      for (final point in data) {
        final diff = point.dateTo.difference(point.dateFrom).inMinutes;
        if (diff > 0 && diff < 900) {
          totalMinutes += diff;
        }
      }

      final hours = double.parse((totalMinutes / 60.0).toStringAsFixed(1));
      final source = Platform.isIOS ? SleepSource.healthKit : SleepSource.healthConnect;
      final points = SleepDataResult.calculatePoints(hours, source);

      return SleepDataResult(
        hours: hours,
        asleepMinutes: totalMinutes,
        source: source,
        pointsAwarded: points,
        isSensorVerified: totalMinutes > 0,
      );
    } catch (_) {
      return const SleepDataResult(
        hours: 0.0,
        asleepMinutes: 0,
        source: SleepSource.none,
        pointsAwarded: 0,
        isSensorVerified: false,
      );
    }
  }

  SleepDataResult logManualSleep(double hours) {
    final clampedHours = hours.clamp(0.0, 16.0);
    final minutes = (clampedHours * 60).round();
    final points = SleepDataResult.calculatePoints(clampedHours, SleepSource.manual);
    return SleepDataResult(
      hours: clampedHours,
      asleepMinutes: minutes,
      source: SleepSource.manual,
      pointsAwarded: points,
      isSensorVerified: false,
    );
  }
}
