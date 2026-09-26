import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gym_connect_app/core/services/secure_storage_service.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:gym_connect_app/features/auth/presentation/providers/auth_state.dart';
import 'package:gym_connect_app/features/navigation/presentation/adaptive_role_shell.dart';
import 'package:gym_connect_app/features/super_admin/presentation/desktop/desktop_super_admin_workstation_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('View & Session Persistence Across Reload Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('AuthNotifier restores active role on reload when session is null', () async {
      FlutterSecureStorage.setMockInitialValues({
        'gymconnect_active_role': 'super_admin',
        'gymconnect_active_sub_tab_super_admin': '2',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger session check
      await container.read(authNotifierProvider.notifier).checkSession();

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      final auth = state as AuthAuthenticated;
      expect(auth.activeRole, UserRole.superAdmin);
      expect(auth.profile.role, UserRole.superAdmin);
    });

    test('AuthNotifier restores switched owner role on reload for member account', () async {
      FlutterSecureStorage.setMockInitialValues({
        'gymconnect_active_role': 'owner',
        'gymconnect_persisted_profile': '{"id":"test-user","role":"member","full_name":"Test User"}',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).checkSession();

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      final auth = state as AuthAuthenticated;
      expect(auth.activeRole, UserRole.owner);
    });

    test('AuthNotifier signOut clears active role and returns to unauthenticated', () async {
      FlutterSecureStorage.setMockInitialValues({
        'gymconnect_active_role': 'owner',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.checkSession();
      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());

      await notifier.signOut();
      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());

      final storage = container.read(secureStorageProvider);
      final role = await storage.getActiveRole();
      expect(role, isNull);
    });

    testWidgets('AdaptiveRoleShell restores saved navigation index on reload', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterSecureStorage.setMockInitialValues({
        'gymconnect_active_nav_index': '2',
        'gymconnect_active_role': 'super_admin',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).checkSession();
      final authState = container.read(authNotifierProvider) as AuthAuthenticated;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AdaptiveRoleShell(
              profile: authState.profile,
              activeRole: authState.activeRole,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigation index 2 for superAdmin is Exercise Studio
      expect(find.text('EXERCISE & VIDEO STUDIO'), findsOneWidget);
    });

    testWidgets('DesktopSuperAdminWorkstationView restores saved subtab on reload', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterSecureStorage.setMockInitialValues({
        'gymconnect_active_role': 'super_admin',
        'gymconnect_active_sub_tab_super_admin': '2',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).checkSession();
      final authState = container.read(authNotifierProvider) as AuthAuthenticated;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: DesktopSuperAdminWorkstationView(
                profile: authState.profile,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should automatically render ExerciseVideoStudioTab
      expect(find.text('TOTAL EXERCISES'), findsOneWidget);
      expect(find.text('CDN STREAM ENGINE'), findsOneWidget);
      expect(find.text('EXERCISE & VIDEO STUDIO'), findsOneWidget);
    });
  });
}
