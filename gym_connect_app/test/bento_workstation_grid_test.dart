import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/dashboard/data/owner_dashboard_repository.dart';
import 'package:gym_connect_app/features/dashboard/domain/models/owner_dashboard_metrics.dart';
import 'package:gym_connect_app/features/members/data/members_repository.dart';
import 'package:gym_connect_app/features/members/domain/models/gym_member.dart';
import 'package:gym_connect_app/features/members/presentation/providers/members_provider.dart';
import 'package:gym_connect_app/features/payments/domain/models/payment_submission.dart';
import 'package:gym_connect_app/features/payments/presentation/providers/payments_providers.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/desktop/desktop_owner_portal_view.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/widgets/bento_previews/bento_workstation_card.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/widgets/bento_previews/mini_calculators_hub_preview.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/widgets/bento_previews/mini_member_table_preview.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/widgets/bento_previews/mini_payment_approvals_preview.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/widgets/bento_previews/mini_pro_shop_inventory_preview.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/widgets/bento_previews/mini_store_orders_preview.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/widgets/bento_previews/mini_workout_protocol_preview.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';
import 'package:gym_connect_app/features/store/presentation/providers/store_providers.dart';

class FakeMembersNotifier extends MembersNotifier {
  final List<GymMember> initialMembers;
  FakeMembersNotifier(this.initialMembers);

  @override
  MembersState build() {
    return MembersState(isLoading: false, allMembers: initialMembers);
  }
}

