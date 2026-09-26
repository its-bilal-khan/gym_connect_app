import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/core/theme/app_theme_presets.dart';
import 'package:gym_connect_app/core/theme/widgets/theme_color_card.dart';
import 'package:gym_connect_app/core/theme/widgets/theme_color_switcher_dialog.dart';
import 'package:gym_connect_app/core/theme/widgets/theme_change_request_dialog.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:gym_connect_app/features/auth/presentation/providers/auth_state.dart';

void main() {
  group('GymConnect Brand Theme & Accent System Tests', () {
    test('The 4 brand theme presets match exact master rules', () {
      expect(AppThemePreset.values.length, 4);

      final volt = AppThemePreset.neonVolt;
      expect(volt.hex, '#CCFF00');
      expect(volt.color, const Color(0xFFCCFF00));

      final blue = AppThemePreset.electricBlue;
      expect(blue.hex, '#4F7CFF');
      expect(blue.color, const Color(0xFF4F7CFF));

      final yellow = AppThemePreset.softYellow;
      expect(yellow.hex, '#F4E87C');
      expect(yellow.color, const Color(0xFFF4E87C));

      final purple = AppThemePreset.lavenderPurple;
      expect(purple.hex, '#A78BFA');
      expect(purple.color, const Color(0xFFA78BFA));
    });

    test('AppColors.primary and primaryAccent update dynamically at runtime when theme changes', () {
      AppColors.setPrimaryAccent(const Color(0xFFCCFF00));
      expect(AppColors.primary, const Color(0xFFCCFF00));
      expect(AppColors.primaryAccent, const Color(0xFFCCFF00));

      AppColors.setPrimaryAccent(const Color(0xFF4F7CFF)); // Electric Blue
      expect(AppColors.primary, const Color(0xFF4F7CFF));
      expect(AppColors.primaryAccent, const Color(0xFF4F7CFF));

      AppColors.setPrimaryAccent(const Color(0xFFF4E87C)); // Soft Yellow
      expect(AppColors.primary, const Color(0xFFF4E87C));
      expect(AppColors.primaryAccent, const Color(0xFFF4E87C));

      AppColors.setPrimaryAccent(const Color(0xFFA78BFA)); // Lavender
      expect(AppColors.primary, const Color(0xFFA78BFA));
      expect(AppColors.primaryAccent, const Color(0xFFA78BFA));
    });

    test('AppThemePreset.fromHex and fromColor resolve correctly', () {
      expect(AppThemePreset.fromHex('#4F7CFF'), AppThemePreset.electricBlue);
      expect(AppThemePreset.fromHex('F4E87C'), AppThemePreset.softYellow);
      expect(AppThemePreset.fromHex('#CCFF00'), AppThemePreset.neonVolt);
      expect(AppThemePreset.fromHex('#A78BFA'), AppThemePreset.lavenderPurple);
      expect(AppThemePreset.fromHex(null), AppThemePreset.neonVolt);

      expect(AppThemePreset.fromColor(const Color(0xFF4F7CFF)), AppThemePreset.electricBlue);
      expect(AppThemePreset.fromColor(const Color(0xFFF4E87C)), AppThemePreset.softYellow);
      expect(AppThemePreset.fromColor(const Color(0xFFA78BFA)), AppThemePreset.lavenderPurple);
      expect(AppThemePreset.fromColor(null), AppThemePreset.neonVolt);
    });

    test('UserProfile parses isThemeLocked and pending change requests from branding JSON', () {
      final json = {
        'id': 'user-100',
        'tenant_id': 'tenant-titan',
        'role': 'gym_owner',
        'full_name': 'Gym Owner John',
        'email': 'owner@titan.io',
        'tenants': {
          'name': 'Titan Gym',
          'branding': {
            'primary_color': '#4F7CFF',
            'theme_locked': true,
            'pending_theme_request': {
              'requested_color': '#F4E87C',
              'reason': 'Summer 2026 Brand Refresh',
            },
          },
        },
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.tenantName, 'Titan Gym');
      expect(profile.tenantPrimaryColor, const Color(0xFF4F7CFF));
      expect(profile.isThemeLocked, isTrue);
      expect(profile.pendingThemeRequestColor, '#F4E87C');
      expect(profile.pendingThemeRequestReason, 'Summer 2026 Brand Refresh');
    });

    testWidgets('ThemeColorCard renders name, hex and triggers onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeColorCard(
              preset: AppThemePreset.electricBlue,
              isSelected: true,
              isLocked: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Electric Blue'), findsOneWidget);
      expect(find.text('#4F7CFF'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);

      await tester.tap(find.byType(ThemeColorCard));
      expect(tapped, isTrue);
    });

    testWidgets('ThemeColorSwitcherDialog renders all 4 presets on Desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const ownerProfile = UserProfile(
        id: 'owner-1',
        tenantId: 'tenant-1',
        role: UserRole.owner,
        fullName: 'Owner Mike',
        email: 'mike@gym.com',
        tenantName: 'Apex Fitness',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const AuthAuthenticated(profile: ownerProfile, activeRole: UserRole.owner),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ThemeColorSwitcherDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BRAND COLOR & THEME PALETTE'), findsOneWidget);
      expect(find.text('Neon Volt Green'), findsOneWidget);
      expect(find.text('Electric Blue'), findsOneWidget);
      expect(find.text('Soft Premium Yellow'), findsOneWidget);
      expect(find.text('Soft Lavender Purple'), findsOneWidget);
      expect(find.text('LOCK PERMANENTLY'), findsOneWidget);

      // Tap on Electric Blue
      await tester.tap(find.text('Electric Blue'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap LOCK PERMANENTLY opens confirmation dialog
      await tester.tap(find.text('LOCK PERMANENTLY'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Lock Theme Permanently?'), findsOneWidget);
      expect(find.text('YES, LOCK PERMANENTLY'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      // Cancel dismisses confirmation dialog
      await tester.tap(find.text('CANCEL'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Lock Theme Permanently?'), findsNothing);
    });

    testWidgets('ThemeChangeRequestDialog validates empty reason and submits', (tester) async {
      const ownerProfile = UserProfile(
        id: 'owner-1',
        tenantId: 'tenant-1',
        role: UserRole.owner,
        fullName: 'Owner Mike',
        email: 'mike@gym.com',
        tenantName: 'Apex Fitness',
        isThemeLocked: true,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemeChangeRequestDialog(
                profile: ownerProfile,
                currentLockedPreset: AppThemePreset.neonVolt,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GENERATE THEME CHANGE REQUEST'), findsOneWidget);

      // Attempting to submit without reason shows validation error
      await tester.tap(find.text('SUBMIT REQUEST'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Please provide a reason for the brand color change.'), findsOneWidget);
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  final AppAuthState initialState;
  _FakeAuthNotifier(this.initialState);

  @override
  AppAuthState build() => initialState;
}
