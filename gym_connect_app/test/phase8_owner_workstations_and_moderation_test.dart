import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/gamification/data/moderation_repository.dart';
import 'package:gym_connect_app/features/gamification/domain/models/models.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/moderation_queue_provider.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/owner_reward_config_provider.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/automated_fulfillment_ledger_table.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/flagged_fraud_grid_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/flagged_fraud_list_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/flagged_fraud_moderation_dialog.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/flagged_moderation_mini_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/owner_reward_configurator_dialog.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/reward_configurator_mini_view.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/widgets/owner_gamification_workstation_card.dart';

class FakeModerationRepository extends ModerationRepository {
  List<FlaggedQueueItem> mockItems;
  TenantRewardConfig mockConfig;
  List<MonthlyPodiumArchive> mockLedger;

  FakeModerationRepository({
    this.mockItems = const [],
    this.mockConfig = const TenantRewardConfig(),
    this.mockLedger = const [],
  }) : super(null);

  @override
  Future<List<FlaggedQueueItem>> fetchPendingFlaggedItems({
    required String tenantId,
    int limit = 50,
  }) async =>
      mockItems;

  @override
  Future<Map<String, dynamic>> moderateFlaggedItem({
    required String queueId,
    required String status,
    required String reviewerId,
    String? notes,
  }) async {
    mockItems = mockItems.where((i) => i.id != queueId).toList();
    return {'success': true};
  }

  @override
  Future<TenantRewardConfig> fetchTenantRewardConfig(String tenantId) async => mockConfig;

  @override
  Future<Map<String, dynamic>> updateTenantRewardConfig({
    required String tenantId,
    required TenantRewardConfig config,
  }) async {
    mockConfig = config;
    return {'success': true};
  }

  @override
  Future<List<MonthlyPodiumArchive>> fetchFulfillmentLedger({
    required String tenantId,
  }) async =>
      mockLedger;
}

