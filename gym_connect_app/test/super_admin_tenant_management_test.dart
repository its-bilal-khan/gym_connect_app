import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/super_admin/data/tenant_repository.dart';
import 'package:gym_connect_app/features/super_admin/domain/models/tenant_model.dart';
import 'package:gym_connect_app/features/super_admin/presentation/desktop/desktop_super_admin_workstation_view.dart';
import 'package:gym_connect_app/features/super_admin/presentation/providers/tenant_providers.dart';

void main() {
  const testAdminProfile = UserProfile(
    id: 'admin-001',
    email: 'superadmin@gymconnect.io',
    fullName: 'Platform Super Admin',
    role: UserRole.superAdmin,
  );

  group('TenantModel & Repository Tests', () {
    test('TenantModel calculates monthly SaaS pricing by tier', () {
      final starter = TenantModel(
        id: '1',
        name: 'Starter Gym',
        slug: 'starter-gym',
        subscriptionTier: 'starter',
        createdAt: DateTime.now(),
      );
      final pro = TenantModel(
        id: '2',
        name: 'Pro Gym',
        slug: 'pro-gym',
        subscriptionTier: 'pro',
        createdAt: DateTime.now(),
      );
      final enterprise = TenantModel(
        id: '3',
        name: 'VIP Gym',
        slug: 'vip-gym',
        subscriptionTier: 'enterprise',
        createdAt: DateTime.now(),
      );

      expect(starter.monthlySaaSPKR, 15000.0);
      expect(pro.monthlySaaSPKR, 35000.0);
      expect(enterprise.monthlySaaSPKR, 75000.0);
    });

    test('TenantRepository fetchAllTenants returns authentic fallback records', () async {
      const repo = TenantRepository(null);
      final list = await repo.fetchAllTenants();

      expect(list.isNotEmpty, isTrue);
      expect(list.any((t) => t.name == 'Titan Fitness Club'), isTrue);
      expect(list.any((t) => t.name == 'Iron Peak Elite Gym'), isTrue);
    });
  });

  group('SuperAdminTenantsNotifier State Tests', () {
    test('Notifier toggles feature flag dynamically', () async {
      final container = ProviderContainer(
        overrides: [
          tenantRepositoryProvider.overrideWithValue(const TenantRepository(null)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(superAdminTenantsNotifierProvider.notifier);
      await container.read(superAdminTenantsNotifierProvider.future);

      final initialList = container.read(superAdminTenantsNotifierProvider).value!;
      final titan = initialList.firstWhere((t) => t.slug == 'titan-fitness');

      final initialAi = titan.aiTrainerEnabled;
      await notifier.toggleFeature(
        tenantId: titan.id,
        featureKey: 'ai_trainer_enabled',
        enabled: !initialAi,
      );

      final updatedList = container.read(superAdminTenantsNotifierProvider).value!;
      final updatedTitan = updatedList.firstWhere((t) => t.slug == 'titan-fitness');
      expect(updatedTitan.aiTrainerEnabled, !initialAi);
    });

    test('GlobalSaaSMetrics computes correct sums across tenants', () async {
      final container = ProviderContainer(
        overrides: [
          tenantRepositoryProvider.overrideWithValue(const TenantRepository(null)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(superAdminTenantsNotifierProvider.future);
      final metrics = container.read(globalSaaSMetricsProvider);

      expect(metrics.totalTenants, greaterThan(0));
      expect(metrics.activeTenants, greaterThan(0));
      expect(metrics.totalMonthlyMRRPKR, greaterThan(0));
    });
  });

  group('DesktopSuperAdminWorkstationView Widget Tests', () {
    testWidgets('renders full Super Admin workstation on desktop width (>= 800px)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DesktopSuperAdminWorkstationView(
                profile: testAdminProfile,
                initialTabIndex: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SUPER ADMIN WORKSTATION'), findsOneWidget);
      expect(find.text('TENANTS DIRECTORY & OPERATIONS'), findsOneWidget);
      expect(find.text('ONBOARD NEW GYM TENANT'), findsOneWidget);
      expect(find.text('SAAS REVENUE & TIERS'), findsOneWidget);
      expect(find.text('AUDIT & GOD MODE'), findsOneWidget);
      expect(find.text('TOTAL ONBOARDED GYMS'), findsOneWidget);
      expect(find.text('Titan Fitness Club'), findsWidgets);
    });

    testWidgets('switches to Onboard New Gym Tenant form when tab clicked', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DesktopSuperAdminWorkstationView(
                profile: testAdminProfile,
                initialTabIndex: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ONBOARD NEW GYM TENANT'));
      await tester.pumpAndSettle();

      expect(find.text('1. BASIC GYM CREDENTIALS'), findsOneWidget);
      expect(find.text('2. SAAS SUBSCRIPTION TIER & SIZING'), findsOneWidget);
      expect(find.text('3. HARDWARE & FEATURE PERMISSIONS'), findsOneWidget);
      expect(find.text('DEPLOY & REGISTER GYM TENANT'), findsOneWidget);
    });
  });
}
