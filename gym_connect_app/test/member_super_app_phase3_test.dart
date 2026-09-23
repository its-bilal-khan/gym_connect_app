import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/community/data/community_repository.dart';
import 'package:gym_connect_app/features/membership/data/membership_repository.dart';
import 'package:gym_connect_app/features/reviews/data/reviews_repository.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/gate_pass_card.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/gym_review_dialog.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/in_gym_store_sheet.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/member_workout_hub_tab.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/pay_dues_sheet.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/transformation_spotlight_card.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';
import 'package:gym_connect_app/features/workout/presentation/providers/workout_notifier.dart';

void main() {
  const testProducts = [
    StoreProduct(id: 'p-1', name: 'Whey Protein Shake (Choco)', category: 'Juice Bar', price: 450, stockQuantity: 50),
    StoreProduct(id: 'p-2', name: 'Pre-Workout Nitro Can (300ml)', category: 'Drinks', price: 350, stockQuantity: 30),
  ];

  const testPost = TransformationPost(
    id: 't-1',
    title: "Ahmad's 90-Day Shred Story",
    story: "GymConnect ke 90-day smart calendar ne discipline banaye rakha.",
    memberName: "Ahmad Raza",
    weightLoss: "-14.5 KG",
    bodyFat: "28% ➔ 15%",
    program: "SHRED D-90",
    daysActive: 78,
    likesCount: 143,
  );

  const testInvoice = PendingInvoiceInfo(
    id: 'inv-1',
    invoiceNumber: 'INV-9821',
    dueAmount: 5000.0,
    status: 'unpaid',
    title: 'Monthly VIP Membership',
  );

  group('Phase 3 Member Super App - TransformationSpotlightCard', () {
    testWidgets('renders daily coach tip and community story from repository', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transformationSpotlightProvider.overrideWith((ref) => Future.value(testPost)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TransformationSpotlightCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AI COACH TIP'), findsOneWidget);
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text("Ahmad Raza's 90-Day Transformation"), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      // Tap motivation button to increment like
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();
      expect(find.text('144'), findsOneWidget);

      // Tap "READ STORY & PROTOCOL →" button
      await tester.tap(find.text('READ STORY & PROTOCOL →'));
      await tester.pumpAndSettle();
      expect(find.text("Ahmad's 90-Day Shred Story"), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();
      expect(find.text("Ahmad's 90-Day Shred Story"), findsNothing);
    });
  });

  group('Phase 3 Member Super App - PayDuesSheet', () {
    testWidgets('renders payment options and completes payment flow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingInvoiceProvider.overrideWith((ref) => Future.value(testInvoice)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => PayDuesSheet.show(context),
                  child: const Text('OPEN PAY DUES'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN PAY DUES'));
      await tester.pumpAndSettle();

      expect(find.text('PAY DUES & RENEWAL'), findsOneWidget);
      expect(find.text('PKR 5000'), findsOneWidget);
      expect(find.text('JazzCash Mobile Account'), findsOneWidget);
      expect(find.text('EasyPaisa Wallet'), findsOneWidget);
      expect(find.text('Debit / Credit Card (Visa/Mastercard)'), findsOneWidget);

      // Tap EasyPaisa Wallet to launch external gateway handoff
      await tester.tap(find.text('EasyPaisa Wallet'));
      await tester.pumpAndSettle();

      // Verify external EasyPaisa handoff screen opened
      expect(find.text('EASYPAISA OFFICIAL GATEWAY'), findsOneWidget);
      expect(find.text('LAUNCHING EASYPAISA APP...'), findsOneWidget);

      // User returns from EasyPaisa and taps I Have Completed Payment
      await tester.tap(find.text('I HAVE COMPLETED PAYMENT IN EASYPAISA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('PAYMENT CONFIRMED!'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);

      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(find.text('PAYMENT CONFIRMED!'), findsNothing);
    });
  });

  group('Phase 3 Member Super App - InGymStoreSheet', () {
    testWidgets('adds items to cart and generates pickup code', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProductsProvider.overrideWith((ref) => Future.value(testProducts)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => InGymStoreSheet.show(context),
                  child: const Text('OPEN STORE'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN STORE'));
      await tester.pumpAndSettle();

      expect(find.text('IN-GYM STORE & SHAKES'), findsOneWidget);
      expect(find.text('Whey Protein Shake (Choco)'), findsOneWidget);
      expect(find.text('Pre-Workout Nitro Can (300ml)'), findsOneWidget);

      // Add one Whey shake (price 450)
      final addIcons = find.byIcon(Icons.add_circle_rounded);
      expect(addIcons, findsWidgets);
      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();

      expect(find.text('ORDER (PKR 450)'), findsOneWidget);

      // Add another
      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();
      expect(find.text('ORDER (PKR 900)'), findsOneWidget);

      // Place order
      await tester.tap(find.text('ORDER (PKR 900)'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('PICKUP CODE'), findsOneWidget);
      expect(find.textContaining('PK-'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);

      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();
      expect(find.text('PICKUP CODE'), findsNothing);
    });
  });

  group('Phase 3 Member Super App - GymReviewDialog', () {
    testWidgets('allows 5-star selection, tag toggling, and review submission', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reviewsRepositoryProvider.overrideWithValue(const ReviewsRepository(null)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => GymReviewDialog.show(context),
                  child: const Text('OPEN REVIEW'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN REVIEW'));
      await tester.pumpAndSettle();

      expect(find.text('RATE YOUR GYM'), findsOneWidget);
      expect(find.text('VERIFIED ACTIVE MEMBER'), findsOneWidget);
      expect(find.text('Cleanliness'), findsOneWidget);
      expect(find.text('Equipments'), findsOneWidget);

      // Toggle tag
      await tester.tap(find.text('Trainers'));
      await tester.pumpAndSettle();

      // Enter review text
      await tester.enterText(find.byType(TextField), 'State of the art gym equipment!');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('SUBMIT VERIFIED REVIEW'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('REVIEW SUBMITTED!'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);

      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();
      expect(find.text('REVIEW SUBMITTED!'), findsNothing);
    });
  });

  group('Phase 3 Member Super App - GatePassCard & MemberWorkoutHubTab', () {
    testWidgets('GatePassCard renders dynamic pass and triggers gate unlock', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GatePassCard(),
            ),
          ),
        ),
      );

      expect(find.text('DEVICE ID LOCKED'), findsOneWidget);
      expect(find.textContaining('PASS TOKEN: GC-'), findsOneWidget);
      expect(find.text('TEST UNLOCK'), findsOneWidget);

      await tester.tap(find.text('TEST UNLOCK'));
      await tester.pump();
      expect(find.text('UNLOCKING...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      expect(find.textContaining('ESP32 Gate Signal Sent'), findsOneWidget);
    });

    testWidgets('MemberWorkoutHubTab displays exercise details and start action', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(workoutNotifierProvider.notifier).loadTodayRoutine(day: 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: MemberWorkoutHubTab(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DAY 1 OF 90'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
      expect(find.text('GROUPED EXERCISES (4)'), findsOneWidget);
    });
  });
}
