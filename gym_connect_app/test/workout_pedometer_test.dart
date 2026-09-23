import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health/health.dart';
import 'package:gym_connect_app/core/services/secure_storage_service.dart';
import 'package:gym_connect_app/features/shells/member/presentation/widgets/pedometer_card.dart';
import 'package:gym_connect_app/features/tracking/presentation/providers/step_tracker_notifier.dart';
import 'package:gym_connect_app/features/tracking/services/step_tracker_service.dart';
import 'package:gym_connect_app/features/workout/data/workout_repository.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';
import 'package:gym_connect_app/features/workout/presentation/active_workout_screen.dart';
import 'package:gym_connect_app/features/workout/presentation/providers/rest_timer_notifier.dart';
import 'package:gym_connect_app/features/workout/presentation/providers/workout_notifier.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/exercise_pip_player.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/ninety_day_calendar_widget.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/one_tap_action_card.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/set_tracker_tile.dart';

void main() {
  group('Workout Models & Repository Tests', () {
    test('WorkoutRepository generates 90-day calendar accurately', () async {
      const repo = WorkoutRepository(null);
      final calendar = await repo.get90DayCalendar();

      expect(calendar.length, 90);
      expect(calendar.first.dayNumber, 1);
      expect(calendar.last.dayNumber, 90);
      expect(calendar.first.exercises.isNotEmpty, isTrue);
    });

    test('WorkoutRepository returns today routine', () async {
      const repo = WorkoutRepository(null);
      final today = await repo.getTodayRoutine(dayNumber: 24);

      expect(today.title, isNotEmpty);
      expect(today.muscleGroups, isNotEmpty);
    });
  });

  group('WorkoutNotifier & Session State Tests', () {
    test('WorkoutNotifier loads routine and tracks set completion', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workoutNotifierProvider.notifier);
      await notifier.loadTodayRoutine(day: 1);

      final state = container.read(workoutNotifierProvider);
      expect(state.routineDay, isNotNull);
      expect(state.routineDay!.exercises.length, 4);

      final firstExerciseId = state.routineDay!.exercises.first.id;
      expect(state.progressPercentage, 0.0);

      // Toggle first set completed
      notifier.toggleSet(firstExerciseId, 0);

      final updatedState = container.read(workoutNotifierProvider);
      expect(updatedState.setsByExercise[firstExerciseId]!.first.isCompleted, isTrue);
      expect(updatedState.progressPercentage, greaterThan(0.0));
    });
  });

  group('RestTimerNotifier Tests', () {
    test('RestTimerNotifier starts and calculates progress', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(seconds: 60);

      var state = container.read(restTimerProvider);
      expect(state.isRunning, isTrue);
      expect(state.secondsRemaining, 60);
      expect(state.progress, 1.0);

      notifier.addSeconds(15);
      state = container.read(restTimerProvider);
      expect(state.secondsRemaining, 75);

      notifier.cancelTimer();
      state = container.read(restTimerProvider);
      expect(state.isRunning, isFalse);
      expect(state.secondsRemaining, 0);
    });
  });

  group('Workout Video Streaming Tests', () {
    test('WorkoutRepository exercises have valid Google Cloud sample MP4 video URLs', () async {
      const repo = WorkoutRepository(null);
      final routine = await repo.getTodayRoutine();
      for (final ex in routine.exercises) {
        expect(ex.exercise.videoUrl, isNotNull);
        expect(ex.exercise.videoUrl!.endsWith('.mp4'), isTrue);
        expect(ex.exercise.videoUrl!.startsWith('https://'), isTrue);
      }
    });
  });

  group('StepTrackerService Tests', () {
    test('StepTrackerService correctly computes distance and calories', () {
      final service = StepTrackerService();

      // 10,000 steps * 0.000762 km = 7.62 km
      expect(service.calculateDistance(10000), 7.62);

      // 10,000 steps * 0.04 kcal = 400 kcal
      expect(service.calculateCalories(10000), 400);
    });

    test('StepTrackerService explicitly declares stepDataTypes and stepPermissions for Health Connect', () {
      expect(StepTrackerService.stepDataTypes, contains(HealthDataType.STEPS));
      expect(StepTrackerService.stepPermissions, contains(HealthDataAccess.READ));
    });

    test('StepTrackerService fetchDailySteps queries aggregated interval steps safely', () async {
      final service = StepTrackerService(
        null,
        null,
        null,
        (start, end) async => 5430, // Mock Health aggregate response
      );

      final steps = await service.fetchDailySteps();
      expect(steps, 5430);
      expect(service.calculateDistance(steps!), 4.14);
      expect(service.calculateCalories(steps), 217);
    });

    test('StepTrackerService mock stream emits aggregated steps', () async {
      final streamController = StreamController<int>();
      final service = StepTrackerService(null, null, streamController.stream);

      final emissions = <int>[];
      final sub = service.liveStepStream.listen(emissions.add);

      streamController.add(50);
      streamController.add(120);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emissions, [50, 120]);
      await sub.cancel();
      await streamController.close();
    });

    test('StepTrackerService pauses and resumes tracking', () {
      final service = StepTrackerService();
      expect(service.isPaused, isFalse);
      service.pauseTracking();
      expect(service.isPaused, isTrue);
      service.resumeTracking();
      expect(service.isPaused, isFalse);
    });

    test('StepTrackerService closed-app checkpoint and background delta reconciliation', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = SecureStorageService(FlutterSecureStorage());
      final service = StepTrackerService(storage);

      // User walks 2000 steps with app open, then app closes without pause
      await service.saveBackgroundCheckpoint(2000, isPaused: false);
      expect(service.isPaused, isFalse);

      // Re-opening app on the same day loads preserved steps
      final baseline = await service.loadTodayBaseline();
      expect(baseline, 2000);
      expect(service.isPaused, isFalse);
    });
  });

  group('StepTrackerNotifier Live Hardware Tests', () {
    test('StepTrackerNotifier initializes with 0 steps and updates dynamic metrics', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stepTrackerProvider.notifier);
      final initialData = container.read(stepTrackerProvider);
      expect(initialData.steps, 0);
      expect(initialData.distanceKm, 0.0);
      expect(initialData.caloriesBurned, 0);

      // Update to 8,000 steps
      notifier.updateSteps(8000, isLive: true);
      final updatedData = container.read(stepTrackerProvider);

      expect(updatedData.steps, 8000);
      expect(updatedData.distanceKm, 6.10); // 8000 * 0.000762 = 6.096 -> 6.10
      expect(updatedData.caloriesBurned, 320); // 8000 * 0.04 = 320
      expect(updatedData.isTrackingLive, isTrue);
    });

    test('StepTrackerNotifier pauseTracking, resumeTracking, and togglePauseResume update state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stepTrackerProvider.notifier);
      notifier.updateSteps(5000, isLive: true);

      expect(container.read(stepTrackerProvider).isPaused, isFalse);
      expect(container.read(stepTrackerProvider).isTrackingLive, isTrue);

      notifier.pauseTracking();
      final paused = container.read(stepTrackerProvider);
      expect(paused.isPaused, isTrue);
      expect(paused.isTrackingLive, isFalse);
      expect(paused.badgeText, 'TRACKING PAUSED');
      expect(paused.steps, 5000);

      notifier.resumeTracking();
      final resumed = container.read(stepTrackerProvider);
      expect(resumed.isPaused, isFalse);
      expect(resumed.isTrackingLive, isTrue);
      expect(resumed.badgeText, 'HEALTH CONNECT LIVE');

      notifier.togglePauseResume();
      expect(container.read(stepTrackerProvider).isPaused, isTrue);
    });

    test('StepTrackerNotifier preserves step count and does not wipe to 0 when paused or refetched', () async {
      final mockService = StepTrackerService(
        null,
        null,
        null,
        (start, end) async => 5000,
      );
      final container = ProviderContainer(
        overrides: [stepTrackerServiceProvider.overrideWithValue(mockService)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(stepTrackerProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(container.read(stepTrackerProvider).steps, 5000);

      // Pause tracking
      notifier.pauseTracking();
      expect(container.read(stepTrackerProvider).steps, 5000);
      expect(container.read(stepTrackerProvider).isPaused, isTrue);

      // Re-trigger handleCardAction while paused: must not reset to 0
      await notifier.handleCardAction();
      expect(container.read(stepTrackerProvider).steps, 5000);

      // Resume tracking: preserves steps
      notifier.resumeTracking();
      expect(container.read(stepTrackerProvider).steps, 5000);
      expect(container.read(stepTrackerProvider).isPaused, isFalse);
    });

    test('StepTrackerNotifier updates immediately upon receiving first sensor event', () async {
      final streamController = StreamController<int>();
      final mockService = StepTrackerService(null, null, streamController.stream);

      final container = ProviderContainer(
        overrides: [
          stepTrackerServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      container.read(stepTrackerProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final initialData = container.read(stepTrackerProvider);
      expect(initialData.steps, 0);

      // First sensor event arrives (e.g. 0 steps)
      streamController.add(0);
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final firstEventData = container.read(stepTrackerProvider);
      expect(firstEventData.steps, 0);
      expect(firstEventData.isTrackingLive, isTrue);
      expect(firstEventData.isWaitingForSensor, isFalse);

      // Next sensor event arrives (e.g. 15 steps walked)
      streamController.add(15);
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final walkedData = container.read(stepTrackerProvider);
      expect(walkedData.steps, 15);
      expect(walkedData.isTrackingLive, isTrue);

      await streamController.close();
    });

    test('StepTrackerNotifier boots with Health aggregate daily steps', () async {
      final mockService = StepTrackerService(
        null,
        null,
        null,
        (start, end) async => 3200,
      );

      final container = ProviderContainer(
        overrides: [
          stepTrackerServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      container.read(stepTrackerProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(stepTrackerProvider);
      expect(state.steps, 3200);
      expect(state.distanceKm, 2.44);
      expect(state.caloriesBurned, 128);
      expect(state.isTrackingLive, isTrue);
    });

    test('StepTrackerNotifier handles Health Connect missing gracefully', () async {
      final mockService = StepTrackerService(
        null,
        null,
        null,
        null,
        () async => HealthAuthResult.healthConnectNotInstalled,
      );

      final container = ProviderContainer(
        overrides: [
          stepTrackerServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      container.read(stepTrackerProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(stepTrackerProvider);
      expect(state.isHealthConnectMissing, isTrue);
      expect(state.sensorError, contains('Health Connect required'));
      expect(state.badgeText, 'INSTALL HEALTH CONNECT');
      expect(state.isWaitingForSensor, isFalse);
    });

    test('StepTrackerNotifier handles Health permission denied gracefully', () async {
      final mockService = StepTrackerService(
        null,
        null,
        null,
        null,
        () async => HealthAuthResult.denied,
      );

      final container = ProviderContainer(
        overrides: [
          stepTrackerServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      container.read(stepTrackerProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(stepTrackerProvider);
      expect(state.isHealthConnectMissing, isFalse);
      expect(state.sensorError, contains('Health permission required'));
      expect(state.badgeText, 'PERMISSION NEEDED');
      expect(state.isWaitingForSensor, isFalse);
    });

    test('StepTrackerNotifier handleCardAction opens Settings and sets diagnostic when rejected', () async {
      bool settingsOpened = false;
      final mockService = StepTrackerService(
        null,
        null,
        null,
        null,
        () async => HealthAuthResult.denied,
        () async {
          settingsOpened = true;
          return true;
        },
      );

      final container = ProviderContainer(
        overrides: [
          stepTrackerServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(stepTrackerProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Tap card
      await notifier.handleCardAction();

      expect(settingsOpened, isTrue);
      final updatedState = container.read(stepTrackerProvider);
      expect(updatedState.badgeText, 'OPEN SETTINGS');
      expect(updatedState.sensorError, contains('Opening Settings'));
    });
  });

  group('Phase 3 Widgets Tests', () {
    const testExercise = Exercise(
      id: 'ex-bench',
      name: 'Barbell Bench Press',
      targetMuscle: 'Chest',
      equipment: 'Barbell',
      tips: 'Tuck elbows and touch mid-chest.',
    );

    const testRoutineDay = WorkoutRoutineDay(
      id: 'day-1',
      routineId: 'routine-90',
      dayNumber: 24,
      title: 'Chest & Triceps Blitz',
      muscleGroups: ['Chest', 'Triceps'],
      exercises: [
        WorkoutDayExercise(
          id: 'de-1',
          exercise: testExercise,
          orderIndex: 1,
          targetSets: 3,
        ),
      ],
    );

    testWidgets('OneTapActionCard renders hero action and triggers onStart callback', (tester) async {
      bool started = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneTapActionCard(
              routine: testRoutineDay,
              onStart: () => started = true,
            ),
          ),
        ),
      );

      expect(find.text("START TODAY'S WORKOUT"), findsOneWidget);
      expect(find.text('DAY 24 OF 90'), findsOneWidget);

      await tester.tap(find.text("START TODAY'S WORKOUT"));
      await tester.pump();
      expect(started, isTrue);
    });

    testWidgets('ExercisePipPlayer renders silent auto-loop and toggle angle controls', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExercisePipPlayer(exercise: testExercise),
          ),
        ),
      );

      expect(find.text('PIP SILENT AUTO-LOOP'), findsOneWidget);
      expect(find.text('SIDE VIEW'), findsOneWidget);
      expect(find.text(testExercise.tips), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);

      // Tap angle toggle button to switch to side view
      await tester.tap(find.text('SIDE VIEW'));
      await tester.pump();
      expect(find.text('FRONT VIEW'), findsOneWidget);

      // Tap fullscreen button to open FullscreenVideoDialog
      await tester.tap(find.byIcon(Icons.fullscreen_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CAMERA ANGLE'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('SetTrackerTile increments weight and reps and toggles checkmark', (tester) async {
      double updatedWeight = 0;
      int updatedReps = 0;
      bool toggled = false;

      const record = WorkoutSetRecord(
        setNumber: 1,
        targetReps: 10,
        actualReps: 10,
        weightKg: 50.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetTrackerTile(
              record: record,
              onToggle: () => toggled = true,
              onWeightChanged: (w) => updatedWeight = w,
              onRepsChanged: (r) => updatedReps = r,
            ),
          ),
        ),
      );

      expect(find.text('SET 1'), findsOneWidget);
      expect(find.text('50.0'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();
      expect(toggled, isTrue);

      await tester.tap(find.byIcon(Icons.arrow_drop_up_rounded).first);
      await tester.pump();
      expect(updatedWeight, 52.5);

      await tester.tap(find.byIcon(Icons.arrow_drop_up_rounded).last);
      await tester.pump();
      expect(updatedReps, 11);
    });

    testWidgets('NinetyDayCalendarWidget renders 90 days and allows selecting a day', (tester) async {
      int selectedDay = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NinetyDayCalendarWidget(
              currentDay: 24,
              onDaySelected: (d) => selectedDay = d,
            ),
          ),
        ),
      );

      expect(find.text('90-DAY SMART CALENDAR'), findsOneWidget);
      expect(find.text('DAY'), findsWidgets);

      await tester.tap(find.text('2'));
      await tester.pump();
      expect(selectedDay, 2);
    });

    testWidgets('ActiveWorkoutScreen renders workout execution layout', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(workoutNotifierProvider.notifier).loadTodayRoutine();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ActiveWorkoutScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
      expect(find.text('FINISH'), findsOneWidget);
      expect(find.byType(ExercisePipPlayer), findsOneWidget);
      expect(find.byType(SetTrackerTile), findsWidgets);
    });

    testWidgets('PedometerCard renders 0 steps and Waiting for motion when default or waiting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedometerCard(),
          ),
        ),
      );

      expect(find.text('0 steps'), findsOneWidget);
      expect(find.text('Waiting for motion...'), findsOneWidget);
      expect(find.text('WAITING FOR MOTION'), findsOneWidget);
    });

    testWidgets('PedometerCard renders Waiting for motion when error occurs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedometerCard(
              errorMessage: 'Permission denied',
            ),
          ),
        ),
      );

      expect(find.text('0 steps'), findsOneWidget);
      expect(find.text('Waiting for motion...'), findsOneWidget);
      expect(find.text('WAITING FOR MOTION'), findsOneWidget);
    });

    testWidgets('PedometerCard renders INSTALL HEALTH CONNECT badge and handles onTap when missing', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PedometerCard(
              isHealthConnectMissing: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('INSTALL HEALTH CONNECT'), findsOneWidget);
      expect(find.text('Health Connect required • Tap to install'), findsOneWidget);

      await tester.tap(find.byType(PedometerCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('PedometerCard renders PERMISSION NEEDED badge when permission is denied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedometerCard(
              badgeText: 'PERMISSION NEEDED',
              errorMessage: 'Health permission required. Tap to grant.',
            ),
          ),
        ),
      );

      expect(find.text('PERMISSION NEEDED'), findsOneWidget);
    });

    testWidgets('PedometerCard renders step count and HARDWARE LIVE badge when isLive is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedometerCard(
              steps: 9200,
              distanceKm: 7.01,
              caloriesBurned: 368,
              isLive: true,
            ),
          ),
        ),
      );

      expect(find.text('9200 STEPS TODAY'), findsOneWidget);
      expect(find.text('HARDWARE LIVE'), findsOneWidget);
    });

    testWidgets('PedometerCard renders TRACKING PAUSED badge and triggers onTogglePause callback', (tester) async {
      bool toggleTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PedometerCard(
              steps: 4500,
              distanceKm: 3.42,
              caloriesBurned: 180,
              isPaused: true,
              onTogglePause: () => toggleTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('4500 STEPS TODAY'), findsOneWidget);
      expect(find.text('TRACKING PAUSED'), findsOneWidget);
      expect(find.textContaining('Tracking Paused'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expect(toggleTapped, isTrue);
    });

    testWidgets('PedometerCard renders action button and triggers onTap when permission is needed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PedometerCard(
              badgeText: 'PERMISSION NEEDED',
              errorMessage: 'Health permission required. Tap to grant.',
              onTap: () => tapped = true,
              onTogglePause: () {},
            ),
          ),
        ),
      );

      expect(find.text('PERMISSION NEEDED'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}

