import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/workout/data/musclewiki_service.dart';

void main() {
  group('MuscleWiki API & Video Parsing Tests', () {
    test('Correctly extracts front and side video URLs from raw MuscleWiki video data', () {
      final ex = MuscleWikiExercise(
        id: 101,
        name: 'Barbell Bicep Curl',
        primaryMuscles: ['Biceps'],
        category: 'Barbell',
        videos: [
          MuscleWikiVideo(
            url: 'https://media.musclewiki.com/media/uploads/videos/branded/male-Barbell-barbell-curl-front.mp4',
            angle: 'front',
            gender: 'male',
          ),
          MuscleWikiVideo(
            url: 'https://media.musclewiki.com/media/uploads/videos/branded/male-Barbell-barbell-curl-side.mp4',
            angle: 'side',
            gender: 'male',
          ),
          MuscleWikiVideo(
            url: 'https://media.musclewiki.com/media/uploads/videos/branded/female-Barbell-barbell-curl-front.mp4',
            angle: 'front',
            gender: 'female',
          ),
          MuscleWikiVideo(
            url: 'https://media.musclewiki.com/media/uploads/videos/branded/female-Barbell-barbell-curl-side.mp4',
            angle: 'side',
            gender: 'female',
          ),
        ],
      );

      // Verify Male Front angle (User's specific requirement: "sirf front")
      final maleFront = ex.getFrontVideoUrl(gender: 'male');
      expect(maleFront, contains('-front.mp4'));
      expect(maleFront, contains('male-'));

      // Verify Male Side angle
      final maleSide = ex.getSideVideoUrl(gender: 'male');
      expect(maleSide, contains('-side.mp4'));
      expect(maleSide, contains('male-'));

      // Verify Female Front angle
      final femaleFront = ex.getFrontVideoUrl(gender: 'female');
      expect(femaleFront, contains('-front.mp4'));
      expect(femaleFront, contains('female-'));

      // Verify Female Side angle
      final femaleSide = ex.getSideVideoUrl(gender: 'female');
      expect(femaleSide, contains('-side.mp4'));
      expect(femaleSide, contains('female-'));
    });

    test('Parses MuscleWiki JSON format with video list and steps', () {
      final sampleJson = {
        'id': 205,
        'name': 'Dumbbell Incline Bench Press',
        'category': 'Dumbbell',
        'primary_muscles': ['Chest', 'Upper Chest'],
        'secondary_muscles': ['Triceps', 'Front Shoulders'],
        'difficulty': 'Intermediate',
        'steps': [
          'Lie back on an incline bench at a 30-45 degree angle.',
          'Press the dumbbells upwards until arms are extended.',
          'Lower slowly to chest level and repeat.',
        ],
        'videos': [
          {
            'url': 'https://media.musclewiki.com/media/uploads/videos/branded/male-Dumbbell-incline-press-front.mp4',
            'angle': 'front',
            'gender': 'male',
          },
          {
            'url': 'https://media.musclewiki.com/media/uploads/videos/branded/male-Dumbbell-incline-press-side.mp4',
            'angle': 'side',
            'gender': 'male',
          },
        ],
      };

      final parsed = MuscleWikiExercise.fromJson(sampleJson);
      expect(parsed.id, 205);
      expect(parsed.name, 'Dumbbell Incline Bench Press');
      expect(parsed.category, 'Dumbbell');
      expect(parsed.primaryMuscles.first, 'Chest');
      expect(parsed.steps.length, 3);
      expect(parsed.videos.length, 2);
      expect(parsed.getFrontVideoUrl(), isNotNull);
      expect(parsed.getSideVideoUrl(), isNotNull);
    });

    test('MuscleWikiService searches and filters verified catalog without network dependency', () async {
      final service = MuscleWikiService();

      // Search for curl
      final curlResults = await service.searchExercises(query: 'curl');
      expect(curlResults.isNotEmpty, isTrue);
      expect(curlResults.any((e) => e.name.toLowerCase().contains('curl')), isTrue);

      // Search for chest / bench press
      final benchResults = await service.searchExercises(query: 'bench');
      expect(benchResults.isNotEmpty, isTrue);
      expect(benchResults.any((e) => e.name.toLowerCase().contains('bench')), isTrue);

      // Filter by muscle
      final backResults = await service.searchExercises(query: '', muscle: 'Back');
      expect(backResults.isNotEmpty, isTrue);
      for (final ex in backResults) {
        final matches = ex.primaryMuscles.any((m) => m.toLowerCase().contains('back') || m.toLowerCase().contains('lat'));
        expect(matches, isTrue);
      }
    });

    test('MuscleWikiService caches queries on client-side to prevent exceeding API limits', () async {
      final service = MuscleWikiService();
      final initialSaved = service.apiCallsSaved;

      // First query (populates cache)
      final res1 = await service.searchExercises(query: 'squat', muscle: 'Legs');
      expect(res1.isNotEmpty, isTrue);

      // Second identical query (served directly from client-side memory cache, zero API calls)
      final res2 = await service.searchExercises(query: 'squat', muscle: 'Legs');
      expect(res2.length, equals(res1.length));
      expect(service.apiCallsSaved, greaterThan(initialSaved));
    });
  });
}
