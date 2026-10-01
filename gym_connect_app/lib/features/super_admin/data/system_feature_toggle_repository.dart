import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/providers/auth_notifier.dart';
import '../../auth/presentation/providers/auth_state.dart';
import '../domain/models/system_feature_flags.dart';

final currentTenantFeatureFlagsProvider =
    FutureProvider<SystemFeatureFlags>((ref) async {
  String? tenantId;
  final auth = ref.watch(authNotifierProvider);
  if (auth is AuthAuthenticated) {
    tenantId = auth.profile.tenantId;
  }
  return ref.watch(effectiveFeatureFlagsProvider(tenantId).future);
});

final maxAllowedAiAgeProvider = Provider<int>((ref) {
  final flags = ref.watch(currentTenantFeatureFlagsProvider).asData?.value;
  return flags?.maxAllowedAiAge ?? 55;
});

final systemFeatureToggleRepositoryProvider =
    Provider<SystemFeatureToggleRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('SystemFeatureToggleRepository: Supabase client unavailable: $e');
  }
  return SystemFeatureToggleRepository(client);
});

final effectiveFeatureFlagsProvider =
    FutureProvider.family<SystemFeatureFlags, String?>((ref, tenantId) async {
  final repo = ref.watch(systemFeatureToggleRepositoryProvider);
  return repo.fetchEffectiveFeatureFlags(tenantId);
});

final globalSystemSettingsProvider =
    FutureProvider<List<GlobalSystemConfig>>((ref) async {
  final repo = ref.watch(systemFeatureToggleRepositoryProvider);
  return repo.fetchGlobalSettings();
});

class SystemFeatureToggleRepository {
  final SupabaseClient? _supabase;

  const SystemFeatureToggleRepository(this._supabase);

  Future<SystemFeatureFlags> fetchEffectiveFeatureFlags(String? tenantId) async {
    if (_supabase == null) return const SystemFeatureFlags();

    try {
      final res = await _supabase.rpc(
        'rpc_get_effective_feature_flags',
        params: {'p_tenant_id': tenantId},
      );
      if (res is Map<String, dynamic>) {
        return SystemFeatureFlags.fromJson(res);
      }
    } catch (e) {
      debugPrint('fetchEffectiveFeatureFlags error: $e');
    }
    return const SystemFeatureFlags();
  }

  Future<List<GlobalSystemConfig>> fetchGlobalSettings() async {
    if (_supabase == null) return [];

    try {
      final res = await _supabase
          .from('global_system_settings')
          .select()
          .order('key');
      return (res as List)
          .map((row) => GlobalSystemConfig.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchGlobalSettings error: $e');
      return [];
    }
  }

  Future<bool> setGlobalFeatureFlag(
    String featureKey,
    bool enabled, {
    bool? allowTenantOverride,
  }) async {
    if (_supabase == null) return false;

    try {
      await _supabase.rpc('rpc_super_admin_set_global_feature_flag', params: {
        'p_feature_key': featureKey,
        'p_enabled': enabled,
        'p_allow_tenant_override': allowTenantOverride,
      });
      return true;
    } catch (e) {
      debugPrint('setGlobalFeatureFlag error: $e');
      return false;
    }
  }

  Future<bool> setTenantFeatureFlag(
    String tenantId,
    String featureKey,
    bool enabled, {
    bool allowTenantOverride = false,
  }) async {
    if (_supabase == null) return false;

    try {
      await _supabase.rpc('rpc_super_admin_set_tenant_feature_flag', params: {
        'p_tenant_id': tenantId,
        'p_feature_key': featureKey,
        'p_enabled': enabled,
        'p_allow_tenant_override': allowTenantOverride,
      });
      return true;
    } catch (e) {
      debugPrint('setTenantFeatureFlag error: $e');
      return false;
    }
  }

  Future<bool> updateGlobalConfig(
    String configKey,
    Map<String, dynamic> value, {
    bool? allowTenantOverride,
  }) async {
    if (_supabase == null) return false;

    try {
      await _supabase.rpc('rpc_super_admin_update_global_config', params: {
        'p_config_key': configKey,
        'p_value': value,
        'p_allow_tenant_override': allowTenantOverride,
      });
      return true;
    } catch (e) {
      debugPrint('updateGlobalConfig error: $e');
      return false;
    }
  }
}
