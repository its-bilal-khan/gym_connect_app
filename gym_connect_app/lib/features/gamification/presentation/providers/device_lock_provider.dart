import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/device_id_service.dart';

class DeviceLockState {
  final String deviceId;
  final String? primaryDeviceId;
  final DeviceLockStatus status;
  final bool isValid;
  final bool isLoading;
  final String message;

  const DeviceLockState({
    this.deviceId = '',
    this.primaryDeviceId,
    this.status = DeviceLockStatus.unverified,
    this.isValid = true,
    this.isLoading = false,
    this.message = '',
  });

  bool get isMismatch => status == DeviceLockStatus.mismatch;
}

final deviceLockProvider =
    NotifierProvider<DeviceLockNotifier, DeviceLockState>(DeviceLockNotifier.new);

class DeviceLockNotifier extends Notifier<DeviceLockState> {
  DeviceIdService get _service => ref.read(deviceIdServiceProvider);

  @override
  DeviceLockState build() {
    Future.microtask(() => checkDeviceLock());
    return const DeviceLockState(isLoading: true);
  }

  Future<void> checkDeviceLock() async {
    state = DeviceLockState(isLoading: true, deviceId: state.deviceId);
    String? userId;
    try {
      userId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {}

    final deviceId = await _service.getDeviceId();
    if (userId == null) {
      state = DeviceLockState(
        deviceId: deviceId,
        primaryDeviceId: deviceId,
        status: DeviceLockStatus.valid,
        isValid: true,
        isLoading: false,
        message: 'Guest / Offline mode: local hardware signature verified.',
      );
      return;
    }

    final result = await _service.verifyOrBindDevice(userId);
    state = DeviceLockState(
      deviceId: result.deviceId,
      primaryDeviceId: result.primaryDeviceId,
      status: result.status,
      isValid: result.isValid,
      isLoading: false,
      message: result.message,
    );
  }
}
