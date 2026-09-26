import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/super_admin/presentation/desktop/widgets/add_edit_exercise_video_dialog.dart';
import 'package:gym_connect_app/features/workout/data/online_exercise_video_service.dart';
import 'package:gym_connect_app/features/workout/data/workout_repository.dart';
import 'package:gym_connect_app/features/workout/data/youtube_video_utils.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/attach_exercise_video_sheet.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/fullscreen_video_dialog.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/pip_player_overlay.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/youtube_embed_player.dart';

void main() {
  group('YouTube URL Detection & Regex Tests', () {
    test('isYouTubeUrl returns true for standard watch URLs', () {
      expect(
        YoutubeVideoUtils.isYouTubeUrl(
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        isTrue,
      );
      expect(
        YoutubeVideoUtils.isYouTubeUrl('http://youtube.com/watch?v=dQw4w9WgXcQ'),
        isTrue,
      );
    });

    test('isYouTubeUrl returns true for youtu.be short links', () {
      expect(
        YoutubeVideoUtils.isYouTubeUrl('https://youtu.be/dQw4w9WgXcQ'),
        isTrue,
      );
      expect(
        YoutubeVideoUtils.isYouTubeUrl('http://youtu.be/dQw4w9WgXcQ?t=15s'),
        isTrue,
      );
    });

    test('isYouTubeUrl returns true for YouTube Shorts', () {
      expect(
        YoutubeVideoUtils.isYouTubeUrl(
            'https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        isTrue,
      );
    });

    test('isShorts returns true for Shorts URLs and false for standard URLs', () {
      expect(
        YoutubeVideoUtils.isShorts('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        isTrue,
      );
      expect(
        YoutubeVideoUtils.isShorts('http://youtube.com/shorts/rT7DgCr-3pg?feature=share'),
        isTrue,
      );
      expect(
        YoutubeVideoUtils.isShorts('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        isFalse,
      );
      expect(
        YoutubeVideoUtils.isShorts('https://youtu.be/dQw4w9WgXcQ'),
        isFalse,
      );
      expect(YoutubeVideoUtils.isShorts(null), isFalse);
    });

    test('isYouTubeUrl returns true for YouTube Embed URLs', () {
      expect(
        YoutubeVideoUtils.isYouTubeUrl(
            'https://www.youtube.com/embed/dQw4w9WgXcQ'),
        isTrue,
      );
      expect(
        YoutubeVideoUtils.isYouTubeUrl(
            'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ'),
        isTrue,
      );
    });

    test('isYouTubeUrl returns true for mobile YouTube links', () {
      expect(
        YoutubeVideoUtils.isYouTubeUrl(
            'https://m.youtube.com/watch?v=dQw4w9WgXcQ'),
        isTrue,
      );
    });

    test('isYouTubeUrl returns false for non-YouTube URLs', () {
      expect(YoutubeVideoUtils.isYouTubeUrl(null), isFalse);
      expect(YoutubeVideoUtils.isYouTubeUrl(''), isFalse);
      expect(
        YoutubeVideoUtils.isYouTubeUrl(
            'https://cdn.example.com/videos/squat.mp4'),
        isFalse,
      );
      expect(
        YoutubeVideoUtils.isYouTubeUrl('https://vimeo.com/123456789'),
        isFalse,
      );
      expect(
        YoutubeVideoUtils.isYouTubeUrl(
            'https://cdn.jsdelivr.net/gh/user/repo@main/video.mp4'),
        isFalse,
      );
    });
  });

  group('YouTube Video ID Extraction Tests', () {
    const expectedId = 'dQw4w9WgXcQ';

    test('extracts ID from standard watch URL', () {
      expect(
        YoutubeVideoUtils.extractVideoId(
            'https://www.youtube.com/watch?v=$expectedId'),
        expectedId,
      );
    });

    test('extracts ID from watch URL with extra query params', () {
      expect(
        YoutubeVideoUtils.extractVideoId(
            'https://www.youtube.com/watch?v=$expectedId&feature=share&t=42s'),
        expectedId,
      );
    });

    test('extracts ID from youtu.be short link', () {
      expect(
        YoutubeVideoUtils.extractVideoId('https://youtu.be/$expectedId'),
        expectedId,
      );
    });

    test('extracts ID from YouTube Shorts URL', () {
      expect(
        YoutubeVideoUtils.extractVideoId(
            'https://www.youtube.com/shorts/$expectedId'),
        expectedId,
      );
    });

    test('extracts ID from YouTube embed link', () {
      expect(
        YoutubeVideoUtils.extractVideoId(
            'https://www.youtube.com/embed/$expectedId'),
        expectedId,
      );
    });

    test('returns null for non-YouTube or invalid URLs', () {
      expect(YoutubeVideoUtils.extractVideoId('https://example.com/video.mp4'),
          isNull);
      expect(YoutubeVideoUtils.extractVideoId(''), isNull);
      expect(YoutubeVideoUtils.extractVideoId(null), isNull);
    });
  });

  group('YouTube Embed URL Transformation Tests', () {
    const testId = 'dQw4w9WgXcQ';
    const testUrl = 'https://www.youtube.com/watch?v=$testId';

    test('toEmbedUrl transforms into copyright-safe youtube-nocookie embed', () {
      final embed = YoutubeVideoUtils.toEmbedUrl(testUrl);

      expect(embed, startsWith('https://www.youtube-nocookie.com/embed/$testId?'));
      expect(embed, contains('autoplay=1'));
      expect(embed, contains('mute=1'));
      expect(embed, contains('loop=1'));
      expect(embed, contains('playlist=$testId'));
      expect(embed, contains('controls=0'));
      expect(embed, contains('rel=0'));
      expect(embed, contains('playsinline=1'));
      expect(embed, contains('disablekb=1'));
      expect(embed, contains('fs=0'));

      final embedWithControls = YoutubeVideoUtils.toEmbedUrl(testUrl, showControls: true);
      expect(embedWithControls, contains('controls=1'));
    });

    test('toEmbedUrl handles optional flags properly', () {
      final embedNoAutoplay = YoutubeVideoUtils.toEmbedUrl(
        testUrl,
        autoPlay: false,
        loop: false,
        mute: false,
      );

      expect(embedNoAutoplay, contains('autoplay=0'));
      expect(embedNoAutoplay, contains('mute=0'));
      expect(embedNoAutoplay, isNot(contains('loop=1')));
      expect(embedNoAutoplay, isNot(contains('playlist=')));
    });

    test('toEmbedUrl returns original string if not a YouTube URL', () {
      const nonYt = 'https://cdn.example.com/stream.mp4';
      expect(YoutubeVideoUtils.toEmbedUrl(nonYt), nonYt);
    });

    test('getThumbnailUrl returns correct thumbnail URLs', () {
      final hqThumb = YoutubeVideoUtils.getThumbnailUrl(testUrl);
      expect(hqThumb, 'https://img.youtube.com/vi/$testId/hqdefault.jpg');

      final maxThumb = YoutubeVideoUtils.getThumbnailUrl(testUrl, highRes: true);
      expect(maxThumb, 'https://img.youtube.com/vi/$testId/maxresdefault.jpg');
    });
  });

  group('OnlineExerciseVideoService YouTube Integration Tests', () {
    test('createCustomItem automatically converts YouTube URL to embed format', () {
      final service = OnlineExerciseVideoService.instance;
      final item = service.createCustomItem(
        title: 'Barbell Bench Press Form',
        primaryVideoUrl: 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
        sideVideoUrl: 'https://youtu.be/4Y2ZdHCOXok',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
      );

      expect(item.primaryVideoUrl,
          startsWith('https://www.youtube-nocookie.com/embed/rT7DgCr-3pg?'));
      expect(item.primaryVideoUrl, contains('autoplay=1'));
      expect(item.primaryVideoUrl, contains('loop=1'));
      expect(item.primaryVideoUrl, contains('playlist=rT7DgCr-3pg'));

      expect(item.sideVideoUrl,
          startsWith('https://www.youtube-nocookie.com/embed/4Y2ZdHCOXok?'));
      expect(item.cdnProvider, contains('YouTube Embed API'));
      expect(item.quality, contains('YouTube HD Auto-Loop'));
    });

    test('createCustomItem leaves regular MP4 stream URLs untouched', () {
      final service = OnlineExerciseVideoService.instance;
      const mp4Url = 'https://cdn.example.com/videos/squat.mp4';
      final item = service.createCustomItem(
        title: 'Squat Stream',
        primaryVideoUrl: mp4Url,
      );

      expect(item.primaryVideoUrl, mp4Url);
      expect(item.cdnProvider, 'Custom Web / Cloud Stream');
    });
  });

  group('YouTube UI Widget Tests', () {
    testWidgets('YoutubeEmbedPlayer shows error placeholder for invalid link',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YoutubeEmbedPlayer(videoUrl: 'https://invalid-url.com'),
          ),
        ),
      );

      expect(find.text('Invalid YouTube Link'), findsOneWidget);
    });

    testWidgets('FullscreenVideoDialog detects YouTube URL and shows EMBED badge',
        (tester) async {
      const exercise = Exercise(
        id: 'ex-yt-1',
        name: 'Incline Bench Press',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        tips: 'Keep scapulae retracted.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FullscreenVideoDialog.show(context, exercise),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check dialog header & YouTube badge
      expect(find.text('INCLINE BENCH PRESS'), findsOneWidget);
      expect(find.text('🔴 YOUTUBE EMBED • AUTOPLAY LOOP'), findsOneWidget);
      expect(find.byType(YoutubeEmbedPlayer), findsOneWidget);
      expect(find.text('VIDEO ASPECT RATIO'), findsOneWidget);
      expect(find.text('9:16 SHORTS'), findsOneWidget);
      expect(find.text('16:9 WIDE'), findsOneWidget);
    });

    testWidgets('AddEditExerciseVideoDialog shows YouTube detection card when YouTube link is entered',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const initialExercise = Exercise(
        id: 'test-edit',
        name: 'Incline Dumbbell Press',
        targetMuscle: 'Chest',
        equipment: 'Dumbbell',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddEditExerciseVideoDialog(initialExercise: initialExercise),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should find YouTube Detected card
      expect(find.text('YOUTUBE DETECTED'), findsOneWidget);
      expect(find.text('COPYRIGHT-SAFE EMBED'), findsOneWidget);
      expect(find.text('Auto-Embed\n& Loop'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('AttachExerciseVideoSheet shows YouTube detection card when YouTube link is present',
        (tester) async {
      const exercise = Exercise(
        id: 'test-mobile-sheet',
        name: 'Leg Press 45',
        targetMuscle: 'Legs',
        equipment: 'Machine',
        videoUrl: 'https://youtu.be/dQw4w9WgXcQ',
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

      expect(find.text('YOUTUBE DETECTED'), findsOneWidget);
      expect(find.text('SAFE EMBED'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    test('updateExerciseInProtocol updates workingDays by name and syncs to mobile routine', () async {
      const repo = WorkoutRepository(null);
      const updatedExercise = Exercise(
        id: 'uuid-real-bench',
        name: 'Flat Barbell Bench Press',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
        videoUrl: 'https://www.youtube-nocookie.com/embed/rT7DgCr-3pg?autoplay=1&mute=1&loop=1',
      );

      // Save via repository
      await repo.saveOrUpdateExercise(updatedExercise);

      // Retrieve routine as mobile app does
      final mobileRoutine = await repo.getTodayRoutine(dayNumber: 1, bodyType: 'ectomorph');
      final benchEx = mobileRoutine.exercises.firstWhere((e) => e.exercise.name == 'Flat Barbell Bench Press');

      expect(benchEx.exercise.videoUrl, contains('youtube-nocookie.com/embed/rT7DgCr-3pg'));
      expect(benchEx.exercise.videoUrl, contains('autoplay=1'));
    });

    testWidgets('PipPlayerOverlay hides angle button when hasSideAngle is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PipPlayerOverlay(
              isFrontAngle: true,
              hasSideAngle: false,
              onToggleAngle: () {},
              onExpand: () {},
            ),
          ),
        ),
      );

      expect(find.text('SIDE VIEW'), findsNothing);
      expect(find.text('FRONT VIEW'), findsNothing);
      expect(find.byIcon(Icons.flip_camera_android_rounded), findsNothing);
      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
    });

    testWidgets('PipPlayerOverlay shows angle button when hasSideAngle is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PipPlayerOverlay(
              isFrontAngle: true,
              hasSideAngle: true,
              onToggleAngle: () {},
              onExpand: () {},
            ),
          ),
        ),
      );

      expect(find.text('SIDE VIEW'), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_android_rounded), findsOneWidget);
    });

    testWidgets('FullscreenVideoDialog hides side button when sideVideoUrl is null',
        (tester) async {
      const exerciseNoSide = Exercise(
        id: 'no-side-1',
        name: 'Standing Biceps Curl',
        targetMuscle: 'Arms',
        equipment: 'Dumbbell',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        sideVideoUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FullscreenVideoDialog.show(context, exerciseNoSide),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('CAMERA ANGLE'), findsNothing);
      expect(find.text('SIDE'), findsNothing);
    });

    testWidgets('FullscreenVideoDialog shows side button when sideVideoUrl is provided',
        (tester) async {
      const exerciseWithSide = Exercise(
        id: 'with-side-1',
        name: 'Barbell Back Squat',
        targetMuscle: 'Legs',
        equipment: 'Barbell',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        sideVideoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FullscreenVideoDialog.show(context, exerciseWithSide),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('CAMERA ANGLE'), findsOneWidget);
      expect(find.text('SIDE'), findsOneWidget);
      expect(find.text('FRONT'), findsOneWidget);
    });
  });
}


