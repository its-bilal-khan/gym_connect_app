import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/vision_ai_config.dart';

/// Repository managing backend RPC persistence for Vision AI Live Trainer configuration.
class VisionAiConfigRepository {
  final SupabaseClient? _supabase;

  const VisionAiConfigRepository(this._supabase);

  Future<VisionAiConfig> fetchEffectiveConfig(String? tenantId) async {
    if (_supabase == null) return const VisionAiConfig();

    try {
      final res = await _supabase.rpc(
        'rpc_get_vision_ai_config',
        params: {'p_tenant_id': tenantId},
      );
      if (res is Map<String, dynamic>) {
        return VisionAiConfig.fromJson(res);
      }
    } catch (e) {
      debugPrint('VisionAiConfigRepository fetchEffectiveConfig error: $e');
    }
    return const VisionAiConfig();
  }

  Future<bool> updateGlobalConfig(
    VisionAiConfig config, {
    bool? allowTenantOverride,
  }) async {
    if (_supabase == null) return false;

    try {
      await _supabase.rpc('rpc_update_vision_ai_config', params: {
        'p_tenant_id': null,
        'p_config': config.toJson(),
        'p_allow_tenant_override': allowTenantOverride,
      });
      return true;
    } catch (e) {
      debugPrint('VisionAiConfigRepository updateGlobalConfig error: $e');
      return false;
    }
  }

  Future<bool> updateTenantConfig(
    String tenantId,
    VisionAiConfig config,
  ) async {
    if (_supabase == null) return false;

    try {
      await _supabase.rpc('rpc_update_vision_ai_config', params: {
        'p_tenant_id': tenantId,
        'p_config': config.toJson(),
      });
      return true;
    } catch (e) {
      debugPrint('VisionAiConfigRepository updateTenantConfig error: $e');
      return false;
    }
  }
}
