import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/members/data/excel_import_service.dart';
import 'package:gym_connect_app/features/members/domain/models/gym_member.dart';
import 'package:gym_connect_app/features/members/presentation/providers/members_provider.dart';
import 'package:gym_connect_app/features/members/presentation/screens/desktop_member_hub_screen.dart';
import 'package:gym_connect_app/features/members/presentation/widgets/member_data_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  group('ExcelImportService Tests', () {
    const importService = ExcelImportService();

    test('detectColumnMapping recognizes standard gym spreadsheet headers', () {
      final headers = [
        'Roll No',
        'Client Name',
        'Mobile No',
        'E-mail',
        'Package Tier',
        'Admission Date',
        'Renewal Date',
        'Balance Due',
        'Temp PIN',
        'Workout Split',
      ];

      final mapping = importService.detectColumnMapping(headers);

      expect(mapping['code'], 0);
      expect(mapping['name'], 1);
      expect(mapping['phone'], 2);
      expect(mapping['email'], 3);
      expect(mapping['plan'], 4);
      expect(mapping['joinDate'], 5);
      expect(mapping['expiryDate'], 6);
      expect(mapping['dues'], 7);
      expect(mapping['password'], 8);
      expect(mapping['protocol'], 9);
    });

    test('processWithMapping creates valid GymMembers and handles duplicate updates', () {
      final existing = [
        GymMember(
          id: 'existing-1',
          tenantId: 'tenant-1',
          memberCode: 'GC-M-1001',
          fullName: 'Original Name',
          phone: '+923001234567',
          email: 'test@example.com',
          joinDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2026, 6, 1),
          duesAmount: 0,
        ),
      ];

      final rows = [
        ['GC-M-1001', 'Updated Name', '03001234567', 'test@example.com', 'Annual VIP', '2026-01-01', '2026-12-31', '5000', 'Gym@Pass', 'Mesomorph'],
        ['GC-M-1002', 'New Member', '03219876543', 'new@example.com', 'Monthly', '2026-09-01', '2026-10-01', '0', 'Gym@New', 'Ectomorph'],
      ];

      final mapping = {
        'code': 0,
        'name': 1,
        'phone': 2,
        'email': 3,
        'plan': 4,
        'joinDate': 5,
        'expiryDate': 6,
        'dues': 7,
        'password': 8,
        'protocol': 9,
      };

      // Test with updateDuplicates = true
      final resultUpdate = importService.processWithMapping(
        rows: rows,
        mapping: mapping,
        tenantId: 'tenant-1',
        updateDuplicates: true,
        existingMembers: existing,
      );

      expect(resultUpdate.successCount, 2);
      expect(resultUpdate.updatedCount, 1);
      expect(resultUpdate.newCount, 1);
      expect(resultUpdate.validMembers.first.fullName, 'Updated Name');
      expect(resultUpdate.validMembers.first.duesAmount, 5000.0);
    });

    test('generateSampleCsvTemplate generates valid CSV structure', () {
      final csv = ExcelImportService.generateSampleCsvTemplate();
      expect(csv, contains('Member Code,Full Name,Phone Number,Email'));
      expect(csv, contains('GC-M-1011,Hamza Tariq'));
    });
  });

  group('GymMember Domain Model Tests', () {
    test('Calculates isExpiringSoon for memberships expiring within 7 days', () {
      final now = DateTime.now();

      final expiringMember = GymMember(
        id: 'exp-1',
        tenantId: 'tenant-1',
        memberCode: 'GC-M-99',
        fullName: 'Expiring Member',
        phone: '+923000000000',
        email: 'exp@example.com',
        joinDate: now.subtract(const Duration(days: 25)),
        expiryDate: now.add(const Duration(days: 3)), // 3 days remaining
      );

      expect(expiringMember.isExpiringSoon, isTrue);
      expect(expiringMember.daysUntilExpiry, 3);
      expect(expiringMember.isExpired, isFalse);

      final safeMember = expiringMember.copyWith(
        expiryDate: now.add(const Duration(days: 45)),
      );
      expect(safeMember.isExpiringSoon, isFalse);
    });

    test('Correctly handles freeze state and dues overdue badges', () {
      final now = DateTime.now();

      final member = GymMember(
        id: 'frz-1',
        tenantId: 'tenant-1',
        memberCode: 'GC-M-77',
        fullName: 'Frozen Member',
        phone: '+923000000000',
        email: 'frz@example.com',
        status: MemberAccountStatus.frozen,
        joinDate: now,
        expiryDate: now.add(const Duration(days: 30)),
        duesAmount: 3500.0,
        duesStatus: MemberDuesStatus.overdue,
      );

      expect(member.isFrozen, isTrue);
      expect(member.statusDisplay, 'FROZEN');
      expect(member.isDuesOverdue, isTrue);
      expect(member.duesStatusDisplay, 'OVERDUE');
    });
  });

  group('DesktopMemberHubScreen Widget Tests', () {
    final mockProfile = UserProfile(
      id: 'owner-test',
      tenantId: '00000000-0000-0000-0000-000000000001',
      fullName: 'Gym Owner Boss',
      email: 'owner@titangym.com',
      role: UserRole.owner,
    );

    testWidgets('Renders Executive Header, Stats, Status Tabs, and Empty State Card when database is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: DesktopMemberHubScreen(profile: mockProfile),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Header & Workstation Titles
      expect(find.textContaining('MEMBERS DIRECTORY & EXCEL INGESTION HUB'), findsOneWidget);
      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Excel / CSV Ingestion'), findsOneWidget);

      // Check Stats Row
      expect(find.text('TOTAL MEMBERS'), findsOneWidget);
      expect(find.text('ACTIVE PASSES'), findsOneWidget);
      expect(find.text('EXPIRING SOON'), findsOneWidget);
      expect(find.text('OVERDUE DUES'), findsOneWidget);

      // Check Quick Status Tabs
      expect(find.textContaining('ALL MEMBERS'), findsOneWidget);
      expect(find.textContaining('ACTIVE ('), findsOneWidget);
      expect(find.textContaining('⚠️ EXPIRING SOON'), findsOneWidget);

      // Check Master Toolbar & 360 Detailed Mode switch
      expect(find.textContaining('360° DETAILED MODE'), findsOneWidget);
      expect(find.text('Data Grid (Table)'), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);

      // When live database has 0 members, verifies zero dummy data & empty state card with Ingestion CTAs
      expect(find.text('NO GYM MEMBERS REGISTERED YET'), findsOneWidget);
      expect(find.text('Upload Excel / CSV Sheet'), findsOneWidget);
      expect(find.text('Register Member'), findsWidgets);
    });

    testWidgets('Populated roster renders Table, Grid Cards, and Density List seamlessly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      final container = ProviderContainer();
      final testMember = GymMember(
        id: 'mem-1',
        tenantId: '00000000-0000-0000-0000-000000000001',
        memberCode: 'GC-M-1001',
        fullName: 'Hamza Tariq',
        phone: '+923001234567',
        email: 'hamza@example.com',
        planName: 'Annual VIP Access',
        joinDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2027, 1, 1),
        duesAmount: 0,
        duesStatus: MemberDuesStatus.paid,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: DesktopMemberHubScreen(profile: mockProfile),
          ),
        ),
      );

      // Inject member into live state
      await container.read(membersNotifierProvider.notifier).addMember(testMember);
      await tester.pumpAndSettle();

      // Check Table View rendering member record
      expect(find.byType(MemberDataTable), findsOneWidget);
      expect(find.text('Hamza Tariq'), findsOneWidget);
      expect(find.text('GC-M-1001'), findsOneWidget);

      // Switch to Grid Cards View
      await tester.tap(find.text('Cards'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Hamza Tariq'), findsOneWidget);

      // Switch back to Table View
      await tester.tap(find.text('Data Grid (Table)'));
      await tester.pumpAndSettle();
      expect(find.byType(MemberDataTable), findsOneWidget);
      expect(find.text('Hamza Tariq'), findsOneWidget);
    });
  });
}
