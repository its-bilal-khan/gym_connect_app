import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(FlutterSecureStorage());
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveActiveRole(String role) async {
    await _storage.write(key: AppConstants.activeRoleKey, value: role);
  }

  Future<String?> getActiveRole() async {
    return _storage.read(key: AppConstants.activeRoleKey);
  }

  Future<void> saveTenantId(String tenantId) async {
    await _storage.write(key: AppConstants.tenantIdKey, value: tenantId);
  }

  Future<String?> getTenantId() async {
    return _storage.read(key: AppConstants.tenantIdKey);
  }

  Future<void> saveTodaySteps(int steps, String date) async {
    await _storage.write(key: AppConstants.todayStepsKey, value: steps.toString());
    await _storage.write(key: AppConstants.todayStepsDateKey, value: date);
  }

  Future<int?> getTodaySteps(String date) async {
    final savedDate = await _storage.read(key: AppConstants.todayStepsDateKey);
    if (savedDate == date) {
      final val = await _storage.read(key: AppConstants.todayStepsKey);
      if (val != null) return int.tryParse(val);
    }
    return null;
  }

  Future<void> saveTrackerPausedState(bool isPaused) async {
    await _storage.write(key: AppConstants.isPausedKey, value: isPaused.toString());
  }

  Future<bool> getTrackerPausedState() async {
    final val = await _storage.read(key: AppConstants.isPausedKey);
    return val == 'true';
  }

  Future<void> saveLastHardwareReading(int reading, String date) async {
    await _storage.write(key: AppConstants.lastHardwareReadingKey, value: '$date:$reading');
  }

  Future<int?> getLastHardwareReading(String date) async {
    final val = await _storage.read(key: AppConstants.lastHardwareReadingKey);
    if (val != null && val.startsWith('$date:')) {
      final parts = val.split(':');
      if (parts.length >= 2) return int.tryParse(parts[1]);
    }
    return null;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
