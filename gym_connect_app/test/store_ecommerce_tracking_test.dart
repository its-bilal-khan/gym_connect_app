import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';
import 'package:gym_connect_app/features/store/presentation/widgets/add_product_dialog.dart';
import 'package:gym_connect_app/features/store/presentation/widgets/order_status_stepper.dart';
import 'package:gym_connect_app/features/store/presentation/widgets/store_fulfillment_card.dart';
import 'package:gym_connect_app/features/store/presentation/widgets/store_product_card.dart';
import 'package:gym_connect_app/features/store/presentation/widgets/store_product_grid_card.dart';

void main() {
  const testProduct = StoreProduct(
    id: 'prod-101',
    name: 'Optimum Nutrition Gold Standard Whey',
    category: 'Supplements',
    price: 18500.0,
    stockQuantity: 25,
    imageUrl: 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f',
    providerBrand: 'Optimum Nutrition',
    servings: '60 Servings • 2.27 KG',
  );

  group('Store E-Commerce Enhancements - Domain Models', () {
    test('StoreProduct parses json and provides effective image URL', () {
      final json = {
        'id': 'prod-102',
        'name': 'Cellucor C4 Pre-Workout',
        'category': 'Supplements',
        'selling_price': 6800.0,
        'stock_quantity': 15,
        'image_url': 'https://images.unsplash.com/photo-1546483875-ad9014c88eba',
      };

      final p = StoreProduct.fromJson(json);
      expect(p.id, 'prod-102');
      expect(p.price, 6800.0);
      expect(p.effectiveImageUrl, contains('unsplash.com'));
    });

    test('StoreProduct fallback image works when image_url is empty', () {
      final p = StoreProduct(
        id: 'prod-fallback',
        name: 'Fresh Cold Shake',
        category: 'Juice Bar',
        price: 450,
        stockQuantity: 100,
        imageUrl: '',
      );
      expect(p.effectiveImageUrl.isNotEmpty, true);
      expect(p.effectiveImageUrl, contains('unsplash.com'));
    });

    test('StoreOrder parses fulfillment and scheduling attributes', () {
      final json = {
        'id': 'ord-1',
        'tenant_id': 'ten-1',
        'user_id': 'usr-1',
        'customer_name': 'Zain Malik',
        'pickup_code': 'PK-9912',
        'fulfillment_type': 'delivery',
        'delivery_address': 'House 14, Street 9, DHA Phase 6, Lahore',
        'delivery_phone': '03001234567',
        'order_status': 'ready_for_pickup',
        'estimated_ready_date': '2026-09-25',
        'estimated_ready_time': '5:00 PM - 7:00 PM',
        'total_amount': 18500.0,
        'is_paid': true,
        'created_at': '2026-09-24T12:00:00Z',
      };

      final order = StoreOrder.fromJson(json);
      expect(order.id, 'ord-1');
      expect(order.customerName, 'Zain Malik');
      expect(order.isDelivery, true);
      expect(order.isPickup, false);
      expect(order.estimatedReadyDate, '2026-09-25');
      expect(order.estimatedReadyTime, contains('5:00 PM'));
      expect(order.orderStatus, 'ready_for_pickup');
    });
  });

  group('Store E-Commerce Enhancements - Widgets', () {
    testWidgets('StoreProductGridCard renders product attributes and triggers onAddToCart', (tester) async {
      bool added = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: StoreProductGridCard(
                product: testProduct,
                inCart: 0,
                onTap: () {},
                onAddToCart: () => added = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Optimum Nutrition Gold Standard Whey'), findsOneWidget);
      expect(find.text('PKR 18500'), findsOneWidget);
      expect(find.text('SUPPLEMENTS'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(added, true);
    });

    testWidgets('StoreProductCard renders list row with brand, name, and price', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreProductCard(
              product: testProduct,
              inCart: 1,
              onTap: () {},
              onAddToCart: () {},
            ),
          ),
        ),
      );

      expect(find.text('Optimum Nutrition Gold Standard Whey'), findsOneWidget);
      expect(find.text('Optimum Nutrition'), findsOneWidget);
      expect(find.text('PKR 18500'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('OrderStatusStepper renders 4 steps with ready date & time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderStatusStepper(
              status: 'ready_for_pickup',
              isDelivery: false,
              readyDate: '2026-09-25',
              readyTime: '4:00 PM - 6:00 PM',
            ),
          ),
        ),
      );

      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Payment Verified'), findsOneWidget);
      expect(find.text('Ready for Pickup'), findsOneWidget);
      expect(find.text('2026-09-25 • 4:00 PM - 6:00 PM'), findsOneWidget);
      expect(find.text('Collected'), findsOneWidget);
    });

    testWidgets('StoreFulfillmentCard switches between Pickup and Delivery', (tester) async {
      bool isDelivery = false;
      final nameCtrl = TextEditingController(text: 'Ali Khan');
      final addressCtrl = TextEditingController();
      final phoneCtrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => StoreFulfillmentCard(
                isDelivery: isDelivery,
                onToggleFulfillment: (val) => setState(() => isDelivery = val),
                nameController: nameCtrl,
                addressController: addressCtrl,
                phoneController: phoneCtrl,
              ),
            ),
          ),
        ),
      );

      expect(find.text('IN-GYM PICKUP'), findsOneWidget);
      expect(find.text('HOME DELIVERY'), findsOneWidget);
      expect(find.text('Collect at gym front desk counter. A pickup code & barcode will be generated upon checkout.'), findsOneWidget);

      // Switch to delivery
      await tester.tap(find.text('HOME DELIVERY'));
      await tester.pump();

      expect(find.text('Recipient Full Name'), findsOneWidget);
      expect(find.text('Delivery Address (Street, House/Flat, City)'), findsOneWidget);
      expect(find.text('Contact Phone Number for Courier'), findsOneWidget);
    });

    test('StoreProduct parses tenant_id properly', () {
      final json = {
        'id': 'prod-tenant-1',
        'tenant_id': 'tenant-uuid-1234',
        'name': 'Titan Shaker Bottle',
        'category': 'Gear',
        'selling_price': 1200.0,
        'stock_quantity': 50,
      };
      final p = StoreProduct.fromJson(json);
      expect(p.tenantId, 'tenant-uuid-1234');
      expect(p.name, 'Titan Shaker Bottle');
      expect(p.price, 1200.0);
    });

    testWidgets('AddProductDialog renders form fields and buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddProductDialog(),
          ),
        ),
      );

      expect(find.text('ADD NEW PRODUCT'), findsOneWidget);
      expect(find.text('Product Name *'), findsOneWidget);
      expect(find.text('Price (PKR) *'), findsOneWidget);
      expect(find.text('Stock Qty *'), findsOneWidget);
      expect(find.text('SAVE PRODUCT'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
    });
  });
}
