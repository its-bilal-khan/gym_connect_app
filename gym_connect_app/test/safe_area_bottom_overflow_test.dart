import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/navigation/domain/nav_destination_item.dart';
import 'package:gym_connect_app/features/navigation/presentation/widgets/glass_bottom_nav.dart';
import 'package:gym_connect_app/features/navigation/presentation/widgets/role_switcher_sheet.dart';
import 'package:gym_connect_app/features/shells/member/presentation/member_shell_view.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/owner_shell_view.dart';
import 'package:gym_connect_app/features/shells/public/presentation/public_shell_view.dart';
import 'package:gym_connect_app/features/shells/staff/presentation/staff_shell_view.dart';

void main() {
  const dummyProfile = UserProfile(
    id: 'test-user-1',
    email: 'member@titan.com',
    fullName: 'Test User',
    role: UserRole.member,
    tenantId: 'tenant-1',
    tenantName: 'Titan Fitness Club',
    tenantPrimaryColor: Color(0xFFCCFF00),
  );

  final dummyTabs = [
    const NavDestinationItem(id: 'today', label: 'Today', icon: Icons.today_rounded),
    const NavDestinationItem(id: 'workouts', label: 'Workouts', icon: Icons.fitness_center_rounded),
  ];

  group('SafeArea & Dynamic Bottom Padding Tests', () {
    testWidgets('GlassBottomNav dynamically adds MediaQuery bottom padding to margin', (tester) async {
      const simulatedBottomInset = 34.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(bottom: simulatedBottomInset),
            ),
            child: Scaffold(
              bottomNavigationBar: GlassBottomNav(
                items: dummyTabs,
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      );

      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.margin == const EdgeInsets.fromLTRB(16, 0, 16, 16 + simulatedBottomInset),
      );

      expect(containerFinder, findsOneWidget);
    });

    testWidgets('RoleSwitcherSheet dynamically adds MediaQuery bottom padding', (tester) async {
      const simulatedBottomInset = 34.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(bottom: simulatedBottomInset),
            ),
            child: Scaffold(
              body: RoleSwitcherSheet(
                activeRole: UserRole.owner,
                onSelectRole: (_) {},
              ),
            ),
          ),
        ),
      );

      final scrollFinder = find.byWidgetPredicate(
        (widget) => widget is SingleChildScrollView && widget.padding == const EdgeInsets.fromLTRB(20, 16, 20, 24 + simulatedBottomInset),
      );

      expect(scrollFinder, findsOneWidget);
    });

    testWidgets('MemberShellView, OwnerShellView, StaffShellView render safely without overflow with 34px gesture bar', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                padding: EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: const Scaffold(
                body: MemberShellView(profile: dummyProfile, selectedIndex: 0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MemberShellView), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: const Scaffold(
              body: OwnerShellView(profile: dummyProfile, selectedIndex: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OwnerShellView), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: const Scaffold(
              body: StaffShellView(profile: dummyProfile, selectedIndex: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StaffShellView), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: const Scaffold(
              body: PublicShellView(profile: dummyProfile, selectedIndex: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PublicShellView), findsOneWidget);
    });
  });
}
