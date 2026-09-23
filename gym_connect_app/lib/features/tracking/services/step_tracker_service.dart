import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
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
  final service = StepTrackerService(storage, client);
  ref.onDispose(() => service.dispose());
  return service;
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
  void pauseTracking() {
    _isPaused = true;
    _storage?.saveTrackerPausedState(true).ignore();
  }

  void resumeTracking() {
    _isPaused = false;
    _storage?.saveTrackerPausedState(false).ignore();
  }

  int _lastKnownDailySteps = 0;
  int? _lastHardwareReading;
  String _pedestrianStatus = 'walking';
  StreamSubscription<StepCount>? _pedometerSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianSubscription;
  final StreamController<int> _hardwareStepController = StreamController<int>.broadcast();

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
        // Request Android Activity Recognition runtime permission
        try {
          final status = await Permission.activityRecognition.status;
          if (!status.isGranted) {
            await Permission.activityRecognition.request();
          }
        } catch (e) {
          debugPrint('StepTrackerService: Activity recognition permission request error: $e');
        }

        final available = await isHealthConnectAvailable();
        if (!available) {
          debugPrint('StepTrackerService: Health Connect is not available on Android device');
          return HealthAuthResult.healthConnectNotInstalled;
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

  void _initHardwarePedometer() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS) || _mockStream != null) return;
    if (_pedometerSubscription != null) return;

    try {
      _pedestrianSubscription = Pedometer.pedestrianStatusStream.listen(
        (event) {
          _pedestrianStatus = event.status;
        },
        onError: (err) {
          debugPrint('StepTrackerService: Pedestrian status error: $err');
        },
        cancelOnError: false,
      );

      _pedometerSubscription = Pedometer.stepCountStream.listen(
        (event) {
          _handleHardwareStepCount(event.steps);
        },
        onError: (err) {
          debugPrint('StepTrackerService: Hardware pedometer error: $err');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('StepTrackerService: Hardware sensor initialization error: $e');
    }
  }

  void _handleHardwareStepCount(int bootSteps) {
    if (_isPaused) {
      _lastHardwareReading = bootSteps;
      return;
    }

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    if (_lastHardwareReading == null) {
      _lastHardwareReading = bootSteps;
      _storage?.saveLastHardwareReading(bootSteps, todayStr).ignore();
      return;
    }

    final delta = bootSteps - _lastHardwareReading!;
    _lastHardwareReading = bootSteps;
    _storage?.saveLastHardwareReading(bootSteps, todayStr).ignore();

    // Sanity filter: Ignore negative (reboot) or unrealistic single-tick jumps (> 500)
    // Anti-noise filter: If pedestrian status is explicitly 'stopped', ignore micro-vibrations
    if (delta > 0 && delta < 500 && _pedestrianStatus != 'stopped') {
      _lastKnownDailySteps += delta;
      saveLocalSteps(_lastKnownDailySteps).ignore();
      if (!_hardwareStepController.isClosed) {
        _hardwareStepController.add(_lastKnownDailySteps);
      }
    }
  }

  Future<void> saveBackgroundCheckpoint(int steps, {required bool isPaused}) async {
    _isPaused = isPaused;
    _lastKnownDailySteps = steps;
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    await _storage?.saveTodaySteps(steps, todayStr);
    await _storage?.saveTrackerPausedState(isPaused);
    if (_lastHardwareReading != null) {
      await _storage?.saveLastHardwareReading(_lastHardwareReading!, todayStr);
    }
  }

  Future<int?> fetchDailySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    if (_mockGetTotalSteps != null) {
      return await _mockGetTotalSteps(midnight, now);
    }

    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        return _lastKnownDailySteps > 0 ? _lastKnownDailySteps : null;
      }
      final healthSteps = await Health().getTotalStepsInInterval(
        midnight,
        now,
        includeManualEntry: false,
      );
      if (healthSteps != null && healthSteps >= 0) {
        // Synchronize with higher count if Health Connect / Google Fit recorded more steps
        if (healthSteps > _lastKnownDailySteps) {
          _lastKnownDailySteps = healthSteps;
        }
        await saveLocalSteps(_lastKnownDailySteps);
        return _lastKnownDailySteps;
      }
      return _lastKnownDailySteps > 0 ? _lastKnownDailySteps : null;
    } catch (e) {
      debugPrint('StepTrackerService: fetchDailySteps error: $e');
      return _lastKnownDailySteps > 0 ? _lastKnownDailySteps : null;
    }
  }

  Stream<int> get liveStepStream {
    final mock = _mockStream;
    if (mock != null) return mock;

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const Stream.empty();
    }

    _initHardwarePedometer();

    final healthStream = Stream.periodic(const Duration(seconds: 4))
        .where((_) => !_isPaused)
        .asyncMap((_) => fetchDailySteps())
        .where((steps) => steps != null)
        .map((steps) => steps!);

    final hardwareStream = _hardwareStepController.stream.where((_) => !_isPaused);

    late final StreamController<int> mergedController;
    StreamSubscription<int>? sub1;
    StreamSubscription<int>? sub2;

    mergedController = StreamController<int>.broadcast(
      onListen: () {
        sub1 = hardwareStream.listen(
          (steps) {
            if (!mergedController.isClosed) mergedController.add(steps);
          },
          onError: (e) {
            if (!mergedController.isClosed) mergedController.addError(e);
          },
        );
        sub2 = healthStream.listen(
          (steps) {
            if (!mergedController.isClosed) mergedController.add(steps);
          },
          onError: (e) {
            if (!mergedController.isClosed) mergedController.addError(e);
          },
        );
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
      },
    );

    return mergedController.stream;
  }

  Future<int> loadTodayBaseline() async {
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    // Check if tracker was previously paused
    if (_storage != null) {
      _isPaused = await _storage.getTrackerPausedState();
    }

    final healthSteps = await fetchDailySteps();
    if (healthSteps != null && healthSteps > 0) {
      _lastKnownDailySteps = healthSteps;
    }

    if (_storage != null) {
      final savedSteps = await _storage.getTodaySteps(todayStr);
      if (savedSteps != null && savedSteps > _lastKnownDailySteps) {
        _lastKnownDailySteps = savedSteps;
      }

      // Reconcile steps taken while app was closed if not paused
      if (!_isPaused && _lastHardwareReading != null) {
        final lastSavedHw = await _storage.getLastHardwareReading(todayStr);
        if (lastSavedHw != null && _lastHardwareReading! > lastSavedHw) {
          final closedAppDelta = _lastHardwareReading! - lastSavedHw;
          if (closedAppDelta > 0 && closedAppDelta < 50000) {
            _lastKnownDailySteps += closedAppDelta;
            await saveLocalSteps(_lastKnownDailySteps);
          }
        }
      }
    }

    if (_lastKnownDailySteps > 0) {
      return _lastKnownDailySteps;
    }

    final client = _supabase;
    if (client != null && client.auth.currentUser != null) {
      try {
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
          _lastKnownDailySteps = count;
          return count;
        }
      } catch (e) {
        debugPrint('StepTrackerService: loadTodayBaseline error: $e');
      }
    }

    return _lastKnownDailySteps;
  }

  Future<void> saveLocalSteps(int steps) async {
    _lastKnownDailySteps = steps;
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

  void dispose() {
    _pedometerSubscription?.cancel();
    _pedestrianSubscription?.cancel();
    _hardwareStepController.close();
  }
}
