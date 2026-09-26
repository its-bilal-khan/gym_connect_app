import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/tenant_repository.dart';
import '../../domain/models/tenant_model.dart';

final tenantSearchQueryProvider =
    NotifierProvider<TenantSearchQueryNotifier, String>(TenantSearchQueryNotifier.new);

class TenantSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
}

final tenantFilterStatusProvider =
    NotifierProvider<TenantFilterStatusNotifier, String>(TenantFilterStatusNotifier.new);

class TenantFilterStatusNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setStatus(String s) => state = s;
}

final superAdminTenantsNotifierProvider =
    AsyncNotifierProvider<SuperAdminTenantsNotifier, List<TenantModel>>(
  SuperAdminTenantsNotifier.new,
);

class SuperAdminTenantsNotifier extends AsyncNotifier<List<TenantModel>> {
  @override
  Future<List<TenantModel>> build() async {
    final repo = ref.read(tenantRepositoryProvider);
    return repo.fetchAllTenants();
  }

  Future<void> refreshTenants() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tenantRepositoryProvider);
      return repo.fetchAllTenants();
    });
  }

  Future<TenantModel?> createTenant(TenantModel newTenant) async {
    try {
      final repo = ref.read(tenantRepositoryProvider);
      final created = await repo.registerNewTenant(newTenant);
      state = AsyncValue.data([created, ...?state.value]);
      return created;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateStatus({
    required String tenantId,
    required String newStatus,
    required bool isActive,
  }) async {
    final repo = ref.read(tenantRepositoryProvider);
    final ok = await repo.updateTenantStatus(
      tenantId: tenantId,
      newStatus: newStatus,
      isActive: isActive,
    );

    if (ok) {
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((t) {
          if (t.id == tenantId) {
            return t.copyWith(subscriptionStatus: newStatus, isActive: isActive);
          }
          return t;
        }).toList(),
      );
    }
    return ok;
  }

  Future<bool> toggleFeature({
    required String tenantId,
    required String featureKey,
    required bool enabled,
  }) async {
    final current = state.value ?? [];
    final target = current.where((t) => t.id == tenantId).firstOrNull;
    if (target == null) return false;

    final existingFeatures = {
      'ai_trainer_enabled': target.aiTrainerEnabled,
      'pos_enabled': target.posEnabled,
      'esp32_gate_enabled': target.esp32GateEnabled,
      'store_enabled': target.storeEnabled,
    };

    final repo = ref.read(tenantRepositoryProvider);
    final ok = await repo.toggleTenantFeature(
      tenantId: tenantId,
      featureKey: featureKey,
      enabled: enabled,
      existingFeatures: existingFeatures,
    );

    if (ok) {
      state = AsyncValue.data(
        current.map((t) {
          if (t.id == tenantId) {
            switch (featureKey) {
              case 'ai_trainer_enabled':
                return t.copyWith(aiTrainerEnabled: enabled);
              case 'pos_enabled':
                return t.copyWith(posEnabled: enabled);
              case 'esp32_gate_enabled':
                return t.copyWith(esp32GateEnabled: enabled);
              case 'store_enabled':
                return t.copyWith(storeEnabled: enabled);
            }
          }
          return t;
        }).toList(),
      );
    }
    return ok;
  }
}

final filteredTenantsProvider = Provider<List<TenantModel>>((ref) {
  final tenantsAsync = ref.watch(superAdminTenantsNotifierProvider);
  final query = ref.watch(tenantSearchQueryProvider).toLowerCase().trim();
  final status = ref.watch(tenantFilterStatusProvider);

  return tenantsAsync.maybeWhen(
    data: (tenants) {
      return tenants.where((t) {
        final matchesQuery = query.isEmpty ||
            t.name.toLowerCase().contains(query) ||
            t.city.toLowerCase().contains(query) ||
            t.slug.toLowerCase().contains(query);

        final matchesStatus = status == 'All' ||
            t.subscriptionStatus.toLowerCase() == status.toLowerCase();

        return matchesQuery && matchesStatus;
      }).toList();
    },
    orElse: () => [],
  );
});

class GlobalSaaSMetrics {
  final int totalTenants;
  final int activeTenants;
  final int trialTenants;
  final int suspendedTenants;
  final int totalMembersAcrossGyms;
  final double totalMonthlyMRRPKR;

  const GlobalSaaSMetrics({
    required this.totalTenants,
    required this.activeTenants,
    required this.trialTenants,
    required this.suspendedTenants,
    required this.totalMembersAcrossGyms,
    required this.totalMonthlyMRRPKR,
  });
}

final globalSaaSMetricsProvider = Provider<GlobalSaaSMetrics>((ref) {
  final tenants = ref.watch(superAdminTenantsNotifierProvider).value ?? [];
  int active = 0;
  int trial = 0;
  int suspended = 0;
  int totalMembers = 0;
  double mrr = 0.0;

  for (final t in tenants) {
    if (t.subscriptionStatus.toLowerCase() == 'active') {
      active++;
      mrr += t.monthlySaaSPKR;
    } else if (t.subscriptionStatus.toLowerCase() == 'trial') {
      trial++;
    } else if (t.subscriptionStatus.toLowerCase() == 'suspended') {
      suspended++;
    }
    totalMembers += t.activeMembersCount;
  }

  return GlobalSaaSMetrics(
    totalTenants: tenants.length,
    activeTenants: active,
    trialTenants: trial,
    suspendedTenants: suspended,
    totalMembersAcrossGyms: totalMembers,
    totalMonthlyMRRPKR: mrr,
  );
});
