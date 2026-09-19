import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/secure_storage_service.dart';

enum HealthAuthResult {
  authorized,
  denied,
  healthConnectNotInstalled,
  unsupported,
  error,
}

final stepTrackerServiceProvider = Provider<StepTrackerService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}
  return StepTrackerService(storage, client);
});

class StepTrackerService {
  final SecureStorageService? _storage;
  final SupabaseClient? _supabase;
  final Stream<int>? _mockStream;
  final Future<int?> Function(DateTime start, DateTime end)? _mockGetTotalSteps;
  final Future<HealthAuthResult> Function()? _mockRequestAuth;
  final Future<bool> Function()? _mockOpenSettings;

  static const double kmPerStep = 0.000762;
  static const double kcalPerStep = 0.04;
  static const List<HealthDataType> stepDataTypes = [HealthDataType.STEPS];
  static const List<HealthDataAccess> stepPermissions = [HealthDataAccess.READ];
  static const MethodChannel _settingsChannel = MethodChannel('com.example.gym_connect_app/health_settings');

  bool _isPaused = false;
  bool get isPaused => _isPaused;
  void pauseTracking() => _isPaused = true;
  void resumeTracking() => _isPaused = false;

  StepTrackerService([
    this._storage,
    this._supabase,
    this._mockStream,
    this._mockGetTotalSteps,
    this._mockRequestAuth,
    this._mockOpenSettings,
  ]);

  double calculateDistance(int steps) => double.parse((steps * kmPerStep).toStringAsFixed(2));

  int calculateCalories(int steps) => (steps * kcalPerStep).round();

