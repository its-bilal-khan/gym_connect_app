import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/payments/domain/models/payment_submission.dart';
import 'package:gym_connect_app/features/payments/domain/models/tenant_payment_settings.dart';
import 'package:gym_connect_app/features/payments/presentation/providers/payments_providers.dart';
import 'package:gym_connect_app/features/payments/presentation/screens/gym_owner_payment_approvals_screen.dart';
import 'package:gym_connect_app/features/payments/presentation/widgets/manual_bank_details_card.dart';
import 'package:gym_connect_app/features/payments/presentation/widgets/manual_payment_pending_dialog.dart';
import 'package:gym_connect_app/features/payments/presentation/widgets/pending_payment_card.dart';
import 'package:gym_connect_app/features/payments/presentation/screens/manual_checkout_screen.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';
import 'package:gym_connect_app/features/store/presentation/widgets/owner_order_details_dialog.dart';

void main() {
  group('Hybrid Payment Architecture - Domain Models', () {
    test('TenantPaymentSettings parses json and respects toggles correctly', () {
      final json = {
        'id': 'tenant-uuid-1',
        'is_payfast_enabled': true,
        'is_manual_payment_enabled': true,
        'manual_easypaisa_number': '03001234567',
        'manual_bank_details': 'Meezan Bank | PK36MEZN0001234567890123',
      };

      final settings = TenantPaymentSettings.fromJson(json);
      expect(settings.tenantId, 'tenant-uuid-1');
      expect(settings.isPayfastEnabled, true);
      expect(settings.isManualPaymentEnabled, true);
      expect(settings.hasAnyPaymentMethod, true);
      expect(settings.manualEasypaisaNumber, '03001234567');
      expect(settings.manualBankDetails, contains('Meezan Bank'));
    });

    test('PaymentSubmission parses json and identifies pending status', () {
      final json = {
        'id': 'pay-123',
        'tenant_id': 'tenant-uuid-1',
        'user_id': 'user-uuid-99',
        'amount': 4500.0,
        'receipt_image_url': 'https://supabase.co/storage/v1/object/public/payment_receipts/receipt.jpg',
        'status': 'pending',
        'created_at': '2026-09-24T00:00:00Z',
        'profiles': {
          'full_name': 'Hamza Ali',
          'email': 'hamza@gmail.com',
          'phone': '03129876543',
        },
      };

      final payment = PaymentSubmission.fromJson(json);
      expect(payment.id, 'pay-123');
      expect(payment.userId, 'user-uuid-99');
      expect(payment.amount, 4500.0);
      expect(payment.receiptImageUrl, contains('payment_receipts'));
      expect(payment.isPending, true);
      expect(payment.userFullName, 'Hamza Ali');
      expect(payment.userEmail, 'hamza@gmail.com');
      expect(payment.userPhone, '03129876543');
    });
  });

  group('Hybrid Payment Architecture - Widgets', () {
    testWidgets('ManualBankDetailsCard renders EasyPaisa and Bank credentials', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ManualBankDetailsCard(
              easypaisaNumber: '03451122334',
              bankDetails: 'Habib Bank Ltd (HBL) - IBAN: PK00HABB123',
              amount: 5500,
            ),
          ),
        ),
      );

      expect(find.text('DIRECT BANK & WALLET TRANSFER'), findsOneWidget);
      expect(find.text('Transfer PKR 5500 using details below'), findsOneWidget);
      expect(find.text('03451122334'), findsOneWidget);
      expect(find.text('Habib Bank Ltd (HBL) - IBAN: PK00HABB123'), findsOneWidget);
    });

    testWidgets('ManualPaymentPendingDialog displays approval pending message and dismisses', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualPaymentPendingDialog(
              amount: 5000,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('PAYMENT SUBMITTED'), findsOneWidget);
      expect(find.text('Your payment is pending approval from the gym.'), findsOneWidget);
      expect(find.text('GOT IT, BACK TO HOME'), findsOneWidget);

      await tester.tap(find.text('GOT IT, BACK TO HOME'));
      await tester.pump();
      expect(dismissed, true);
    });

    testWidgets('PendingPaymentCard displays member proof and triggers approval callback', (tester) async {
      bool approved = false;
      bool rejected = false;

      final testPayment = PaymentSubmission(
        id: 'p-1',
        tenantId: 't-1',
        userId: 'u-1',
        amount: 6000,
        receiptImageUrl: 'https://example.com/receipt.jpg',
        status: 'pending',
        createdAt: DateTime(2026, 9, 24, 10, 30),
        userFullName: 'Bilal Khan',
        userEmail: 'bilal@gymconnect.pk',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingPaymentCard(
              payment: testPayment,
              onApprove: () => approved = true,
              onReject: () => rejected = true,
            ),
          ),
        ),
      );

      expect(find.text('BILAL KHAN'), findsOneWidget);
      expect(find.text('bilal@gymconnect.pk'), findsOneWidget);
      expect(find.text('PKR 6000'), findsOneWidget);
      expect(find.text('APPROVE'), findsOneWidget);
      expect(find.text('REJECT'), findsOneWidget);

      await tester.tap(find.text('APPROVE'));
      await tester.pump();
      expect(approved, true);

      await tester.tap(find.text('REJECT'));
      await tester.pump();
      expect(rejected, true);
    });

    testWidgets('GymOwnerPaymentApprovalsScreen renders empty state when no pending payments', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingPaymentsProvider('test-tenant').overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: GymOwnerPaymentApprovalsScreen(tenantId: 'test-tenant'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('PAYMENT PROOFS & APPROVALS'), findsOneWidget);
      expect(find.text('ALL CAUGHT UP!'), findsOneWidget);
      expect(find.text('No pending manual payments waiting for approval.'), findsOneWidget);
    });

    testWidgets('OwnerOrderDetailsDialog renders customer, order items, and receipt preview actions', (tester) async {
      final testOrder = StoreOrder(
        id: 'ord-99887766',
        tenantId: 'tenant-1',
        userId: 'user-1',
        customerName: 'Ahmad Raza',
        customerPhone: '03001234567',
        pickupCode: 'PK-4521',
        fulfillmentType: 'pickup',
        orderStatus: 'pending',
        paymentMethod: 'manual_proof',
        paymentReceiptUrl: 'https://example.com/receipt.jpg',
        totalAmount: 9500,
        isPaid: true,
        createdAt: DateTime(2026, 9, 24, 12, 0),
        items: const [
          StoreOrderItem(
            id: 'item-1',
            productId: 'prod-1',
            productName: 'Gold Standard Whey 5lbs',
            quantity: 1,
            unitPrice: 9500,
            totalPrice: 9500,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OwnerOrderDetailsDialog(
              order: testOrder,
              onSchedule: (s, d, t) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('ORDER #ORD-9988'), findsOneWidget);
      expect(find.text('PENDING VERIFICATION'), findsOneWidget);
      expect(find.text('Ahmad Raza'), findsOneWidget);
      expect(find.text('Gym Pickup Code: PK-4521'), findsOneWidget);
      expect(find.text('Gold Standard Whey 5lbs'), findsOneWidget);
      expect(find.text('TOTAL: PKR 9500'), findsOneWidget);
      expect(find.text('PAYMENT PROOF & RECEIPT'), findsOneWidget);
      expect(find.text('TAP TO EXPAND & ZOOM RECEIPT'), findsOneWidget);
      expect(find.text('SCHEDULE READY TIME'), findsOneWidget);
      expect(find.text('MARK COMPLETED'), findsOneWidget);
    });

    testWidgets('ManualCheckoutScreen renders copyable credentials and receipt upload picker without disabled blocker', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantPaymentSettingsProvider('test-tenant').overrideWith((ref) => Future.value(
                  const TenantPaymentSettings(
                    tenantId: 'test-tenant',
                    isPayfastEnabled: false,
                    isManualPaymentEnabled: true,
                    manualEasypaisaNumber: '0300-1234567 (Titan Reception)',
                    manualBankDetails: 'Meezan Bank - IBAN: PK64MEZN000123',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: ManualCheckoutScreen(
              tenantId: 'test-tenant',
              amount: 5000,
              invoiceNumber: 'INV-1001',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('MANUAL PROOF CHECKOUT'), findsOneWidget);
      expect(find.text('DIRECT BANK & WALLET TRANSFER'), findsOneWidget);
      expect(find.text('0300-1234567 (Titan Reception)'), findsOneWidget);
      expect(find.text('Meezan Bank - IBAN: PK64MEZN000123'), findsOneWidget);
      expect(find.text('PROOF OF PAYMENT'), findsOneWidget);
      expect(find.text('SUBMIT SCREENSHOT FOR APPROVAL'), findsOneWidget);
      expect(find.text('Manual transfer is currently disabled for this gym.'), findsNothing);
    });
  });
}
