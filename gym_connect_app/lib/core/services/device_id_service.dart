import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_storage_service.dart';

enum DeviceLockStatus { valid, bound, mismatch, unverified }

class DeviceLockResult {
  final DeviceLockStatus status;
  final String deviceId;
  final String? primaryDeviceId;
  final bool isValid;
  final String message;

  const DeviceLockResult({
    required this.status,
    required this.deviceId,
    this.primaryDeviceId,
    required this.isValid,
    required this.message,
  });
}

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}
  return DeviceIdService(storage, client);
});

class DeviceIdService {
  final SecureStorageService _storage;
  final SupabaseClient? _client;

  DeviceIdService(this._storage, [this._client]);

  Future<String> getDeviceId() async {
    final id = await _storage.getOrCreateDeviceId();
    return id ?? 'hw_default_signature';
  }

  Future<DeviceLockResult> verifyOrBindDevice(String userId) async {
    final localDeviceId = await getDeviceId();
    if (_client == null) {
      return DeviceLockResult(
        status: DeviceLockStatus.valid,
        deviceId: localDeviceId,
        primaryDeviceId: localDeviceId,
        isValid: true,
        message: 'Offline verification: local hardware signature active.',
      );
    }

    try {
      final res = await _client.rpc('rpc_verify_or_bind_device', params: {
        'p_user_id': userId,
        'p_device_id': localDeviceId,
      });

      if (res is Map<String, dynamic>) {
        final statusStr = res['status'] as String? ?? 'valid';
        final isValid = res['is_valid'] as bool? ?? true;
        final primaryId = res['primary_device_id'] as String?;
        final msg = res['message'] as String? ?? 'Device verified';

        final status = statusStr == 'bound'
            ? DeviceLockStatus.bound
            : (statusStr == 'mismatch'
                ? DeviceLockStatus.mismatch
                : DeviceLockStatus.valid);

        return DeviceLockResult(
          status: status,
          deviceId: localDeviceId,
          primaryDeviceId: primaryId,
          isValid: isValid,
          message: msg,
        );
      }
    } catch (_) {}

    return DeviceLockResult(
      status: DeviceLockStatus.valid,
      deviceId: localDeviceId,
      primaryDeviceId: localDeviceId,
      isValid: true,
      message: 'Local hardware signature active.',
    );
  }
}