void main() {
  const testTenantId = '00000000-0000-0000-0000-000000000001';

  final testMembers = [
    GymMember(
      id: 'mem-101',
      tenantId: testTenantId,
      memberCode: 'GC-M-1011',
      fullName: 'Hamza Tariq',
      phone: '+923001234567',
      email: 'hamza@titan.com',
      planName: 'Annual VIP Pass',
      joinDate: DateTime(2026, 1, 1),
      expiryDate: DateTime(2027, 1, 1),
      duesAmount: 0.0,
      duesStatus: MemberDuesStatus.paid,
      tempPassword: 'Pass1',
    ),
    GymMember(
      id: 'mem-102',
      tenantId: testTenantId,
      memberCode: 'GC-M-1012',
      fullName: 'Bilal Khan',
      phone: '+923219876543',
      email: 'bilal@titan.com',
      planName: 'Monthly Pro',
      joinDate: DateTime(2026, 2, 1),
      expiryDate: DateTime(2026, 3, 1),
      duesAmount: 5000.0,
      duesStatus: MemberDuesStatus.unpaid,
      tempPassword: 'Pass2',
    ),
  ];

  final testOrders = [
    StoreOrder(
      id: 'ord-101',
      tenantId: testTenantId,
      userId: 'usr-1',
      customerName: 'Zain Malik',
      pickupCode: 'PK-9912',
      fulfillmentType: 'pickup',
      orderStatus: 'pending',
      totalAmount: 18500.0,
      createdAt: DateTime.now(),
      items: [
        const StoreOrderItem(
          id: 'item-1',
          productId: 'prod-1',
          productName: 'Optimum Nutrition Gold Whey',
          quantity: 1,
          unitPrice: 18500.0,
          totalPrice: 18500.0,
        ),
      ],
    ),
  ];

  const testProducts = [
    StoreProduct(
      id: 'prod-1',
      tenantId: testTenantId,
      name: 'Optimum Nutrition Gold Whey',
      category: 'Supplements',
      price: 18500.0,
      stockQuantity: 24,
      imageUrl: '',
      providerBrand: 'Optimum Nutrition',
    ),
    StoreProduct(
      id: 'prod-2',
      tenantId: testTenantId,
      name: 'Cellucor C4 Pre-Workout',
      category: 'Supplements',
      price: 6800.0,
      stockQuantity: 15,
      imageUrl: '',
      providerBrand: 'Cellucor',
    ),
  ];

  final testPayments = [
    PaymentSubmission(
      id: 'pay-1',
      tenantId: testTenantId,
      userId: 'usr-1',
      amount: 4500.0,
      status: 'pending',
      paymentMethod: 'meezan_bank',
      createdAt: DateTime.now(),
      userFullName: 'Hamza Ali',
    ),
  ];

  group('Bento-Box Workstation Grid & Live Preview Architecture Tests', () {
    testWidgets('BentoWorkstationCard scales preview and blocks inner pointer events for outer navigation', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BentoWorkstationCard(
                width: 500,
                title: 'MEMBERS DIRECTORY & EXCEL INGESTION [DESKTOP]',
                subtitle: 'Batch upload and roster management',
                icon: Icons.groups_rounded,
                badge: 'MEMBERS',
                moduleTag: 'TITAN // MEMBERS HUB',
                isHighlight: true,
                onTap: () => tapped = true,
                previewWidget: const Text('INNER_LIVE_UI'),
              ),
            ),
          ),
        ),
      );

      // Verify Oswald title, badge and live indicator are rendered
      expect(find.text('MEMBERS DIRECTORY & EXCEL INGESTION [DESKTOP]'), findsOneWidget);
      expect(find.text('MEMBERS'), findsOneWidget);
      expect(find.text('LIVE WORKSTATION'), findsOneWidget);
      expect(find.text('TITAN // MEMBERS HUB'), findsOneWidget);

      // Verify Transform.scale, ClipRRect, Align, and IgnorePointer exist
      expect(find.byType(Transform), findsWidgets);
      expect(find.byType(ClipRRect), findsWidgets);
      expect(find.byType(Align), findsWidgets);
      expect(find.byType(IgnorePointer), findsWidgets);

      // Tap on the scaled preview area: IgnorePointer blocks child hit test, allowing parent InkWell to receive it
      await tester.tap(find.text('INNER_LIVE_UI'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Parent card InkWell must receive the tap cleanly
      expect(tapped, isTrue);
    });

    testWidgets('MiniMemberTablePreview renders live member roster table', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membersNotifierProvider.overrideWith(() => FakeMembersNotifier(testMembers)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 380,
                height: 196,
                child: const MiniMemberTablePreview(tenantId: testTenantId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EXCEL IMPORT'), findsOneWidget);
      expect(find.textContaining('ROSTER: 2 (2 ACTIVE)'), findsOneWidget);
      expect(find.text('TABLE'), findsOneWidget);
      expect(find.text('Hamza Tariq'), findsOneWidget);
      expect(find.text('GC-M-1011'), findsOneWidget);
    });

    testWidgets('MiniWorkoutProtocolPreview renders body type split & routine telemetry', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 380,
                height: 196,
                child: const MiniWorkoutProtocolPreview(tenantId: testTenantId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ECTOMORPH'), findsOneWidget);
      expect(find.text('MESOMORPH'), findsOneWidget);
      expect(find.text('ENDOMORPH'), findsOneWidget);
      expect(find.text('ADD EXERCISE'), findsOneWidget);
      expect(find.textContaining('DAY 1: CHEST'), findsOneWidget);
      expect(find.text('RPE 8.5'), findsOneWidget);
    });

    testWidgets('MiniStoreOrdersPreview renders live orders queue', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantStoreOrdersProvider(testTenantId).overrideWith((ref) => Future.value(testOrders)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 380,
                height: 196,
                child: const MiniStoreOrdersPreview(tenantId: testTenantId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PICKUP: PK-9912'), findsOneWidget);
      expect(find.textContaining('Zain Malik'), findsOneWidget);
      expect(find.text('PKR 18500'), findsOneWidget);
      expect(find.text('DISPATCH ORDER'), findsOneWidget);
    });

    testWidgets('MiniProShopInventoryPreview renders live supplement stock telemetry', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProductsProvider.overrideWith((ref) => Future.value(testProducts)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 380,
                height: 196,
                child: const MiniProShopInventoryPreview(tenantId: testTenantId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CATALOG: 2 PRODUCTS'), findsOneWidget);
      expect(find.text('ADD PRODUCT'), findsOneWidget);
      expect(find.text('Optimum Nutrition Gold Whey'), findsOneWidget);
      expect(find.text('24 IN STOCK'), findsOneWidget);
      expect(find.text('PKR 18500'), findsOneWidget);
    });

    testWidgets('MiniPaymentApprovalsPreview renders pending member transfer slips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingPaymentsProvider(testTenantId).overrideWith((ref) => Future.value(testPayments)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 380,
                height: 196,
                child: const MiniPaymentApprovalsPreview(tenantId: testTenantId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HAMZA ALI'), findsOneWidget);
      expect(find.text('TRANSFER: PKR 4500'), findsOneWidget);
      expect(find.text('REJECT'), findsOneWidget);
      expect(find.textContaining('APPROVE & ACTIVATE'), findsOneWidget);
    });

    testWidgets('MiniCalculatorsHubPreview renders clinical BMR/TDEE & 1RM telemetry', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 196,
              child: MiniCalculatorsHubPreview(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CALORIES'), findsOneWidget);
      expect(find.text('2,450 kcal'), findsOneWidget);
      expect(find.text('MACROS'), findsOneWidget);
      expect(find.text('40P:40C:20F'), findsOneWidget);
      expect(find.text('1RM BENCH MAX'), findsOneWidget);
      expect(find.text('105 KG ESTIMATE'), findsOneWidget);
      expect(find.text('22.4 OPTIMAL'), findsOneWidget);
    });

    testWidgets('DesktopOwnerPortalView integrates all 6 Bento-Box Workstation cards with live telemetry', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testMetrics = OwnerDashboardMetrics(
        monthlyRevenue: 18500.0,
        previousMonthRevenue: 0.0,
        paidInvoicesCount: 1,
        activeMembers: 1,
        totalMembers: 1,
        checkInsToday: 0,
        peakHours: 'Peak: 6:00 PM - 8:30 PM',
        shiftCashDrawer: 0.0,
        shiftStatus: 'closed',
        activeStaffName: null,
        shiftSalesCount: 0,
      );

      const profile = UserProfile(
        id: 'owner-test-1',
        role: UserRole.owner,
        fullName: 'Bilal Khan',
        email: 'owner@titanfitness.com',
        tenantId: testTenantId,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ownerDashboardMetricsProvider(testTenantId).overrideWith((ref) => testMetrics),
            membersNotifierProvider.overrideWith(() => FakeMembersNotifier(testMembers)),
            tenantStoreOrdersProvider(testTenantId).overrideWith((ref) => Future.value(testOrders)),
            storeProductsProvider.overrideWith((ref) => Future.value(testProducts)),
            pendingPaymentsProvider(testTenantId).overrideWith((ref) => Future.value(testPayments)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DesktopOwnerPortalView(profile: profile),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 6 Bento Workstations exist
      expect(find.text('MEMBERS DIRECTORY & EXCEL INGESTION [DESKTOP]'), findsOneWidget);
      expect(find.text('WORKOUT PROTOCOL STUDIO [DESKTOP]'), findsOneWidget);
      expect(find.text('STORE ORDERS & DISPATCH'), findsOneWidget);
      expect(find.text('PRO SHOP & INVENTORY MANAGER'), findsOneWidget);
      expect(find.text('PENDING PROOF-OF-PAYMENTS'), findsOneWidget);
      expect(find.text('CLINICAL TOOLS & CALCULATORS'), findsOneWidget);

      // Verify Bento Live telemetry indicators are rendered
      expect(find.text('LIVE WORKSTATION'), findsNWidgets(6));
    });
  });
}
