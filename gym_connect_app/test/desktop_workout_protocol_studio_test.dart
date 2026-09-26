import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:gym_connect_app/features/auth/presentation/providers/auth_state.dart';
import 'package:gym_connect_app/features/workout/data/workout_repository.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';
import 'package:gym_connect_app/features/workout/presentation/desktop/desktop_workout_protocol_manager_view.dart';
import 'package:gym_connect_app/features/workout/presentation/providers/workout_protocol_manager_provider.dart';

const testProfile = UserProfile(
  id: 'user-owner-1',
  role: UserRole.owner,
  tenantId: 'tenant-lahore-101',
  fullName: 'Bilal Khan (Gym Owner)',
  email: 'bilal@fitzone.pk',
);

class FakeAuthNotifier extends AuthNotifier {
  @override
  AppAuthState build() =>
      const AuthAuthenticated(profile: testProfile, activeRole: UserRole.owner);
}

void main() {
  group('WorkoutRepository Protocol Hierarchy Tests', () {
    test('fetchFullWeeklyProtocol falls back to built-in catalog when remote is unavailable', () async {
      const repo = WorkoutRepository(null);
      final protocol = await repo.fetchFullWeeklyProtocol(
        bodyType: 'mesomorph',
        tenantId: 'tenant-lahore-101',
      );

      expect(protocol.bodyType, 'mesomorph');
      expect(protocol.days.length, 7);
      expect(protocol.isCustomTenantOverride, false);
      expect(protocol.days.first.exercises.isNotEmpty, true);
    });

    test('fetchExerciseCatalog extracts complete exercises from built-in repository catalog', () async {
      const repo = WorkoutRepository(null);
      final catalog = await repo.fetchExerciseCatalog();

      expect(catalog.isNotEmpty, true);
      expect(catalog.any((e) => e.name.toLowerCase().contains('bench press')), true);
      expect(catalog.any((e) => e.name.toLowerCase().contains('squat')), true);
    });
  });

  group('WorkoutProtocolManagerNotifier State Tests', () {
    test('notifier initializes with default protocol and catalog', () async {
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(const WorkoutRepository(null)),
          authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(workoutProtocolManagerProvider.notifier);
      await notifier.initialize(userTenantId: 'tenant-lahore-101', bodyType: 'mesomorph');

      final state = container.read(workoutProtocolManagerProvider);
      expect(state.isLoading, false);
      expect(state.workingDays.length, 7);
      expect(state.selectedBodyType, 'mesomorph');
      expect(state.isDirty, false);
    });

    test('notifier modifies exercise sets and reps marking isDirty to true', () async {
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(const WorkoutRepository(null)),
          authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(workoutProtocolManagerProvider.notifier);
      await notifier.initialize(userTenantId: 'tenant-lahore-101', bodyType: 'mesomorph');

      notifier.updateExerciseParameters(1, 0, targetSets: 5, targetRepsRange: '5x5');

      final state = container.read(workoutProtocolManagerProvider);
      expect(state.isDirty, true);
      final updatedEx = state.workingDays.first.exercises.first;
      expect(updatedEx.targetSets, 5);
      expect(updatedEx.targetRepsRange, '5x5');
    });

    test('notifier toggles day to rest day and back', () async {
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(const WorkoutRepository(null)),
          authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(workoutProtocolManagerProvider.notifier);
      await notifier.initialize(userTenantId: 'tenant-lahore-101', bodyType: 'ectomorph');

      notifier.toggleRestDay(1, true);
      var state = container.read(workoutProtocolManagerProvider);
      expect(state.workingDays.first.isRestDay, true);
      expect(state.isDirty, true);

      notifier.toggleRestDay(1, false);
      state = container.read(workoutProtocolManagerProvider);
      expect(state.workingDays.first.isRestDay, false);
    });

    test('notifier adds and removes exercise dynamically', () async {
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(const WorkoutRepository(null)),
          authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(workoutProtocolManagerProvider.notifier);
      await notifier.initialize(userTenantId: 'tenant-lahore-101', bodyType: 'mesomorph');

      final initialCount = container.read(workoutProtocolManagerProvider).workingDays.first.exercises.length;

      const newExercise = Exercise(
        id: 'test-deadlift',
        name: 'Deadlift',
        targetMuscle: 'Back',
        equipment: 'Barbell',
      );

      notifier.addExerciseToDay(1, newExercise, targetSets: 4, targetRepsRange: '5x5');
      var state = container.read(workoutProtocolManagerProvider);
      expect(state.workingDays.first.exercises.length, initialCount + 1);
      expect(state.workingDays.first.exercises.last.exercise.name, 'Deadlift');

      notifier.removeExerciseFromDay(1, state.workingDays.first.exercises.length - 1);
      state = container.read(workoutProtocolManagerProvider);
      expect(state.workingDays.first.exercises.length, initialCount);
    });
  });

  group('DesktopWorkoutProtocolManagerView Widget Tests', () {
    testWidgets('shows mobile guard message on screens under 800px width', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DesktopWorkoutProtocolManagerView(profile: testProfile),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DESKTOP POS ONLY'), findsOneWidget);
      expect(find.byIcon(Icons.desktop_windows_rounded), findsOneWidget);
    });

    testWidgets('renders full studio layout on desktop width (>= 800px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DesktopWorkoutProtocolManagerView(profile: testProfile),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WORKOUT PROTOCOL STUDIO'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text('ECTOMORPH'), findsOneWidget);
      expect(find.text('MESOMORPH'), findsOneWidget);
      expect(find.text('ENDOMORPH'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(find.text('DAY 1'), findsOneWidget);
      expect(find.text('DAY 7'), findsOneWidget);
    });
  });
}
