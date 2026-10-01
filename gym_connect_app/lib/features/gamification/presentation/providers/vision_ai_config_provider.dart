import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/vision_ai_config_repository.dart';
import '../../domain/models/vision_ai_config.dart';

final visionAiConfigRepositoryProvider = Provider<VisionAiConfigRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('VisionAiConfigRepository: Supabase client unavailable: $e');
  }
  return VisionAiConfigRepository(client);
});

final effectiveVisionAiConfigProvider =
    FutureProvider.family<VisionAiConfig, String?>((ref, tenantId) async {
  final repo = ref.watch(visionAiConfigRepositoryProvider);
  return repo.fetchEffectiveConfig(tenantId);
});

final currentTenantVisionAiConfigProvider =
    FutureProvider<VisionAiConfig>((ref) async {
  String? tenantId;
  final auth = ref.watch(authNotifierProvider);
  if (auth is AuthAuthenticated) {
    tenantId = auth.profile.tenantId;
  }
  return ref.watch(effectiveVisionAiConfigProvider(tenantId).future);
});

/// Reactive notifier holding the actively loaded VisionAiConfig for UI components.
class VisionAiConfigNotifier extends Notifier<VisionAiConfig> {
  VisionAiConfig? _manualConfig;

  @override
  VisionAiConfig build() {
    if (_manualConfig != null) return _manualConfig!;
    final asyncVal = ref.watch(currentTenantVisionAiConfigProvider);
    return asyncVal.asData?.value ?? const VisionAiConfig();
  }

  void setConfig(VisionAiConfig newConfig) {
    _manualConfig = newConfig;
    state = newConfig;
  }

  void updateSquatDepth(double angle) {
    state = state.copyWith(squatDepthAngle: angle);
  }

  void updatePushupDepth(double angle) {
    state = state.copyWith(pushupDepthAngle: angle);
  }

  void updateBadPostureTrigger(int ms) {
    state = state.copyWith(badPostureTriggerMs: ms);
  }

  void updateTtsCooldown(double seconds) {
    state = state.copyWith(ttsCooldownSeconds: seconds);
  }

  void updateMicroClipDuration(int seconds) {
    state = state.copyWith(microClipDurationSec: seconds);
  }

  void toggleLiveTrainer(bool enabled) {
    state = state.copyWith(isLiveTrainerEnabled: enabled);
  }

  Future<bool> saveConfig({String? tenantId, bool? allowTenantOverride}) async {
    final repo = ref.read(visionAiConfigRepositoryProvider);
    bool success;
    if (tenantId != null) {
      success = await repo.updateTenantConfig(tenantId, state);
    } else {
      success = await repo.updateGlobalConfig(state, allowTenantOverride: allowTenantOverride);
    }

    if (success) {
      ref.invalidate(effectiveVisionAiConfigProvider(tenantId));
      ref.invalidate(effectiveVisionAiConfigProvider(null));
      ref.invalidate(currentTenantVisionAiConfigProvider);
    }
    return success;
  }
}

final visionAiConfigProvider =
    NotifierProvider<VisionAiConfigNotifier, VisionAiConfig>(VisionAiConfigNotifier.new);
