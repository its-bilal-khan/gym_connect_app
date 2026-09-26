import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'secure_storage_stub.dart'
    if (dart.library.html) 'secure_storage_web.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(
    FlutterSecureStorage(
      webOptions: WebOptions(
        dbName: 'GymConnectDb',
        publicKey: 'GymConnectAppKey',
      ),
    ),
  );
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              webOptions: WebOptions(
                dbName: 'GymConnectDb',
                publicKey: 'GymConnectAppKey',
              ),
            );

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
    if (kIsWeb) {
      webStorageWrite(key, value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final webVal = webStorageRead(key);
      if (webVal != null && webVal.isNotEmpty) return webVal;
    }
    try {
      final val = await _storage.read(key: key);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    if (kIsWeb) {
      return webStorageRead(key);
    }
    return null;
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
    if (kIsWeb) {
      webStorageDelete(key);
    }
  }

  Future<void> saveToken(String token) async {
    await _write(AppConstants.tokenKey, token);
  }

  Future<String?> getToken() async {
    return _read(AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _delete(AppConstants.tokenKey);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _write(AppConstants.refreshTokenKey, refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return _read(AppConstants.refreshTokenKey);
  }

  Future<void> saveActiveRole(String role) async {
    await _write(AppConstants.activeRoleKey, role);
  }

  Future<String?> getActiveRole() async {
    return _read(AppConstants.activeRoleKey);
  }

  Future<void> saveTenantId(String tenantId) async {
    await _write(AppConstants.tenantIdKey, tenantId);
  }

  Future<String?> getTenantId() async {
    return _read(AppConstants.tenantIdKey);
  }

  Future<void> saveUserAccentColor(String hex) async {
    await _write('gym_user_accent_color', hex);
  }

  Future<String?> getUserAccentColor() async {
    return _read('gym_user_accent_color');
  }

  Future<void> saveTodaySteps(int steps, String date) async {
    await _write(AppConstants.todayStepsKey, steps.toString());
    await _write(AppConstants.todayStepsDateKey, date);
  }

  Future<int?> getTodaySteps(String date) async {
    final savedDate = await _read(AppConstants.todayStepsDateKey);
    if (savedDate == date) {
      final val = await _read(AppConstants.todayStepsKey);
      if (val != null) return int.tryParse(val);
    }
    return null;
  }

  Future<void> saveTrackerPausedState(bool isPaused) async {
    await _write(AppConstants.isPausedKey, isPaused.toString());
  }

  Future<bool> getTrackerPausedState() async {
    final val = await _read(AppConstants.isPausedKey);
    return val == 'true';
  }

  Future<void> saveLastHardwareReading(int reading, String date) async {
    await _write(AppConstants.lastHardwareReadingKey, '$date:$reading');
  }

  Future<int?> getLastHardwareReading(String date) async {
    final val = await _read(AppConstants.lastHardwareReadingKey);
    if (val != null && val.startsWith('$date:')) {
      final parts = val.split(':');
      if (parts.length >= 2) return int.tryParse(parts[1]);
    }
    return null;
  }

  Future<void> saveSelectedBodyType(String bodyType) async {
    await _write(AppConstants.selectedBodyTypeKey, bodyType);
  }

  Future<String?> getSelectedBodyType() async {
    return _read(AppConstants.selectedBodyTypeKey);
  }

  Future<void> saveFitnessGoal(String goal) async {
    await _write(AppConstants.fitnessGoalKey, goal);
  }

  Future<String?> getFitnessGoal() async {
    return _read(AppConstants.fitnessGoalKey);
  }

  Future<void> savePlacedOrderId(String orderId) async {
    try {
      final existing = await _read(AppConstants.lastOrderIdsKey);
      final list = (existing != null && existing.isNotEmpty) ? existing.split(',') : <String>[];
      if (!list.contains(orderId)) {
        list.insert(0, orderId);
        if (list.length > 10) list.removeRange(10, list.length);
        await _write(AppConstants.lastOrderIdsKey, list.join(','));
      }
    } catch (_) {}
  }

  Future<List<String>> getPlacedOrderIds() async {
    try {
      final existing = await _read(AppConstants.lastOrderIdsKey);
      if (existing != null && existing.isNotEmpty) {
        return existing.split(',').where((e) => e.isNotEmpty).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> deleteActiveRole() async {
    await _delete(AppConstants.activeRoleKey);
    await _delete(AppConstants.activeNavIndexKey);
    await _delete(AppConstants.persistedProfileKey);
  }

  Future<void> saveActiveNavIndex(int index) async {
    await _write(AppConstants.activeNavIndexKey, index.toString());
  }

  Future<int?> getActiveNavIndex() async {
    final val = await _read(AppConstants.activeNavIndexKey);
    return val != null ? int.tryParse(val) : null;
  }

  Future<void> saveActiveSubTab(String viewKey, int tabIndex) async {
    await _write('${AppConstants.activeSubTabKey}_$viewKey', tabIndex.toString());
  }

  Future<int?> getActiveSubTab(String viewKey) async {
    final val = await _read('${AppConstants.activeSubTabKey}_$viewKey');
    return val != null ? int.tryParse(val) : null;
  }

  Future<void> savePersistedProfileJson(String jsonStr) async {
    await _write(AppConstants.persistedProfileKey, jsonStr);
  }

  Future<String?> getPersistedProfileJson() async {
    return _read(AppConstants.persistedProfileKey);
  }

  Future<void> saveProtocolStudioGridView(bool isGridView) async {
    await _write('protocol_studio_is_grid_view', isGridView.toString());
  }

  Future<bool> getProtocolStudioGridView() async {
    final val = await _read('protocol_studio_is_grid_view');
    return val == 'true';
  }

  Future<void> saveMuscleWikiApiKey(String apiKey) async {
    await _write('musclewiki_api_key', apiKey.trim());
  }

  Future<String?> getMuscleWikiApiKey() async {
    final key = await _read('musclewiki_api_key');
    if (key != null && key.trim().isNotEmpty) return key.trim();
    if (dotenv.isInitialized) {
      final envKey = dotenv.env['MUSCLEWIKI_API_KEY'];
      if (envKey != null && envKey.trim().isNotEmpty) return envKey.trim();
    }
    return null;
  }

  Future<void> saveMembersRoster(String tenantId, String rosterJson) async {
    final key = 'gym_members_roster_${tenantId.trim()}';
    await _write(key, rosterJson);
  }

  Future<String?> getMembersRoster(String tenantId) async {
    final key = 'gym_members_roster_${tenantId.trim()}';
    return _read(key);
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    if (kIsWeb) {
      webStorageClear();
    }
  }
}