void main() {
  group('Phase 8: Domain Models & Deserialization Tests', () {
    test('FlaggedQueueItem parses Supabase join payload correctly', () {
      final json = {
        'id': 'q-101',
        'tenant_id': 'tenant-alpha',
        'user_id': 'user-beta',
        'profiles': {'full_name': 'Tariq Mehmood'},
        'proof_type': 'diet_photo',
        'proof_url': 'https://storage.supabase.co/proofs/diet101.jpg',
        'points_awarded': 50,
        'status': 'pending_review',
        'flagged_reason': 'Suspicious repetitive photo similarity score 98%',
      };

      final item = FlaggedQueueItem.fromJson(json);
      expect(item.id, 'q-101');
      expect(item.memberName, 'Tariq Mehmood');
      expect(item.pointsAwarded, 50);
      expect(item.isPending, isTrue);
      expect(item.isApproved, isFalse);
      expect(item.isDeducted, isFalse);
      expect(item.flaggedReason, contains('Suspicious'));
    });

    test('TenantRewardConfig defaults and copyWith operate accurately', () {
      const config = TenantRewardConfig();
      expect(config.rank1Title, '1-Month Free Access');
      expect(config.minMonthlyWorkoutsQualification, 18);

      final updated = config.copyWith(
        rank1Title: 'Gold VIP Pass + 1 Tub Whey Protein',
        minMonthlyWorkoutsQualification: 20,
      );
      expect(updated.rank1Title, 'Gold VIP Pass + 1 Tub Whey Protein');
      expect(updated.minMonthlyWorkoutsQualification, 20);
      expect(updated.rank2Title, config.rank2Title);
    });

    test('MonthlyPodiumArchive parses fulfillment metadata properly', () {
      final json = {
        'id': 'arch-001',
        'tenant_id': 'tenant-alpha',
        'month_year': 'October 2026',
        'podium_rank': 1,
        'user_id': 'user-gamma',
        'points_scored': 1420,
        'streak_at_finish': 22,
        'reward_title': '1-Month Free Gym Membership',
        'reward_type': 'free_month',
        'reward_value': 30,
        'is_fulfilled': true,
        'fulfilled_at': '2026-10-01T00:00:00.000Z',
        'invoice_id_generated': 'inv-zero-01',
        'profiles': {'full_name': 'Bilal Khan'},
      };

      final archive = MonthlyPodiumArchive.fromJson(json);
      expect(archive.podiumRank, 1);
      expect(archive.memberName, 'Bilal Khan');
      expect(archive.isFulfilled, isTrue);
      expect(archive.invoiceIdGenerated, 'inv-zero-01');
    });
  });

  group('Phase 8: State Management & Notifier Tests', () {
    test('ModerationQueueNotifier loads items, toggles view mode, and executes clawback', () async {
      final fakeRepo = FakeModerationRepository(
        mockItems: [
          const FlaggedQueueItem(
            id: 'q-01',
            tenantId: 'tenant-alpha',
            userId: 'user-01',
            memberName: 'Hamza Ali',
            proofType: 'manual_steps',
            proofUrl: '',
            pointsAwarded: 15,
            flaggedReason: 'Manual step entry exceeds 35,000 threshold',
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          moderationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(moderationQueueProvider.notifier);
      await notifier.loadItems('tenant-alpha');

      expect(container.read(moderationQueueProvider).items.length, 1);
      expect(container.read(moderationQueueProvider).isListView, isTrue);

      // Rule 5 Dual-View toggle
      notifier.setViewMode(ModerationViewMode.grid);
      expect(container.read(moderationQueueProvider).isListView, isFalse);

      // Execute atomic clawback
      final clawbackSuccess = await notifier.clawbackPoints(
        queueId: 'q-01',
        reviewerId: 'owner-admin',
        auditNotes: 'Manual step spoof detected',
      );
      expect(clawbackSuccess, isTrue);
      expect(container.read(moderationQueueProvider).items, isEmpty);
    });

    test('OwnerRewardConfigNotifier loads and updates tenant settings', () async {
      final fakeRepo = FakeModerationRepository(
        mockConfig: const TenantRewardConfig(
          rank1Title: 'Custom Gym Bag + 1 Month Free',
          minMonthlyWorkoutsQualification: 15,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          moderationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(ownerRewardConfigProvider.notifier);
      await notifier.loadConfigAndLedger('tenant-alpha');

      expect(container.read(ownerRewardConfigProvider).config.rank1Title, 'Custom Gym Bag + 1 Month Free');
      expect(container.read(ownerRewardConfigProvider).config.minMonthlyWorkoutsQualification, 15);

      final saveSuccess = await notifier.saveConfig(
        tenantId: 'tenant-alpha',
        newConfig: const TenantRewardConfig(
          rank1Title: 'Annual VIP Pass',
          minMonthlyWorkoutsQualification: 22,
        ),
      );
      expect(saveSuccess, isTrue);
      expect(container.read(ownerRewardConfigProvider).config.rank1Title, 'Annual VIP Pass');
    });
  });

  group('Phase 8: UI Widget & Workstations Tests', () {
    testWidgets('FlaggedFraudListView renders item with Approve and Clawback buttons', (tester) async {
      final items = [
        const FlaggedQueueItem(
          id: 'q-01',
          tenantId: 'tenant-alpha',
          userId: 'user-01',
          memberName: 'Zainab Bibi',
          proofType: 'diet_photo',
          proofUrl: '',
          pointsAwarded: 50,
          flaggedReason: 'Stock photo match',
        ),
      ];

      String? approvedId;
      String? clawbackedId;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: FlaggedFraudListView(
              items: items,
              reviewerId: 'owner-01',
              onApprove: (id) => approvedId = id,
              onClawback: (id) => clawbackedId = id,
            ),
          ),
        ),
      );

      expect(find.text('Zainab Bibi'), findsOneWidget);
      expect(find.text('APPROVE'), findsOneWidget);
      expect(find.text('CLAWBACK'), findsOneWidget);

      await tester.tap(find.text('APPROVE'));
      expect(approvedId, 'q-01');

      await tester.tap(find.text('CLAWBACK'));
      expect(clawbackedId, 'q-01');
    });

    testWidgets('FlaggedFraudGridView renders 2-column card view (Strict Rule 5)', (tester) async {
      final items = [
        const FlaggedQueueItem(
          id: 'q-01',
          tenantId: 'tenant-alpha',
          userId: 'user-01',
          memberName: 'Zainab Bibi',
          proofType: 'diet_photo',
          proofUrl: '',
          pointsAwarded: 50,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: FlaggedFraudGridView(
              items: items,
              reviewerId: 'owner-01',
              onApprove: (_) {},
              onClawback: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Zainab Bibi'), findsOneWidget);
    });

    testWidgets('AutomatedFulfillmentLedgerTable renders past auto-extended winners', (tester) async {
      final ledger = <MonthlyPodiumArchive>[
        const MonthlyPodiumArchive(
          id: 'arch-1',
          tenantId: 'tenant-alpha',
          userId: 'user-1',
          monthYear: 'September 2026',
          podiumRank: 1,
          pointsScored: 1200,
          streakAtFinish: 20,
          rewardTitle: '1-Month Free Gym Membership',
          rewardType: 'free_month',
          rewardValue: 30,
          isFulfilled: true,
          memberName: 'Asad Umar',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
          ),
          home: Scaffold(
            body: AutomatedFulfillmentLedgerTable(ledger: ledger),
          ),
        ),
      );

      expect(find.text('Asad Umar'), findsOneWidget);
      expect(find.text('✓ Auto-Fulfilled'), findsOneWidget);
      expect(find.text('Rs. 0 Invoice • +30d Sub'), findsOneWidget);
    });

    testWidgets('RewardConfiguratorMiniView and FlaggedModerationMiniView render correctly (Rule 7)', (tester) async {
      final fakeRepo = FakeModerationRepository(
        mockConfig: const TenantRewardConfig(
          rank1Title: 'Gold VIP Champion Trophy',
          minMonthlyWorkoutsQualification: 18,
        ),
        mockItems: [
          const FlaggedQueueItem(
            id: 'q-99',
            tenantId: 'tenant-alpha',
            userId: 'user-99',
            memberName: 'Test Member',
            proofType: 'diet_photo',
            proofUrl: '',
            pointsAwarded: 50,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moderationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5FF)),
            ),
            home: const Scaffold(
              body: Column(
                children: [
                  RewardConfiguratorMiniView(),
                  FlaggedModerationMiniView(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RewardConfiguratorMiniView), findsOneWidget);
      expect(find.byType(FlaggedModerationMiniView), findsOneWidget);
      expect(find.text('REWARD CONFIGURATOR'), findsOneWidget);
      expect(find.text('FRAUD MODERATION QUEUE'), findsOneWidget);
    });

    testWidgets('OwnerGamificationWorkstationCard renders buttons and triggers dialogs', (tester) async {
      final fakeRepo = FakeModerationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moderationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: Color(0xFFCCFF00)),
            ),
            home: const Scaffold(
              body: OwnerGamificationWorkstationCard(
                tenantId: 'tenant-123',
                reviewerId: 'owner-123',
              ),
            ),
          ),
        ),
      );

      expect(find.text('GAMIFICATION & REWARDS WORKSTATION'), findsOneWidget);
      expect(find.text('CONFIG REWARDS'), findsOneWidget);
      expect(find.text('AUDIT QUEUE'), findsOneWidget);

      // Tap CONFIG REWARDS -> opens OwnerRewardConfiguratorDialog
      await tester.tap(find.text('CONFIG REWARDS'));
      await tester.pumpAndSettle();
      expect(find.byType(OwnerRewardConfiguratorDialog), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Tap AUDIT QUEUE -> opens FlaggedFraudModerationDialog
      await tester.tap(find.text('AUDIT QUEUE'));
      await tester.pumpAndSettle();
      expect(find.byType(FlaggedFraudModerationDialog), findsOneWidget);
    });
  });
}
