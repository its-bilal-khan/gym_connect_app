import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/super_admin/presentation/desktop/widgets/exercise_video_studio_tab.dart';
import 'package:gym_connect_app/features/workout/data/online_exercise_video_service.dart';
import 'package:gym_connect_app/features/workout/domain/models/cdn_video_item.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';
import 'package:gym_connect_app/features/workout/presentation/desktop/widgets/day_exercise_editor_card.dart';
import 'package:gym_connect_app/features/workout/presentation/providers/exercise_catalog_provider.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/attach_exercise_video_sheet.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/cdn_video_picker_dialog.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/exercise_video_preview_thumbnail.dart';

void main() {
  group('Exercise Video Model & Serialization Tests', () {
    test('Exercise copyWith updates videoUrl and sideVideoUrl correctly', () {
      const original = Exercise(
        id: 'ex-101',
        name: 'Incline Bench Press',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
      );

      expect(original.videoUrl, isNull);
      expect(original.sideVideoUrl, isNull);

      final updated = original.copyWith(
        videoUrl: 'https://cdn.example.com/incline_front.mp4',
        sideVideoUrl: 'https://cdn.example.com/incline_side.mp4',
      );

      expect(updated.id, 'ex-101');
      expect(updated.name, 'Incline Bench Press');
      expect(updated.videoUrl, 'https://cdn.example.com/incline_front.mp4');
      expect(updated.sideVideoUrl, 'https://cdn.example.com/incline_side.mp4');
    });

    test('Exercise toJson serializes all video and muscle fields correctly', () {
      const exercise = Exercise(
        id: 'ex-202',
        name: 'Deadlift Conventional',
        targetMuscle: 'Back',
        equipment: 'Barbell',
        difficulty: 'Advanced',
        videoUrl: 'https://cdn.example.com/deadlift.mp4',
        sideVideoUrl: 'https://cdn.example.com/deadlift_side.mp4',
        tips: 'Keep lats engaged and bar tight to shins.',
      );

      final json = exercise.toJson(isGlobal: true);

      expect(json['id'], 'ex-202');
      expect(json['name'], 'Deadlift Conventional');
      expect(json['target_muscle'], 'Back');
      expect(json['equipment'], 'Barbell');
      expect(json['video_url'], 'https://cdn.example.com/deadlift.mp4');
      expect(json['side_video_url'], 'https://cdn.example.com/deadlift_side.mp4');
      expect(json['is_global'], true);
    });
  });

  group('ExerciseCatalogNotifier State & Video Attachment Tests', () {
    test('ExerciseCatalogNotifier filters by video, search, and muscle', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(exerciseCatalogNotifierProvider.notifier);

      // Add test exercises
      const ex1 = Exercise(
        id: 'test-1',
        name: 'Barbell Squat',
        targetMuscle: 'Legs',
        equipment: 'Barbell',
        videoUrl: 'https://cdn.example.com/squat.mp4',
      );
      const ex2 = Exercise(
        id: 'test-2',
        name: 'Dumbbell Hammer Curl',
        targetMuscle: 'Arms',
        equipment: 'Dumbbell',
        videoUrl: null, // No video
      );

      await notifier.addOrUpdateExercise(ex1);
      await notifier.addOrUpdateExercise(ex2);

      var state = container.read(exerciseCatalogNotifierProvider);
      expect(state.allExercises.any((e) => e.id == 'test-1'), true);
      expect(state.allExercises.any((e) => e.id == 'test-2'), true);

      // Test muscle filter
      notifier.setSelectedMuscle('Legs');
      state = container.read(exerciseCatalogNotifierProvider);
      expect(state.filteredExercises.every((e) => e.targetMuscle == 'Legs'), true);

      // Reset muscle and filter by "only with videos"
      notifier.setSelectedMuscle('All');
      notifier.toggleOnlyWithVideos();
      state = container.read(exerciseCatalogNotifierProvider);
      expect(state.filteredExercises.every((e) => e.videoUrl != null && e.videoUrl!.isNotEmpty), true);
      expect(state.filteredExercises.any((e) => e.id == 'test-2'), false);

      // Attach video to test-2
      await notifier.attachOrUpdateVideo(
        exerciseId: 'test-2',
        videoUrl: 'https://cdn.example.com/curl_front.mp4',
        sideVideoUrl: 'https://cdn.example.com/curl_side.mp4',
      );

      state = container.read(exerciseCatalogNotifierProvider);
      final updatedEx2 = state.allExercises.firstWhere((e) => e.id == 'test-2');
      expect(updatedEx2.videoUrl, 'https://cdn.example.com/curl_front.mp4');
      expect(updatedEx2.sideVideoUrl, 'https://cdn.example.com/curl_side.mp4');
    });
  });

  group('Exercise Video Library & Anti-Duplicate Verification Tests', () {
    test('Chest exercises have diverse options and zero duplicate video URLs', () {
      final chestVideos = CdnVideoLibrary.search(muscle: 'Chest');

      // Must have multiple diverse chest exercises, not just push-ups
      expect(chestVideos.length, greaterThanOrEqualTo(8));

      // Push-Up and Bench Press MUST NOT share the same video URL
      final pushUp = chestVideos.firstWhere((v) => v.id == 'cdn-pushup');
      final benchPress = chestVideos.firstWhere((v) => v.id == 'cdn-bench-press');
      expect(pushUp.primaryVideoUrl, isNot(equals(benchPress.primaryVideoUrl)));

      // Every single chest exercise must have a distinct unique primaryVideoUrl
      final urls = chestVideos.map((v) => v.primaryVideoUrl).toList();
      final uniqueUrls = urls.toSet();
      expect(urls.length, equals(uniqueUrls.length),
          reason: 'Duplicate video URLs detected in chest exercise list!');

      // Check key chest movements are present
      expect(chestVideos.any((v) => v.title.contains('Push-Up')), true);
      expect(chestVideos.any((v) => v.title.contains('Bench Press')), true);
      expect(chestVideos.any((v) => v.title.contains('Incline')), true);
      expect(chestVideos.any((v) => v.title.contains('Dumbbell')), true);
      expect(chestVideos.any((v) => v.title.contains('Fly')), true);
      expect(chestVideos.any((v) => v.title.contains('Dips')), true);
    });

    test('OnlineExerciseVideoService creates custom streams correctly', () {
      final service = OnlineExerciseVideoService.instance;
      final custom = service.createCustomItem(
        title: 'Cable Standing Incline Fly',
        primaryVideoUrl: 'https://cdn.example.com/cable_incline.mp4',
        targetMuscle: 'Chest',
        equipment: 'Cable',
        tips: 'Squeeze upper chest at top peak.',
      );

      expect(custom.id, startsWith('custom-'));
      expect(custom.title, 'Cable Standing Incline Fly');
      expect(custom.targetMuscle, 'Chest');
      expect(custom.equipment, 'Cable');
      expect(custom.primaryVideoUrl, 'https://cdn.example.com/cable_incline.mp4');
      expect(custom.tips, 'Squeeze upper chest at top peak.');
    });
  });

  group('Exercise Video Widget Tests', () {
    testWidgets('AttachExerciseVideoSheet renders properly on mobile view', (tester) async {
      const exercise = Exercise(
        id: 'mobile-ex-1',
        name: 'Flat Dumbbell Press',
        targetMuscle: 'Chest',
        equipment: 'Dumbbell',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AttachExerciseVideoSheet(exercise: exercise),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ATTACH EXERCISE VIDEO'), findsOneWidget);
      expect(find.text('Flat Dumbbell Press'), findsOneWidget);
      expect(find.text('SEARCH MUSCLEWIKI (1,900+ HD FORM VIDEOS)'), findsOneWidget);
      expect(find.text('SAVE VIDEO'), findsOneWidget);
      expect(find.text('Preview Video'), findsOneWidget);
    });

    testWidgets('ExerciseVideoStudioTab renders metrics and controls on desktop view', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseVideoStudioTab(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TOTAL EXERCISES'), findsOneWidget);
      expect(find.text('VIDEOS ATTACHED'), findsOneWidget);
      expect(find.text('CDN STREAM ENGINE'), findsOneWidget);
      expect(find.text('ADD EXERCISE & VIDEO'), findsOneWidget);
      expect(find.text('Only With Videos'), findsOneWidget);
    });

    testWidgets('CdnVideoPickerDialog allows searching and selecting a CDN stream', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      CdnVideoItem? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  selectedItem = await CdnVideoPickerDialog.show(ctx);
                },
                child: const Text('OPEN PICKER'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN PICKER'));
      await tester.pumpAndSettle();

      expect(find.text('SEARCH CLOUD CDN VIDEO LIBRARY'), findsOneWidget);
      expect(find.text('VERIFIED CDN (20+)'), findsOneWidget);
      expect(find.text('ONLINE SEARCH (1,300+)'), findsOneWidget);
      expect(find.text('CUSTOM VIDEO URL'), findsOneWidget);
      expect(find.text('Standard Push-Up Form'), findsOneWidget);

      // Search for curl
      await tester.enterText(find.byType(TextField).first, 'curl');
      await tester.pumpAndSettle();

      expect(find.text('Bicep Arm Curl (Dumbbell / Barbell)'), findsOneWidget);
      expect(find.text('Standard Push-Up Form'), findsNothing);

      // Tap Use This Video
      await tester.tap(find.text('Use This Video'));
      await tester.pumpAndSettle();

      expect(selectedItem, isNotNull);
      expect(selectedItem!.id, 'cdn-curl');
      expect(selectedItem!.primaryVideoUrl, contains('curl_form.mp4'));
    });

    testWidgets('CdnVideoPickerDialog allows attaching custom stream via tab', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      CdnVideoItem? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  selectedItem = await CdnVideoPickerDialog.show(ctx);
                },
                child: const Text('OPEN PICKER'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN PICKER'));
      await tester.pumpAndSettle();

      // Switch to CUSTOM VIDEO URL tab
      await tester.tap(find.text('CUSTOM VIDEO URL'));
      await tester.pumpAndSettle();

      expect(find.text('ATTACH DIRECT ONLINE VIDEO STREAM'), findsOneWidget);
      expect(find.text('PRIMARY VIDEO STREAM URL *'), findsOneWidget);

      // Enter stream details
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Machine Chest Press');
      await tester.enterText(textFields.at(1), 'Leverage Machine');
      await tester.enterText(textFields.at(2), 'https://storage.supabase.co/gym/chest_press.mp4');

      await tester.ensureVisible(find.text('Use Custom Stream'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use Custom Stream'));
      await tester.pumpAndSettle();

      expect(selectedItem, isNotNull);
      expect(selectedItem!.title, 'Machine Chest Press');
      expect(selectedItem!.equipment, 'Leverage Machine');
      expect(selectedItem!.primaryVideoUrl, 'https://storage.supabase.co/gym/chest_press.mp4');
    });

    testWidgets('DayExerciseEditorCard in Grid View renders visible ExerciseVideoPreviewThumbnail', (tester) async {
      const exerciseWithVideo = Exercise(
        id: 'test-squat',
        name: 'Barbell Back Squat',
        targetMuscle: 'Legs',
        equipment: 'Barbell',
        videoUrl: 'https://www.youtube.com/watch?v=bEv6CCg2BC8',
      );

      final exerciseItem = WorkoutDayExercise(
        id: 'day-ex-1',
        exercise: exerciseWithVideo,
        orderIndex: 0,
        targetSets: 4,
        targetRepsRange: '8-12',
        restSeconds: 90,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 280,
              child: DayExerciseEditorCard(
                index: 0,
                exerciseItem: exerciseItem,
                isGrid: true,
                onRemove: () {},
                onUpdate: (_, _, _, _) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Barbell Back Squat'), findsOneWidget);
      expect(find.byType(ExerciseVideoPreviewThumbnail), findsOneWidget);
      expect(find.text('YOUTUBE'), findsOneWidget);
    });

    testWidgets('DayExerciseEditorCard in List View renders visible ExerciseVideoPreviewThumbnail', (tester) async {
      const exerciseWithVideo = Exercise(
        id: 'test-bench',
        name: 'Flat Barbell Bench Press',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
        videoUrl: 'https://media.musclewiki.com/media/uploads/videos/branded/male-barbell-bench-press-front.mp4',
      );

      final exerciseItem = WorkoutDayExercise(
        id: 'day-ex-2',
        exercise: exerciseWithVideo,
        orderIndex: 1,
        targetSets: 3,
        targetRepsRange: '10-12',
        restSeconds: 60,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 200,
              child: DayExerciseEditorCard(
                index: 1,
                exerciseItem: exerciseItem,
                isGrid: false,
                onRemove: () {},
                onUpdate: (_, _, _, _) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Flat Barbell Bench Press'), findsOneWidget);
      expect(find.byType(ExerciseVideoPreviewThumbnail), findsOneWidget);
      expect(find.text('MUSCLEWIKI'), findsOneWidget);
    });
  });
}
