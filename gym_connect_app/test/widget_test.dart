import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/auth/presentation/auth_gate.dart';
import 'package:gym_connect_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gym_connect_app/features/dashboard/presentation/widgets/dashboard_sidebar.dart';
import 'package:gym_connect_app/main.dart';

void main() {
  testWidgets('GymConnectApp loads LoginScreen via AuthGate when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymConnectApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('GYMCONNECT'), findsWidgets);
    expect(find.text('ENTERPRISE ACCESS & CONTROL'), findsOneWidget);
    expect(find.text('AUTHENTICATE'), findsOneWidget);
  });

  testWidgets('AuthGate defaults to LoginScreen when no active session exists', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthGate(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('AUTHENTICATE'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation errors when submitted empty', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymConnectApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('AUTHENTICATE'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('DashboardScreen renders desktop layout (width > 800) with sidebar and row cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify Sidebar exists
    expect(find.byType(DashboardSidebar), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);

    // Verify Header & 3 Metric Cards
    expect(find.text('TITAN FITNESS CLUB'), findsOneWidget);
    expect(find.text('TOTAL MEMBERS'), findsOneWidget);
    expect(find.text("TODAY'S REVENUE"), findsOneWidget);
    expect(find.text('ACTIVE SUBSCRIPTIONS'), findsOneWidget);
  });

  testWidgets('DashboardScreen renders mobile layout (width <= 800) with BottomNavigationBar and vertical cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify Sidebar is removed, BottomNavigationBar is present
    expect(find.byType(DashboardSidebar), findsNothing);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify Header & 3 Metric Cards stacked vertically
    expect(find.text('TITAN FITNESS CLUB'), findsOneWidget);
    expect(find.text('TOTAL MEMBERS'), findsOneWidget);
    expect(find.text("TODAY'S REVENUE"), findsOneWidget);
    expect(find.text('ACTIVE SUBSCRIPTIONS'), findsOneWidget);
  });
}
