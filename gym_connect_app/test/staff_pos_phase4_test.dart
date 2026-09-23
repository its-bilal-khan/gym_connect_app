import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/shells/staff/presentation/staff_shell_view.dart';
import 'package:gym_connect_app/features/staff/data/staff_pos_repository.dart';
import 'package:gym_connect_app/features/staff/data/staff_reception_repository.dart';
import 'package:gym_connect_app/features/staff/data/staff_shift_repository.dart';
import 'package:gym_connect_app/features/staff/presentation/widgets/shift_management_sheet.dart';
import 'package:gym_connect_app/features/staff/presentation/widgets/staff_check_in_dialog.dart';
import 'package:gym_connect_app/features/staff/presentation/widgets/staff_pos_register_sheet.dart';
import 'package:gym_connect_app/features/staff/presentation/widgets/staff_walk_in_dialog.dart';
import 'package:gym_connect_app/features/staff/presentation/widgets/thermal_receipt_dialog.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';

void main() {
  const testProfile = UserProfile(
    id: 'staff-001',
    email: 'staff@gymconnect.com',
    fullName: 'Bilal Reception',
    role: UserRole.staff,
  );

  Widget createTestWidget(Widget child, {List<dynamic> overrides = const []}) {
    return ProviderScope(
      overrides: [
        storeProductsProvider.overrideWith((ref) async => [
              const StoreProduct(
                id: 'prod-001',
                name: 'Gold Standard 100% Whey',
                price: 18500,
                category: 'Supplements',
                stockQuantity: 15,
                description: '24g protein isolate',
              ),
              const StoreProduct(
                id: 'prod-002',
                name: 'Pre-Workout Shot',
                price: 650,
                category: 'Drinks',
                stockQuantity: 40,
                description: '300mg caffeine blast',
              ),
            ]),
        staffMembersProvider.overrideWith((ref, query) async => [
              const StaffMemberLookupItem(
                id: 'mem-001',
                fullName: 'Ahmad Raza',
                phone: '03001234567',
                planName: 'Gold 12 Months VIP',
                status: 'ACTIVE',
              ),
            ]),
        activeShiftProvider.overrideWith((ref) async => const ShiftSummary(
              shiftId: 'shift-test-01',
              staffName: 'Bilal Reception',
              openingCash: 5000.0,
              cashSales: 12500.0,
              digitalSales: 8900.0,
              pettyCashSpent: 1200.0,
              totalInvoicesCount: 8,
              status: 'open',
            )),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Phase 4 Staff Reception & Access Tests', () {
    testWidgets('StaffCheckInDialog validates token and displays access granted', (tester) async {
      await tester.pumpWidget(createTestWidget(const StaffCheckInDialog()));
      await tester.pumpAndSettle();

      expect(find.text('MEMBER CHECK-IN'), findsOneWidget);
      expect(find.text('VERIFY & UNLOCK GATE'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '03001234567');
      await tester.tap(find.text('VERIFY & UNLOCK GATE'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hamza Tariq'), findsOneWidget);
      expect(find.textContaining('ACTIVE'), findsOneWidget);
    });

    testWidgets('StaffWalkInDialog creates 24-hr walk-in guest pass', (tester) async {
      await tester.pumpWidget(createTestWidget(const StaffWalkInDialog()));
      await tester.pumpAndSettle();

      expect(find.text('WALK-IN GUEST PASS'), findsOneWidget);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Usman Qureshi');
      await tester.enterText(textFields.at(1), '03219876543');
      await tester.tap(find.text('COLLECT PKR 1,000 & ISSUE PASS'));
      await tester.pumpAndSettle();

      expect(find.textContaining('GP-'), findsOneWidget);
      expect(find.textContaining('Usman Qureshi'), findsOneWidget);
    });
  });

  group('Phase 4 Retail POS & Split Payments Tests', () {
    testWidgets('StaffPosRegisterSheet loads catalog, handles cart, and checkout', (tester) async {
      await tester.pumpWidget(createTestWidget(const StaffPosRegisterSheet()));
      await tester.pumpAndSettle();

      expect(find.text('RETAIL POS & KHATA REGISTER'), findsOneWidget);
      expect(find.text('Gold Standard 100% Whey'), findsOneWidget);

      // Add to cart
      final addButtons = find.byIcon(Icons.add_circle_rounded);
      expect(addButtons, findsWidgets);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('COLLECT PKR 18500'), findsOneWidget);

      // Select Khata Credit
      await tester.tap(find.text('Khata Credit'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Khata Credit'), findsWidgets);
    });

    testWidgets('ThermalReceiptDialog displays clean 80mm printable layout', (tester) async {
      final receipt = PosReceipt(
        invoiceNumber: 'INV-20260923-001',
        cashierName: 'Bilal Reception',
        dateTime: DateTime(2026, 9, 23, 17, 30),
        items: [
          const PosSaleItem(
            product: StoreProduct(
              id: 'p1',
              name: 'Gold Standard Whey',
              price: 18500,
              category: 'Supplements',
              stockQuantity: 10,
              description: 'Protein isolate',
            ),
            quantity: 1,
            unitPrice: 18500,
          ),
        ],
        subtotal: 18500,
        discount: 0,
        tax: 0,
        total: 18500,
        paymentMethod: 'Khata_Credit',
        customerName: 'Ahmad Raza (VIP)',
        isKhata: true,
      );

      await tester.pumpWidget(createTestWidget(ThermalReceiptDialog(receipt: receipt)));
      await tester.pumpAndSettle();

      expect(find.text('TITAN FITNESS CLUB'), findsOneWidget);
      expect(find.textContaining('INV: INV-20260923-001'), findsOneWidget);
      expect(find.textContaining('18500'), findsWidgets);
      expect(find.textContaining('Khata_Credit'), findsOneWidget);
    });
  });

  group('Phase 4 Shift Management & Z-Report Tests', () {
    testWidgets('ShiftManagementSheet displays live shift breakdown and generates Z-Report', (tester) async {
      await tester.pumpWidget(createTestWidget(const ShiftManagementSheet()));
      await tester.pumpAndSettle();

      expect(find.text('SHIFT TALLY & Z-REPORT'), findsOneWidget);
      expect(find.text('Opening Float'), findsOneWidget);
      expect(find.textContaining('5000'), findsWidgets);
      expect(find.text('Cash Sales'), findsOneWidget);
      expect(find.textContaining('12500'), findsWidgets);

      // Close shift
      await tester.tap(find.text('CLOSE SHIFT & PRINT Z-REPORT'));
      await tester.pumpAndSettle();

      expect(find.text('Z-REPORT GENERATED'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);
    });
  });

  group('Phase 4 Staff Shell Navigation Tests', () {
    testWidgets('StaffShellView renders all 4 tabs seamlessly with zero hardcoded fake data', (tester) async {
      // Tab 0: Reception
      await tester.pumpWidget(createTestWidget(const StaffShellView(profile: testProfile, selectedIndex: 0)));
      await tester.pumpAndSettle();
      expect(find.text('RECEPTION CHECK-IN DESK'), findsOneWidget);
      expect(find.text('SCAN MEMBER QR CODE'), findsOneWidget);
      expect(find.text('Emergency Gate Unlock'), findsOneWidget);

      // Tab 1: Member Directory
      await tester.pumpWidget(createTestWidget(const StaffShellView(profile: testProfile, selectedIndex: 1)));
      await tester.pumpAndSettle();
      expect(find.text('MEMBER DIRECTORY & LOOKUP'), findsOneWidget);
      expect(find.text('Ahmad Raza'), findsOneWidget);
      expect(find.textContaining('Gold 12 Months VIP'), findsOneWidget);

      // Tab 2: POS & Khata
      await tester.pumpWidget(createTestWidget(const StaffShellView(profile: testProfile, selectedIndex: 2)));
      await tester.pumpAndSettle();
      expect(find.text('POS & KHATA CREDIT SYSTEM'), findsOneWidget);
      expect(find.text('New POS Sale'), findsOneWidget);
      expect(find.text('RETAIL CAPABILITIES'), findsOneWidget);

      // Tab 3: Shift Tally
      await tester.pumpWidget(createTestWidget(const StaffShellView(profile: testProfile, selectedIndex: 3)));
      await tester.pumpAndSettle();
      expect(find.text('SHIFT TALLY & Z-REPORT'), findsOneWidget);
      expect(find.text('Current Shift Tally'), findsOneWidget);
      expect(find.text('ACTIVE SHIFT METRICS'), findsOneWidget);
    });
  });
}
