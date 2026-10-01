import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/auth/presentation/auth_gate.dart';
import 'package:gym_connect_app/features/auth/presentation/login_screen.dart';
import 'package:gym_connect_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:gym_connect_app/features/auth/presentation/providers/auth_state.dart';
import 'package:gym_connect_app/features/auth/presentation/signup_screen.dart';
import 'package:gym_connect_app/features/auth/presentation/widgets/member_onboarding_gate_view.dart';
import 'package:gym_connect_app/features/workout/domain/models/fitness_profile_model.dart';
import 'package:gym_connect_app/features/workout/presentation/providers/fitness_profile_provider.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/member_today_tab.dart';

class FakeAuthNotifier extends AuthNotifier {
  final AppAuthState initialState;
  FakeAuthNotifier(this.initialState);

  @override
  AppAuthState build() => initialState;
}

class FakeFitnessProfileNotifier extends FitnessProfileNotifier {
  final UserFitnessProfile initialProfile;
  FakeFitnessProfileNotifier(this.initialProfile);

  @override
  Future<UserFitnessProfile> build() async => initialProfile;
}

void main() {
  const testMemberProfile = UserProfile(
    id: 'mem-999-uuid',
    role: UserRole.member,
    fullName: 'Bilal Khan',
    email: 'bilal@titanfitness.com',
    tenantId: '00000000-0000-0000-0000-000000000001',
    tenantName: 'TITAN FITNESS CLUB',
  );

  group('Real Supabase Auth Screens & Form Validation Tests', () {
    testWidgets('SignupScreen renders all required registration fields and branding', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GYMCONNECT'), findsOneWidget);
      expect(find.text('NEW MEMBER REGISTRATION'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password (min 6 characters)'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT & ONBOARD'), findsOneWidget);
      expect(find.text('Log In here'), findsOneWidget);
    });

    testWidgets('SignupScreen enforces password confirmation matching', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter name, email, and mismatching passwords
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Hamza Ali');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'hamza@titan.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password (min 6 characters)'), 'secret123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'differentpass');

      await tester.tap(find.text('CREATE ACCOUNT & ONBOARD'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('LoginScreen renders Create Account link and navigates to SignupScreen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AUTHENTICATE'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('NEW MEMBER REGISTRATION'), findsOneWidget);
    });
  });

  group('Smart Routing & New Member Onboarding Gate Tests', () {
    testWidgets('AuthGate routes uncompleted member profile to MemberOnboardingGateView', (tester) async {
      const uncompletedFitnessProfile = UserFitnessProfile(
        userId: 'mem-999-uuid',
        profileCompleted: false, // Brand new member
        assignedWorkoutTrack: 'track_a',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(
                const AuthAuthenticated(
                  profile: testMemberProfile,
                  activeRole: UserRole.member,
                ),
              ),
            ),
            fitnessProfileProvider.overrideWith(
              () => FakeFitnessProfileNotifier(uncompletedFitnessProfile),
            ),
          ],
          child: const MaterialApp(
            home: AuthGate(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: Forced into Rapid 30-Second Setup
      expect(find.byType(MemberOnboardingGateView), findsOneWidget);
      expect(find.text('RAPID 30-SECOND SETUP'), findsOneWidget);
      expect(find.text('1-TAP LAUNCH PROTOCOL'), findsOneWidget);
      expect(find.text('NEW MEMBER CALIBRATION'), findsOneWidget);
    });

    testWidgets('AuthGate routes completed member profile directly to Member Shell & Today Tab', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const completedFitnessProfile = UserFitnessProfile(
        userId: 'mem-999-uuid',
        profileCompleted: true, // Existing onboarded member
        assignedWorkoutTrack: 'track_a',
        currentWeightKg: 78.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(
                const AuthAuthenticated(
                  profile: testMemberProfile,
                  activeRole: UserRole.member,
                ),
              ),
            ),
            fitnessProfileProvider.overrideWith(
              () => FakeFitnessProfileNotifier(completedFitnessProfile),
            ),
          ],
          child: const MaterialApp(
            home: AuthGate(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: Bypasses onboarding gate and lands directly in member shell & today tab
      expect(find.byType(MemberOnboardingGateView), findsNothing);
      expect(find.text('RAPID 30-SECOND SETUP'), findsNothing);
      expect(find.byType(MemberTodayTab), findsOneWidget);
    });
  });
}
