import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/services/secure_storage_service.dart';
import '../../domain/models/workstation_item.dart';

final workstationsOrderProvider = NotifierProvider.family<
    WorkstationsOrderNotifier, List<WorkstationId>, String>(
  (tenantId) => WorkstationsOrderNotifier(tenantId),
);

class WorkstationsOrderNotifier extends Notifier<List<WorkstationId>> {
  final String tenantId;

  WorkstationsOrderNotifier(this.tenantId);

  String get _effectiveTenantId =>
      tenantId.isNotEmpty ? tenantId : '00000000-0000-0000-0000-000000000001';

  @override
  List<WorkstationId> build() {
    _loadPersistedOrder();
    return WorkstationId.defaultOrder;
  }

  Future<void> _loadPersistedOrder() async {
    final storage = ref.read(secureStorageProvider);

    // 1. Instant load from local storage
    final localJson = await storage.getWorkstationOrder(_effectiveTenantId);
    if (localJson != null && localJson.isNotEmpty) {
      final parsed = _parseOrder(localJson);
      if (parsed != null && parsed.isNotEmpty) {
        state = parsed;
      }
    }

    // 2. Load from Supabase tenants.branding JSONB
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('tenants')
          .select('branding')
          .eq('id', _effectiveTenantId)
          .maybeSingle();

      final branding = res?['branding'] as Map<String, dynamic>?;
      final remoteOrder = branding?['workstations_order'];
      if (remoteOrder != null) {
        final parsed = _parseOrder(remoteOrder);
        if (parsed != null && parsed.isNotEmpty) {
          state = parsed;
          await storage.saveWorkstationOrder(
            _effectiveTenantId,
            jsonEncode(parsed.map((e) => e.key).toList()),
          );
        }
      }
    } catch (e) {
      debugPrint('WorkstationsOrderNotifier: Supabase load notice: $e');
    }
  }

  List<WorkstationId>? _parseOrder(dynamic raw) {
    List<dynamic> list;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          list = decoded;
        } else {
          return null;
        }
      } catch (_) {
        return null;
      }
    } else if (raw is List) {
      list = raw;
    } else {
      return null;
    }

    final result = <WorkstationId>[];
    for (final item in list) {
      final id = WorkstationId.tryParse(item.toString());
      if (id != null && !result.contains(id)) {
        result.add(id);
      }
    }

    // Ensure all 6 workstations exist
    for (final defaultId in WorkstationId.defaultOrder) {
      if (!result.contains(defaultId)) {
        result.add(defaultId);
      }
    }

    return result;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= state.length ||
        newIndex < 0 ||
        newIndex >= state.length) {
      return;
    }

    final updated = List<WorkstationId>.from(state);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    // Immediate optimistic update
    state = updated;

    final encoded = jsonEncode(updated.map((e) => e.key).toList());
    final storage = ref.read(secureStorageProvider);

    // 1. Save locally for 0ms next-boot load
    await storage.saveWorkstationOrder(_effectiveTenantId, encoded);

    // 2. Persist to Supabase database in tenants.branding JSONB
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('tenants')
          .select('branding')
          .eq('id', _effectiveTenantId)
          .maybeSingle();

      final existingBranding =
          (res?['branding'] as Map<String, dynamic>?) ?? {};
      final updatedBranding = {
        ...existingBranding,
        'workstations_order': updated.map((e) => e.key).toList(),
        'workstations_order_updated_at': DateTime.now().toIso8601String(),
      };

      await client
          .from('tenants')
          .update({'branding': updatedBranding})
          .eq('id', _effectiveTenantId);
    } catch (e) {
      debugPrint('WorkstationsOrderNotifier: Supabase persist error: $e');
    }
  }

  Future<void> resetToDefault() async {
    state = WorkstationId.defaultOrder;
    final encoded =
        jsonEncode(WorkstationId.defaultOrder.map((e) => e.key).toList());
    final storage = ref.read(secureStorageProvider);
    await storage.saveWorkstationOrder(_effectiveTenantId, encoded);

    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('tenants')
          .select('branding')
          .eq('id', _effectiveTenantId)
          .maybeSingle();

      final existingBranding =
          (res?['branding'] as Map<String, dynamic>?) ?? {};
      final updatedBranding = {
        ...existingBranding,
        'workstations_order':
            WorkstationId.defaultOrder.map((e) => e.key).toList(),
        'workstations_order_updated_at': DateTime.now().toIso8601String(),
      };

      await client
          .from('tenants')
          .update({'branding': updatedBranding})
          .eq('id', _effectiveTenantId);
    } catch (e) {
      debugPrint('WorkstationsOrderNotifier: Supabase reset error: $e');
    }
  }
}
