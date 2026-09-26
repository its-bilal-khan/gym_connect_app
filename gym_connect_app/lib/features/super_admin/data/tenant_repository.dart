import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/tenant_model.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}
  return TenantRepository(client);
});

class TenantRepository {
  final SupabaseClient? _client;

  const TenantRepository(this._client);

  static final List<TenantModel> fallbackTenants = [
    TenantModel(
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Titan Fitness Club',
      slug: 'titan-fitness',
      contactEmail: 'info@titanfitness.pk',
      contactPhone: '+92 300 1234567',
      address: 'Plot 14-B, Sector C, Phase 5, DHA',
      city: 'Lahore',
      country: 'Pakistan',
      subscriptionStatus: 'active',
      subscriptionTier: 'pro',
      maxMembers: 500,
      aiTrainerEnabled: true,
      posEnabled: true,
      esp32GateEnabled: true,
      storeEnabled: true,
      isActive: true,
      primaryColor: const Color(0xFFCCFF00),
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      activeMembersCount: 238,
    ),
    TenantModel(
      id: '00000000-0000-0000-0000-000000000002',
      name: 'Iron Peak Elite Gym',
      slug: 'iron-peak',
      contactEmail: 'reception@ironpeak.com.pk',
      contactPhone: '+92 321 9876543',
      address: 'Floor 3, Beverly Centre, Blue Area',
      city: 'Islamabad',
      country: 'Pakistan',
      subscriptionStatus: 'active',
      subscriptionTier: 'enterprise',
      maxMembers: 1000,
      aiTrainerEnabled: true,
      posEnabled: true,
      esp32GateEnabled: true,
      storeEnabled: true,
      isActive: true,
      primaryColor: const Color(0xFF00F0FF),
      createdAt: DateTime.now().subtract(const Duration(days: 85)),
      activeMembersCount: 512,
    ),
    TenantModel(
      id: '00000000-0000-0000-0000-000000000003',
      name: 'Sindh Athletic Club & Spa',
      slug: 'sindh-athletic',
      contactEmail: 'desk@sindhathletic.pk',
      contactPhone: '+92 333 4567890',
      address: 'Block 4, Marine Drive, Clifton',
      city: 'Karachi',
      country: 'Pakistan',
      subscriptionStatus: 'active',
      subscriptionTier: 'enterprise',
      maxMembers: 1200,
      aiTrainerEnabled: true,
      posEnabled: true,
      esp32GateEnabled: true,
      storeEnabled: true,
      isActive: true,
      primaryColor: const Color(0xFFA855F7),
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      activeMembersCount: 680,
    ),
    TenantModel(
      id: '00000000-0000-0000-0000-000000000004',
      name: 'Khyber Powerhouse Fitness',
      slug: 'khyber-powerhouse',
      contactEmail: 'contact@khyberpower.pk',
      contactPhone: '+92 345 8899001',
      address: 'Jamrud Road, University Town',
      city: 'Peshawar',
      country: 'Pakistan',
      subscriptionStatus: 'active',
      subscriptionTier: 'starter',
      maxMembers: 300,
      aiTrainerEnabled: false,
      posEnabled: true,
      esp32GateEnabled: false,
      storeEnabled: true,
      isActive: true,
      primaryColor: const Color(0xFFF59E0B),
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      activeMembersCount: 164,
    ),
    TenantModel(
      id: '00000000-0000-0000-0000-000000000005',
      name: 'Rawal Strength & Conditioning',
      slug: 'rawal-strength',
      contactEmail: 'ops@rawalstrength.com',
      contactPhone: '+92 312 3344556',
      address: 'Civic Center, Bahria Town Phase 4',
      city: 'Rawalpindi',
      country: 'Pakistan',
      subscriptionStatus: 'trial',
      subscriptionTier: 'pro',
      maxMembers: 400,
      aiTrainerEnabled: true,
      posEnabled: true,
      esp32GateEnabled: false,
      storeEnabled: false,
      isActive: true,
      primaryColor: const Color(0xFF10B981),
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      activeMembersCount: 88,
    ),
    TenantModel(
      id: '00000000-0000-0000-0000-000000000006',
      name: 'Metro Flex Gym',
      slug: 'metro-flex-fsd',
      contactEmail: 'metroflexfsd@gmail.com',
      contactPhone: '+92 301 5566778',
      address: 'Main Boulevard, Kohinoor City',
      city: 'Faisalabad',
      country: 'Pakistan',
      subscriptionStatus: 'suspended',
      subscriptionTier: 'starter',
      maxMembers: 250,
      aiTrainerEnabled: false,
      posEnabled: false,
      esp32GateEnabled: false,
      storeEnabled: true,
      isActive: false,
      primaryColor: const Color(0xFFEF4444),
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      activeMembersCount: 45,
    ),
  ];

  Future<List<TenantModel>> fetchAllTenants() async {
    if (_client == null) return fallbackTenants;
    try {
      final res = await _client
          .from('tenants')
          .select()
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((row) => TenantModel.fromJson(row as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) return fallbackTenants;
      return list;
    } catch (_) {
      return fallbackTenants;
    }
  }

  Future<TenantModel> registerNewTenant(TenantModel newTenant) async {
    if (_client != null) {
      try {
        final payload = newTenant.toSupabaseInsert();
        final res = await _client
            .from('tenants')
            .insert(payload)
            .select()
            .single();

        return TenantModel.fromJson(res);
      } catch (e) {
        // Fallback for offline/local simulation
        return newTenant;
      }
    }
    return newTenant;
  }

  Future<bool> updateTenantStatus({
    required String tenantId,
    required String newStatus,
    required bool isActive,
  }) async {
    if (_client == null) return true;
    try {
      await _client.from('tenants').update({
        'subscription_status': newStatus,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', tenantId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleTenantFeature({
    required String tenantId,
    required String featureKey,
    required bool enabled,
    required Map<String, dynamic> existingFeatures,
  }) async {
    if (_client == null) return true;
    try {
      final updated = Map<String, dynamic>.from(existingFeatures);
      updated[featureKey] = enabled;

      await _client.from('tenants').update({
        'features': updated,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', tenantId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