  Future<void> configureHealth() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      await Health().configure();
    } catch (e) {
      debugPrint('StepTrackerService: Health configure error: $e');
    }
  }

  Future<bool> isHealthConnectAvailable() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      return await Health().isHealthConnectAvailable();
    } catch (e) {
      debugPrint('StepTrackerService: isHealthConnectAvailable error: $e');
      return false;
    }
  }

  Future<void> installHealthConnect() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await Health().installHealthConnect();
    } catch (e) {
      debugPrint('StepTrackerService: installHealthConnect error: $e');
    }
  }

  Future<bool> hasStepPermission() async {
    if (_mockStream != null || _mockGetTotalSteps != null) return true;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return false;
    try {
      if (Platform.isAndroid && !(await isHealthConnectAvailable())) {
        return false;
      }
      final hasPerm = await Health().hasPermissions(
        stepDataTypes,
        permissions: stepPermissions,
      );
      return hasPerm ?? false;
    } catch (e) {
      debugPrint('StepTrackerService: hasPermissions error: $e');
      return false;
    }
  }

  Future<HealthAuthResult> requestHealthAuthorization() async {
    if (_mockRequestAuth != null) {
      return await _mockRequestAuth();
    }
    if (_mockStream != null || _mockGetTotalSteps != null) {
      return HealthAuthResult.authorized;
    }
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return HealthAuthResult.unsupported;
    }

    try {
      await configureHealth();

      if (Platform.isAndroid) {
        final available = await isHealthConnectAvailable();
        if (!available) {
          debugPrint('StepTrackerService: Health Connect is not available on Android device');
          return HealthAuthResult.healthConnectNotInstalled;
        }

        // Request Android Activity Recognition runtime permission before Health Connect prompt
        try {
          final status = await Permission.activityRecognition.status;
          if (!status.isGranted) {
            await Permission.activityRecognition.request();
          }
        } catch (e) {
          debugPrint('StepTrackerService: Activity recognition permission request error: $e');
        }
      }

      // Check if permission is already granted
      final alreadyGranted = await hasStepPermission();
      if (alreadyGranted) {
        return HealthAuthResult.authorized;
      }

      final authorized = await Health().requestAuthorization(
        stepDataTypes,
        permissions: stepPermissions,
      );

      if (authorized) {
        return HealthAuthResult.authorized;
      }

      // Double-check permission in case of platform reporting discrepancy
      final confirmed = await hasStepPermission();
      return confirmed ? HealthAuthResult.authorized : HealthAuthResult.denied;
    } catch (e) {
      debugPrint('StepTrackerService: Health authorization error: $e');
      if (e.toString().contains('Health Connect is not available')) {
        return HealthAuthResult.healthConnectNotInstalled;
      }
      return HealthAuthResult.error;
    }
  }

  Future<bool> openHealthSettings() async {
    if (_mockOpenSettings != null) {
      return await _mockOpenSettings();
    }
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      try {
        final res = await _settingsChannel.invokeMethod<bool>('openHealthConnectSettings');
        if (res == true) return true;
      } catch (e) {
        debugPrint('StepTrackerService: openHealthConnectSettings error: $e');
      }
    }

    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('StepTrackerService: openAppSettings fallback error: $e');
      return false;
    }
  }

  Future<bool> requestMotionPermission() async {
    final result = await requestHealthAuthorization();
    return result == HealthAuthResult.authorized;
  }

  Future<int?> fetchDailySteps() async {
    if (_isPaused) return null;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    if (_mockGetTotalSteps != null) {
      return await _mockGetTotalSteps(midnight, now);
    }

    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        return null;
      }
      final steps = await Health().getTotalStepsInInterval(
        midnight,
        now,
        includeManualEntry: false,
      );
      if (steps != null) {
        await saveLocalSteps(steps);
      }
      return steps;
    } catch (e) {
      debugPrint('StepTrackerService: fetchDailySteps error: $e');
      return null;
    }
  }

  Stream<int> get liveStepStream {
    final mock = _mockStream;
    if (mock != null) return mock;

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const Stream.empty();
    }

    return Stream.periodic(const Duration(seconds: 3))
        .where((_) => !_isPaused)
        .asyncMap((_) => fetchDailySteps())
        .where((steps) => steps != null)
        .map((steps) => steps!)
        .handleError((e) {
      debugPrint('StepTrackerService: health stream error: $e');
      throw e;
    });
  }

  Future<int> loadTodayBaseline() async {
    final healthSteps = await fetchDailySteps();
    if (healthSteps != null && healthSteps >= 0) {
      return healthSteps;
    }

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    try {
      if (_storage != null) {
        final localSteps = await _storage.getTodaySteps(todayStr);
        if (localSteps != null) return localSteps;
      }
      final client = _supabase;
      if (client != null && client.auth.currentUser != null) {
        final userId = client.auth.currentUser!.id;
        final res = await client
            .from('daily_step_logs')
            .select('step_count')
            .eq('user_id', userId)
            .eq('log_date', todayStr)
            .maybeSingle();
        if (res != null && res['step_count'] != null) {
          final count = (res['step_count'] as num).toInt();
          await _storage?.saveTodaySteps(count, todayStr);
          return count;
        }
      }
    } catch (e) {
      debugPrint('StepTrackerService: loadTodayBaseline error: $e');
    }
    return 0;
  }

  Future<void> saveLocalSteps(int steps) async {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    await _storage?.saveTodaySteps(steps, todayStr);
  }

  Future<void> syncStepLog({
    required String userId,
    required String tenantId,
    required int steps,
  }) async {
    final client = _supabase;
    if (client == null) return;

    final distance = calculateDistance(steps);
    final calories = calculateCalories(steps);
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    try {
      await client.from('daily_step_logs').upsert({
        'user_id': userId,
        'tenant_id': tenantId,
        'log_date': todayStr,
        'step_count': steps,
        'distance_km': distance,
        'calories_burned': calories,
      }, onConflict: 'user_id,log_date');

      await client.from('member_gamification').upsert({
        'user_id': userId,
        'tenant_id': tenantId,
        'daily_steps': steps,
        'daily_distance_km': distance,
        'daily_calories_burned': calories,
        'last_activity_date': todayStr,
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('StepTrackerService: sync error: $e');
    }
  }
}
