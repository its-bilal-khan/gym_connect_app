import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/dashboard/data/owner_dashboard_repository.dart';
import 'package:gym_connect_app/features/dashboard/domain/models/owner_dashboard_metrics.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/desktop/desktop_owner_portal_view.dart';

void main() {
  group('OwnerDashboardMetrics Domain Model Tests', () {
    test('Calculates formatting and rates accurately', () {
      const metrics = OwnerDashboardMetrics(
        monthlyRevenue: 185000.0,
        previousMonthRevenue: 162000.0,
        paidInvoicesCount: 28,
        activeMembers: 1482,
        totalMembers: 1540,
        checkInsToday: 348,
        peakHours: 'Peak: 6:00 PM - 8:30 PM',
        shiftCashDrawer: 54000.0,
        shiftStatus: 'open',
        activeStaffName: 'Hamza',
        shiftSalesCount: 14,
      );

      expect(metrics.formattedMonthlyRevenue, equals('PKR 185,000'));
      expect(metrics.formattedActiveMembers, equals('1,482'));
      expect(metrics.formattedCheckInsToday, equals('348'));
      expect(metrics.formattedShiftCashDrawer, equals('PKR 54,000'));
      expect(metrics.retentionSubtitle, contains('96.2% retention rate'));
      expect(metrics.revenueGrowthSubtitle, contains('+14.2% vs previous month'));
      expect(metrics.checkInsSubtitle, equals('Peak: 6:00 PM - 8:30 PM'));
      expect(metrics.shiftCashSubtitle, contains('14 sales in shift • Staff: Hamza'));
    });

    test('Handles zero and closed states cleanly without errors', () {
      final empty = OwnerDashboardMetrics.empty();

      expect(empty.formattedMonthlyRevenue, equals('PKR 0'));
      expect(empty.formattedActiveMembers, equals('0'));
      expect(empty.formattedCheckInsToday, equals('0'));
      expect(empty.formattedShiftCashDrawer, equals('PKR 0'));
      expect(empty.retentionSubtitle, equals('0 registered members'));
      expect(empty.revenueGrowthSubtitle, equals('No transactions recorded yet'));
      expect(empty.checkInsSubtitle, equals('No check-ins logged today'));
      expect(empty.shiftCashSubtitle, contains('POS drawer closed'));
    });
  });

  group('DesktopOwnerPortalView Real Metrics Widget Tests', () {
    testWidgets('Renders real metrics from ownerDashboardMetricsProvider', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testMetrics = OwnerDashboardMetrics(
        monthlyRevenue: 245000.0,
        previousMonthRevenue: 210000.0,
        paidInvoicesCount: 35,
        activeMembers: 180,
        totalMembers: 200,
        checkInsToday: 64,
        peakHours: 'Peak: 5:30 PM - 8:00 PM',
        shiftCashDrawer: 32000.0,
        shiftStatus: 'open',
        activeStaffName: 'Reception Desk',
        shiftSalesCount: 8,
      );

      const profile = UserProfile(
        id: 'owner-test-1',
        role: UserRole.owner,
        fullName: 'Bilal Khan',
        email: 'owner@titanfitness.com',
        tenantId: '00000000-0000-0000-0000-000000000001',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ownerDashboardMetricsProvider('00000000-0000-0000-0000-000000000001').overrideWith(
              (ref) => testMetrics,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DesktopOwnerPortalView(profile: profile),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that live values from testMetrics are rendered
      expect(find.text('MONTHLY REVENUE'), findsOneWidget);
      expect(find.text('PKR 245,000'), findsOneWidget);
      expect(find.text('ACTIVE MEMBERS'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);
      expect(find.text('CHECK-INS TODAY'), findsOneWidget);
      expect(find.text('64'), findsOneWidget);
      expect(find.text('SHIFT CASH DRAWER'), findsOneWidget);
      expect(find.text('PKR 32,000'), findsOneWidget);

      // Verify subtitles
      expect(find.text('+16.7% vs previous month'), findsOneWidget);
      expect(find.text('90.0% retention rate (180/200)'), findsOneWidget);
      expect(find.text('Peak: 5:30 PM - 8:00 PM'), findsOneWidget);
      expect(find.text('8 sales in shift • Staff: Reception Desk'), findsOneWidget);
    });
  });
}
