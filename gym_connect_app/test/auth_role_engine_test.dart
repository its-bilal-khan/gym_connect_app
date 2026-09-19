import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/navigation/presentation/adaptive_role_shell.dart';
import 'package:gym_connect_app/features/navigation/presentation/role_navigation_config.dart';
import 'package:gym_connect_app/features/navigation/presentation/widgets/adaptive_sidebar.dart';
import 'package:gym_connect_app/features/navigation/presentation/widgets/glass_bottom_nav.dart';
import 'package:gym_connect_app/features/navigation/presentation/widgets/shell_app_bar.dart';
import 'package:gym_connect_app/features/shells/member/presentation/member_shell_view.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/owner_shell_view.dart';
import 'package:gym_connect_app/features/shells/staff/presentation/staff_shell_view.dart';

void main() {
  group('UserRole Engine Tests', () {
    test('UserRole.fromString correctly parses all role variations', () {
      expect(UserRole.fromString('super_admin'), UserRole.owner);
      expect(UserRole.fromString('gym_owner'), UserRole.owner);
      expect(UserRole.fromString('owner'), UserRole.owner);
      expect(UserRole.fromString('staff'), UserRole.staff);
      expect(UserRole.fromString('trainer'), UserRole.staff);
      expect(UserRole.fromString('member'), UserRole.member);
      expect(UserRole.fromString('public_user'), UserRole.publicUser);
      expect(UserRole.fromString(null), UserRole.member);
      expect(UserRole.fromString('unknown_role'), UserRole.member);
    });

    test('UserRole canSwitchRoles grants privileges to Owner and Staff only', () {
      expect(UserRole.owner.canSwitchRoles, isTrue);
      expect(UserRole.staff.canSwitchRoles, isTrue);
      expect(UserRole.member.canSwitchRoles, isFalse);
      expect(UserRole.publicUser.canSwitchRoles, isFalse);
    });
  });

  group('UserProfile Model Tests', () {
    test('UserProfile.fromJson parses tenant branding and custom colors', () {
      final json = {
        'id': 'usr-123',
        'tenant_id': 'ten-456',
        'role': 'gym_owner',
        'full_name': 'Sarah Connor',
        'email': 'sarah@gymconnect.io',
        'tenants': {
          'name': 'Powerhouse Gym',
          'branding': {
            'primary_color': '#00FFAA',
          },
        },
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, 'usr-123');
      expect(profile.role, UserRole.owner);
      expect(profile.fullName, 'Sarah Connor');
      expect(profile.tenantName, 'Powerhouse Gym');
      expect(profile.tenantPrimaryColor, const Color(0xFF00FFAA));
    });
  });

  group('RoleNavigationConfig Tests', () {
    test('RoleNavigationConfig returns correct tab destinations per role', () {
      final ownerTabs = RoleNavigationConfig.getTabsForRole(UserRole.owner);
      expect(ownerTabs.length, 4);
      expect(ownerTabs.map((t) => t.id), containsAll(['overview', 'pos_staff', 'live_ops', 'settings']));

      final staffTabs = RoleNavigationConfig.getTabsForRole(UserRole.staff);
      expect(staffTabs.length, 4);
      expect(staffTabs.map((t) => t.id), containsAll(['reception', 'members', 'pos', 'shift']));

      final memberTabs = RoleNavigationConfig.getTabsForRole(UserRole.member);
      expect(memberTabs.length, 4);
      expect(memberTabs.map((t) => t.id), containsAll(['daily_action', 'workout_hub', 'pass', 'store_profile']));
    });
  });

  group('AdaptiveRoleShell Widget Tests', () {
    const testProfile = UserProfile(
      id: 'test-user-1',
      role: UserRole.owner,
      fullName: 'Iron Mike',
      email: 'mike@titangym.com',
      tenantName: 'TITAN GYM',
    );

    testWidgets('renders mobile layout with GlassBottomNav and ShellAppBar for Owner', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdaptiveRoleShell(
              profile: testProfile,
              activeRole: UserRole.owner,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ShellAppBar), findsOneWidget);
      expect(find.byType(GlassBottomNav), findsOneWidget);
      expect(find.byType(AdaptiveSidebar), findsNothing);
      expect(find.byType(OwnerShellView), findsOneWidget);
      expect(find.text('TITAN GYM'), findsOneWidget);
      expect(find.text('OWNER / BOSS'), findsOneWidget);
    });

    testWidgets('renders desktop layout with AdaptiveSidebar when width >= 800', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdaptiveRoleShell(
              profile: testProfile,
              activeRole: UserRole.staff,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AdaptiveSidebar), findsOneWidget);
      expect(find.byType(GlassBottomNav), findsNothing);
      expect(find.byType(StaffShellView), findsOneWidget);
    });

    testWidgets('renders MemberShellView when active role is Member', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdaptiveRoleShell(
              profile: testProfile,
              activeRole: UserRole.member,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MemberShellView), findsOneWidget);
      expect(find.text("START TODAY'S WORKOUT"), findsOneWidget);
    });

    testWidgets('tapping role badge in ShellAppBar opens RoleSwitcherSheet and switches view to Staff', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdaptiveRoleShell(
              profile: testProfile,
              activeRole: UserRole.owner,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(OwnerShellView), findsOneWidget);
      expect(find.byType(StaffShellView), findsNothing);

      // Tap the role switcher badge in ShellAppBar
      await tester.tap(find.text('OWNER / BOSS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // bottom sheet animation

      // Verify RoleSwitcherSheet is displayed
      expect(find.text('ROLE-SWITCHING ENGINE'), findsOneWidget);
      expect(find.text('Reception & POS Desk'), findsOneWidget);

      // Tap 'Reception & POS Desk'
      await tester.tap(find.text('Reception & POS Desk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // bottom sheet pop

      // Verify AdaptiveRoleShell seamlessly rebuilt to StaffShellView!
      expect(find.byType(StaffShellView), findsOneWidget);
      expect(find.byType(OwnerShellView), findsNothing);
      expect(find.text('STAFF DESK'), findsOneWidget);
    });
  });
}
