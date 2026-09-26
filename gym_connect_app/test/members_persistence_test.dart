import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gym_connect_app/core/services/secure_storage_service.dart';
import 'package:gym_connect_app/features/members/data/members_repository.dart';
import 'package:gym_connect_app/features/members/domain/models/gym_member.dart';
import 'package:gym_connect_app/features/members/presentation/providers/members_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testTenantId = '00000000-0000-0000-0000-000000000001';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Members Backend Persistence & Reload Verification', () {
    test('Imported members permanently persist across simulated page reload (F5)', () async {
      final storage = const SecureStorageService();
      final repo1 = MembersRepository(null, storage);

      final importedMembers = [
        GymMember(
          id: 'imported-1',
          tenantId: testTenantId,
          memberCode: 'GC-M-1011',
          fullName: 'Hamza Tariq',
          phone: '+923001234567',
          email: 'hamza@titangym.com',
          planName: 'Annual VIP Access',
          joinDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2027, 1, 1),
          duesAmount: 5000.0,
          duesStatus: MemberDuesStatus.unpaid,
          tempPassword: 'Gym@Secure1011',
          assignedProtocol: 'Mesomorph: Hypertrophy & Power',
        ),
        GymMember(
          id: 'imported-2',
          tenantId: testTenantId,
          memberCode: 'GC-M-1012',
          fullName: 'Bilal Khan',
          phone: '+923219876543',
          email: 'bilal@titangym.com',
          planName: 'Monthly Pro Pass',
          joinDate: DateTime(2026, 2, 1),
          expiryDate: DateTime(2026, 3, 1),
          duesAmount: 0.0,
          duesStatus: MemberDuesStatus.paid,
          tempPassword: 'Gym@Secure1012',
          assignedProtocol: 'Ectomorph: Lean Mass & Agility',
        ),
      ];

      // 1. Ingest batch in first session
      final importSuccess = await repo1.importBatch(
        tenantId: testTenantId,
        members: importedMembers,
      );
      expect(importSuccess, isTrue);

      final initialFetch = await repo1.fetchMembers(tenantId: testTenantId);
      expect(initialFetch.length, 2);
      expect(initialFetch[0].fullName, 'Hamza Tariq');
      expect(initialFetch[1].fullName, 'Bilal Khan');

      // 2. SIMULATE BROWSER RELOAD (F5 / CTRL+R)
      // New instance, empty RAM memory store, exactly like a fresh page load
      final repo2 = MembersRepository(null, storage);

      final restoredMembers = await repo2.fetchMembers(tenantId: testTenantId);

      // Verify that NO USERS VANISHED upon reload
      expect(restoredMembers.isNotEmpty, isTrue);
      expect(restoredMembers.length, 2);
      expect(restoredMembers[0].memberCode, 'GC-M-1011');
      expect(restoredMembers[0].fullName, 'Hamza Tariq');
      expect(restoredMembers[0].duesAmount, 5000.0);
      expect(restoredMembers[0].tempPassword, 'Gym@Secure1011');
      expect(restoredMembers[1].memberCode, 'GC-M-1012');
      expect(restoredMembers[1].fullName, 'Bilal Khan');
    });

    test('Updating member details or resetting password persists across reload', () async {
      final storage = const SecureStorageService();
      final repo1 = MembersRepository(null, storage);

      final member = GymMember(
        id: 'member-freeze-test',
        tenantId: testTenantId,
        memberCode: 'GC-M-2001',
        fullName: 'Zainab Ahmed',
        phone: '+923335557799',
        email: 'zainab@titangym.com',
        planName: 'Quarterly Shred',
        joinDate: DateTime(2026, 1, 15),
        expiryDate: DateTime(2026, 4, 15),
        duesAmount: 0,
        tempPassword: 'InitialPassword1',
      );

      await repo1.createMember(tenantId: testTenantId, member: member);

      // Update password and freeze status
      await repo1.resetPassword(
        tenantId: testTenantId,
        memberId: 'member-freeze-test',
        newPassword: 'BrandNewPassword2026!',
      );

      final updatedMember = member.copyWith(
        status: MemberAccountStatus.frozen,
        freezeReason: 'Medical Leave',
        tempPassword: '',
      );
      await repo1.updateMember(member: updatedMember);

      // SIMULATE RELOAD
      final repo2 = MembersRepository(null, storage);
      final reloaded = await repo2.fetchMembers(tenantId: testTenantId);

      expect(reloaded.length, 1);
      expect(reloaded.first.tempPassword, 'BrandNewPassword2026!');
      expect(reloaded.first.isFrozen, isTrue);
      expect(reloaded.first.freezeReason, 'Medical Leave');
    });

    test('MembersNotifier loads and maintains state through reload lifecycle', () async {
      final container = ProviderContainer();

      final notifier = container.read(membersNotifierProvider.notifier);
      final sample = GymMember(
        id: 'test-notifier-mem',
        tenantId: testTenantId,
        memberCode: 'GC-M-3001',
        fullName: 'Danyal Malik',
        phone: '+923009998877',
        email: 'danyal@titangym.com',
        joinDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2026, 6, 1),
      );

      await notifier.addMember(sample);
      expect(container.read(membersNotifierProvider).allMembers.length, 1);

      // Let pending microtasks settle
      await Future<void>.delayed(const Duration(milliseconds: 50));
      container.dispose();

      // Create a fresh container simulating reload
      final reloadContainer = ProviderContainer();

      await reloadContainer.read(membersNotifierProvider.notifier).loadMembers(testTenantId);
      final reloadedState = reloadContainer.read(membersNotifierProvider);

      expect(reloadedState.allMembers.length, 1);
      expect(reloadedState.allMembers.first.fullName, 'Danyal Malik');
      expect(reloadedState.allMembers.first.memberCode, 'GC-M-3001');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      reloadContainer.dispose();
    });
  });
}
