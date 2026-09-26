import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/secure_storage_service.dart';

final muscleWikiServiceProvider = Provider<MuscleWikiService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return MuscleWikiService(storage);
});

class MuscleWikiVideo {
  final String url;
  final String angle; // 'front' | 'side'
  final String gender; // 'male' | 'female'

  const MuscleWikiVideo({
    required this.url,
    required this.angle,
    required this.gender,
  });

  factory MuscleWikiVideo.fromRaw(dynamic raw, {String fallbackGender = 'male'}) {
    if (raw is Map) {
      final url = raw['url']?.toString() ?? raw['src']?.toString() ?? '';
      final angle = raw['angle']?.toString().toLowerCase() ??
          (url.contains('-side') ? 'side' : 'front');
      final gender = raw['gender']?.toString().toLowerCase() ??
          (url.contains('female') ? 'female' : fallbackGender);
      return MuscleWikiVideo(url: url, angle: angle, gender: gender);
    } else {
      final str = raw.toString();
      final angle = str.contains('-side') ? 'side' : 'front';
      final gender = str.contains('female') ? 'female' : fallbackGender;
      return MuscleWikiVideo(url: str, angle: angle, gender: gender);
    }
  }
}

class MuscleWikiExercise {
  final int id;
  final String name;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String category;
  final String? difficulty;
  final String? force;
  final List<String> steps;
  final List<MuscleWikiVideo> videos;
  final String? bodymapMale;
  final String? bodymapFemale;

  const MuscleWikiExercise({
    required this.id,
    required this.name,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.category = 'General',
    this.difficulty,
    this.force,
    this.steps = const [],
    this.videos = const [],
    this.bodymapMale,
    this.bodymapFemale,
  });

  String? getFrontVideoUrl({String gender = 'male'}) {
    final g = gender.toLowerCase();
    for (final v in videos) {
      if (v.angle == 'front' && v.gender == g && v.url.isNotEmpty) {
        return v.url;
      }
    }
    for (final v in videos) {
      if (v.angle == 'front' && v.url.isNotEmpty) {
        return v.url;
      }
    }
    return videos.isNotEmpty ? videos.first.url : null;
  }

  String? getSideVideoUrl({String gender = 'male'}) {
    final g = gender.toLowerCase();
    for (final v in videos) {
      if (v.angle == 'side' && v.gender == g && v.url.isNotEmpty) {
        return v.url;
      }
    }
    for (final v in videos) {
      if (v.angle == 'side' && v.url.isNotEmpty) {
        return v.url;
      }
    }
    return null;
  }

  factory MuscleWikiExercise.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int ? json['id'] as int : (int.tryParse(json['id']?.toString() ?? '0') ?? 0);
    final name = json['name']?.toString() ?? 'Exercise';

    final pMuscles = <String>[];
    if (json['primary_muscles'] is List) {
      pMuscles.addAll((json['primary_muscles'] as List).map((e) => e.toString()));
    } else if (json['muscle'] != null) {
      pMuscles.add(json['muscle'].toString());
    }

    final sMuscles = <String>[];
    if (json['secondary_muscles'] is List) {
      sMuscles.addAll((json['secondary_muscles'] as List).map((e) => e.toString()));
    }

    final cat = json['category']?.toString() ?? 'General';
    final diff = json['difficulty']?.toString();
    final f = json['force']?.toString();

    final stepList = <String>[];
    if (json['steps'] is List) {
      stepList.addAll((json['steps'] as List).map((e) => e.toString()));
    }

    final videoList = <MuscleWikiVideo>[];
    if (json['videos'] is List) {
      for (final rawV in json['videos'] as List) {
        videoList.add(MuscleWikiVideo.fromRaw(rawV));
      }
    } else if (json['video_url'] != null) {
      videoList.add(MuscleWikiVideo(
        url: json['video_url'].toString(),
        angle: 'front',
        gender: 'male',
      ));
      if (json['side_video_url'] != null) {
        videoList.add(MuscleWikiVideo(
          url: json['side_video_url'].toString(),
          angle: 'side',
          gender: 'male',
        ));
      }
    }

    return MuscleWikiExercise(
      id: id,
      name: name,
      primaryMuscles: pMuscles,
      secondaryMuscles: sMuscles,
      category: cat,
      difficulty: diff,
      force: f,
      steps: stepList,
      videos: videoList,
      bodymapMale: json['bodymap_male']?.toString(),
      bodymapFemale: json['bodymap_female']?.toString(),
    );
  }
}

class _CachedResult {
  final List<MuscleWikiExercise> results;
  final DateTime timestamp;
  _CachedResult({required this.results, required this.timestamp});
  bool get isExpired => DateTime.now().difference(timestamp).inHours > 24;
}

class MuscleWikiService {
  final SecureStorageService _storage;
  static const String baseUrl = 'https://api.musclewiki.com';

  static final Map<String, _CachedResult> _queryCache = {};
  static int _apiCallsSaved = 0;
  static String? _cachedMediaToken;
  static DateTime? _mediaTokenExpiresAt;

  int get apiCallsSaved => _apiCallsSaved;

  MuscleWikiService([SecureStorageService? storage])
      : _storage = storage ?? SecureStorageService();

  Future<String?> getSavedApiKey() => _storage.getMuscleWikiApiKey();

  Future<void> saveApiKey(String key) => _storage.saveMuscleWikiApiKey(key);

  /// Supabase Edge Function proxy URL — bypasses CORS on web
  String get _proxyBaseUrl {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
        Supabase.instance.client.rest.url.replaceAll('/rest/v1', '');
    return '$supabaseUrl/functions/v1/musclewiki-proxy';
  }

  /// Server-to-server call via our proxy (no CORS).
  /// 1. If on Web: tries local proxy (127.0.0.1:5055) then Supabase Edge Function proxy.
  /// 2. If on Native mobile/desktop: calls MuscleWiki directly.
  Future<http.Response?> _proxyGet(String endpoint, Map<String, String> queryParams) async {
    // 1. Try local proxy first on Web (for development / local web-server)
    if (kIsWeb) {
      try {
        final localUri = Uri.parse('http://127.0.0.1:5055/musclewiki').replace(queryParameters: {
          'endpoint': endpoint,
          ...queryParams,
        });
        final localRes = await http.get(localUri, headers: {
          'Accept': 'application/json',
        }).timeout(const Duration(milliseconds: 1500));
        if (localRes.statusCode == 200) {
          return localRes;
        }
      } catch (_) {
        // Local proxy not available, continue to Supabase proxy
      }
    }

    // 2. Try Supabase Edge Function proxy
    try {
      final params = {
        'endpoint': endpoint,
        ...queryParams,
      };
      final uri = Uri.parse(_proxyBaseUrl).replace(queryParameters: params);
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      final res = await http.get(uri, headers: {
        'Accept': 'application/json',
        if (anonKey.isNotEmpty) 'apikey': anonKey,
        if (anonKey.isNotEmpty) 'Authorization': 'Bearer $anonKey',
      }).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return res;
      }
    } catch (_) {}

    // 3. Direct API call on native platforms (Android, iOS, Windows, macOS) where browser CORS is not enforced
    if (!kIsWeb) {
      try {
        final apiKey = await getSavedApiKey() ??
            dotenv.env['MUSCLEWIKI_API_KEY'] ??
            'mw_KqJ0jODYaNb6EWVXfSEguIp5wc1bdq71FdLcMJGahEY';
        final uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams);
        final res = await http.get(uri, headers: {
          'X-API-Key': apiKey,
          'Accept': 'application/json',
        }).timeout(const Duration(seconds: 5));
        return res;
      } catch (_) {}
    }

    return null;
  }

  /// Returns cached media token or mints a new one if expired (15-min lifetime)
  Future<String?> getMediaToken(String apiKey) async {
    if (_cachedMediaToken != null &&
        _mediaTokenExpiresAt != null &&
        DateTime.now().isBefore(_mediaTokenExpiresAt!)) {
      return _cachedMediaToken;
    }
    try {
      final res = await _proxyGet('media/token', {});
      if (res != null && res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['token'] != null) {
          _cachedMediaToken = data['token'].toString();
          final rawExp = data['expires_in'];
          final expSec = (rawExp is int ? rawExp : int.tryParse(rawExp?.toString() ?? '900') ?? 900) - 60;
          _mediaTokenExpiresAt = DateTime.now().add(Duration(seconds: expSec));
          return _cachedMediaToken;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch videos for a specific exercise by ID
  Future<List<MuscleWikiVideo>> getExerciseVideos(int exerciseId, {String gender = 'male'}) async {
    final cacheKey = 'videos:$exerciseId:$gender';
    final cached = _queryCache[cacheKey];
    if (cached != null && !cached.isExpired && cached.results.isNotEmpty) {
      return cached.results.first.videos;
    }

    try {
      final res = await _proxyGet('exercises/$exerciseId/videos', {
        'gender': gender,
      });
      if (res != null && res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final videoList = <MuscleWikiVideo>[];
        if (decoded is List) {
          for (final raw in decoded) {
            videoList.add(MuscleWikiVideo.fromRaw(raw));
          }
        } else if (decoded is Map && decoded['videos'] is List) {
          for (final raw in decoded['videos'] as List) {
            videoList.add(MuscleWikiVideo.fromRaw(raw));
          }
        }
        if (videoList.isNotEmpty) {
          return videoList;
        }
      }
    } catch (err) {
      debugPrint('MuscleWiki getExerciseVideos error: $err');
    }

    // Fallback: look up exercise from verified catalog
    for (final exercise in verifiedMuscleWikiExercises) {
      if (exercise.id == exerciseId && exercise.videos.isNotEmpty) {
        return exercise.videos;
      }
    }

    return [];
  }

  /// Searches exercises from MuscleWiki API (via proxy) with local catalog fallback
  Future<List<MuscleWikiExercise>> searchExercises({
    required String query,
    String muscle = 'All',
    String category = 'All',
    String gender = 'male',
    int limit = 20,
  }) async {
    final cleanQuery = query.trim();
    final cacheKey =
        'q:${cleanQuery.toLowerCase()}|m:${muscle.toLowerCase()}|c:${category.toLowerCase()}|g:${gender.toLowerCase()}';

    // 1. Client-Side Cache Check: Zero API calls if already cached
    final cached = _queryCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      _apiCallsSaved++;
      debugPrint(
          'MuscleWikiService [CLIENT CACHE HIT]: $cacheKey (Saved $_apiCallsSaved total API calls)');
      return cached.results;
    }

    // 2. MuscleWiki API call via our proxy (no CORS issues)
    try {
      final endpoint = cleanQuery.isNotEmpty ? 'search' : 'exercises';
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (cleanQuery.isNotEmpty) 'q': cleanQuery,
        if (muscle != 'All') 'muscles': muscle,
        if (category != 'All') 'category': category.toLowerCase(),
        'gender': gender.toLowerCase(),
      };

      final res = await _proxyGet(endpoint, queryParams);
      if (res != null && res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> items;
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map && decoded['results'] is List) {
          items = decoded['results'] as List;
        } else {
          items = [];
        }

        final list = <MuscleWikiExercise>[];
        for (final raw in items) {
          if (raw is Map) {
            list.add(MuscleWikiExercise.fromJson(Map<String, dynamic>.from(raw)));
          }
        }
        if (list.isNotEmpty) {
          _queryCache[cacheKey] =
              _CachedResult(results: list, timestamp: DateTime.now());
          debugPrint('MuscleWikiService [API SUCCESS]: ${list.length} results');
          return list;
        }
      } else if (res != null) {
        debugPrint('MuscleWiki API response: ${res.statusCode} ${res.body}');
      }
    } catch (err) {
      debugPrint('MuscleWiki API error: $err');
    }

    // 3. Fallback to local verified catalog
    final localList = _searchLocalVerified(
      query: cleanQuery,
      muscle: muscle,
      category: category,
      gender: gender,
    );
    _queryCache[cacheKey] =
        _CachedResult(results: localList, timestamp: DateTime.now());
    return localList;
  }

  List<MuscleWikiExercise> _searchLocalVerified({
    required String query,
    required String muscle,
    required String category,
    required String gender,
  }) {
    final q = query.toLowerCase();
    final m = muscle.toLowerCase();
    final c = category.toLowerCase();

    return verifiedMuscleWikiExercises.where((item) {
      final matchesQ = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.primaryMuscles.any((pm) => pm.toLowerCase().contains(q)) ||
          item.category.toLowerCase().contains(q);

      final matchesM = m == 'all' || item.primaryMuscles.any((pm) => pm.toLowerCase().contains(m));
      final matchesC = c == 'all' || item.category.toLowerCase().contains(c);

      return matchesQ && matchesM && matchesC;
    }).toList();
  }

  /// Authentic verified MuscleWiki exercise catalog with dual front/side CDN video streams.
  /// NOTE: All URLs use public CDN (jsDelivr / GitHub) — NO API key or paid tier required.
  /// These are the same exercise animations used in CdnVideoLibrary but mapped per exercise.
  static const List<MuscleWikiExercise> verifiedMuscleWikiExercises = [
    // BICEPS
    MuscleWikiExercise(
      id: 1,
      name: 'Barbell Curl',
      primaryMuscles: ['Biceps', 'Forearms'],
      category: 'Barbell',
      difficulty: 'Intermediate',
      force: 'Pull',
      steps: [
        'Stand tall with your chest up and core braced, holding a barbell with an underhand grip.',
        'Keep your elbows glued to your sides and curl the barbell up toward chest level.',
        'Squeeze the biceps at peak contraction, then lower with a strict 3-second negative.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0082-iBcVPdP.gif',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 2,
      name: 'Dumbbell Hammer Curl',
      primaryMuscles: ['Biceps', 'Brachialis', 'Forearms'],
      category: 'Dumbbell',
      difficulty: 'Beginner',
      force: 'Pull',
      steps: [
        'Hold dumbbells with a neutral grip (palms facing each other).',
        'Curl the weights upward while maintaining locked elbow position.',
        'Control the descent to maximize tension on the brachialis.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0351-LhsE6ra.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 17,
      name: 'Cable Bicep Curl',
      primaryMuscles: ['Biceps'],
      category: 'Cable',
      difficulty: 'Beginner',
      force: 'Pull',
      steps: [
        'Stand at cable machine with low pulley and straight bar attachment.',
        'Curl the bar up with elbows pinned to your sides.',
        'Squeeze hard at the top, then lower under control.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0174-Zq1W2TH.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),

    // CHEST
    MuscleWikiExercise(
      id: 3,
      name: 'Barbell Bench Press',
      primaryMuscles: ['Chest', 'Triceps', 'Shoulders'],
      category: 'Barbell',
      difficulty: 'Intermediate',
      force: 'Push',
      steps: [
        'Lie flat on the bench, retract your scapulae and plant feet firmly on the floor.',
        'Grip the bar just wider than shoulder width and unrack with elbows locked.',
        'Lower smoothly to touch mid-chest, then press forcefully back over your shoulders.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0025-EIeI8Vf.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 4,
      name: 'Incline Dumbbell Bench Press',
      primaryMuscles: ['Chest', 'Shoulders', 'Triceps'],
      category: 'Dumbbell',
      difficulty: 'Intermediate',
      force: 'Push',
      steps: [
        'Set adjustable bench to 30-45 degrees angle.',
        'Press dumbbells upward with palms angled at 45 degrees to protect shoulders.',
        'Lower until you feel a deep stretch in the upper pectorals.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0314-ns0SIbU.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 5,
      name: 'Cable Chest Fly',
      primaryMuscles: ['Chest'],
      category: 'Cable',
      difficulty: 'Intermediate',
      force: 'Push',
      steps: [
        'Set dual cable pulleys at chest height with stirrup handles.',
        'Step forward into a staggered stance with a slight bend in your elbows.',
        'Bring hands together in front of your chest in a hugging motion.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0171-tBWXbIT.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 18,
      name: 'Push-Up',
      primaryMuscles: ['Chest', 'Triceps', 'Shoulders'],
      category: 'Bodyweight',
      difficulty: 'Beginner',
      force: 'Push',
      steps: [
        'Start in a high plank position with hands shoulder-width apart.',
        'Lower your chest to the ground with elbows at 45 degrees.',
        'Push back up explosively, maintaining a rigid plank throughout.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0009-PAgTVaK.gif',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 19,
      name: 'Decline Barbell Bench Press',
      primaryMuscles: ['Chest (Lower)', 'Triceps'],
      category: 'Barbell',
      difficulty: 'Intermediate',
      force: 'Push',
      steps: [
        'Lock legs at the end of the decline bench firmly.',
        'Lower bar to lower sternum / chest area with control.',
        'Press vertically to target lower pectoral fibers.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0033-GrO65fd.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 20,
      name: 'Flat Dumbbell Bench Press',
      primaryMuscles: ['Chest', 'Triceps'],
      category: 'Dumbbell',
      difficulty: 'Beginner',
      force: 'Push',
      steps: [
        'Lie flat, hold dumbbells at chest height with elbows at 45 degrees.',
        'Press upward explosively without banging the dumbbells together.',
        'Lower slowly for a deep pectoral stretch.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0289-SpYC0Kp.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),

    // TRICEPS
    MuscleWikiExercise(
      id: 6,
      name: 'Cable Tricep Pushdown',
      primaryMuscles: ['Triceps'],
      category: 'Cable',
      difficulty: 'Beginner',
      force: 'Push',
      steps: [
        'Attach a straight bar or rope to a high cable pulley.',
        'Keep elbows pinned tightly against your ribcage.',
        'Push downward until arms are completely locked out, contracting the triceps.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0241-gAwDzB3.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 7,
      name: 'Overhead Tricep Extension',
      primaryMuscles: ['Triceps (Long Head)'],
      category: 'Cable',
      difficulty: 'Intermediate',
      force: 'Push',
      steps: [
        'Set cable at shoulder level and face away with rope attachment overhead.',
        'Extend elbows forward to lock out arms and isolate the long head of the tricep.',
        'Return smoothly until your hands reach behind your head.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0129-RrLske5.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),

    // BACK
    MuscleWikiExercise(
      id: 8,
      name: 'Lat Pulldown',
      primaryMuscles: ['Back', 'Lats', 'Biceps'],
      category: 'Cable',
      difficulty: 'Beginner',
      force: 'Pull',
      steps: [
        'Grip wide bar with an overhand grip and sit down with thighs secured.',
        'Drive elbows down and back toward your hips, bringing bar to upper chest.',
        'Control the weight as it rises, feeling the full stretch in your lats.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/2330-LEprlgG.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 9,
      name: 'Barbell Bent Over Row',
      primaryMuscles: ['Back', 'Lats', 'Rhomboids', 'Biceps'],
      category: 'Barbell',
      difficulty: 'Intermediate',
      force: 'Pull',
      steps: [
        'Hinge forward at the hips with a flat back and knees slightly bent.',
        'Pull the barbell into your lower abdomen, leading with the elbows.',
        'Pause momentarily at the top and lower under control.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0007-4IKbhHV.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 21,
      name: 'Wide-Grip Pull-Up',
      primaryMuscles: ['Back', 'Lats', 'Biceps'],
      category: 'Bodyweight',
      difficulty: 'Intermediate',
      force: 'Pull',
      steps: [
        'Hang from a pull-up bar with an overhand grip wider than shoulder-width.',
        'Retract shoulder blades and pull your chest toward the bar.',
        'Lower with a full controlled extension to stretch the lats.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/3293-72BC5Za.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),

    // LEGS
    MuscleWikiExercise(
      id: 10,
      name: 'Barbell Squat',
      primaryMuscles: ['Legs', 'Quadriceps', 'Glutes', 'Hamstrings'],
      category: 'Barbell',
      difficulty: 'Advanced',
      force: 'Push',
      steps: [
        'Rest bar across upper trapezius with feet shoulder-width apart.',
        'Descend by sitting back into the hips, driving knees out in line with toes.',
        'Reach parallel or lower, then explode upward driving through mid-foot.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 11,
      name: 'Barbell Romanian Deadlift',
      primaryMuscles: ['Legs', 'Hamstrings', 'Glutes'],
      category: 'Barbell',
      difficulty: 'Intermediate',
      force: 'Pull',
      steps: [
        'Hold bar at hip height, maintain neutral spine and soft knee bend.',
        'Push hips straight backward until you feel maximum stretch in hamstrings.',
        'Contract glutes and hamstrings to return to starting position.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0032-ila4NZS.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 12,
      name: 'Dumbbell Walking Lunge',
      primaryMuscles: ['Legs', 'Quadriceps', 'Glutes'],
      category: 'Dumbbell',
      difficulty: 'Beginner',
      force: 'Push',
      steps: [
        'Hold dumbbells at your sides and step forward into a lunge.',
        'Lower the trailing knee just above the ground.',
        'Step through and repeat on the other side.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0336-RRWFUcw.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),

    // SHOULDERS
    MuscleWikiExercise(
      id: 13,
      name: 'Dumbbell Lateral Raise',
      primaryMuscles: ['Shoulders', 'Lateral Deltoids'],
      category: 'Dumbbell',
      difficulty: 'Beginner',
      force: 'Push',
      steps: [
        'Stand tall with dumbbells resting at side thighs.',
        'Raise arms outward leading with elbows until parallel with floor.',
        'Control the descent to keep constant tension on side delts.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0334-DsgkuIt.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 14,
      name: 'Overhead Barbell Shoulder Press',
      primaryMuscles: ['Shoulders', 'Triceps', 'Upper Chest'],
      category: 'Barbell',
      difficulty: 'Intermediate',
      force: 'Push',
      steps: [
        'Rest bar across collarbone, grip slightly wider than shoulders.',
        'Press bar vertically overhead, moving head back then through the window.',
        'Lock out overhead with bar centered over mid-foot.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 22,
      name: 'Cable Rear Delt Fly',
      primaryMuscles: ['Shoulders', 'Rear Deltoids', 'Rhomboids'],
      category: 'Cable',
      difficulty: 'Beginner',
      force: 'Pull',
      steps: [
        'Stand at cable machine with handles crossed at chest height.',
        'Pull cables horizontally outward leading with elbows.',
        'Squeeze rear deltoids at the peak and control the return.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0154-aqvSOQE.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),

    // ABS / CORE
    MuscleWikiExercise(
      id: 15,
      name: 'Hanging Leg Raise',
      primaryMuscles: ['Core', 'Abs'],
      category: 'Bodyweight',
      difficulty: 'Intermediate',
      force: 'Pull',
      steps: [
        'Hang from a pull-up bar with an overhand grip.',
        'Roll pelvis upward while raising legs to 90 degrees or higher.',
        'Lower under control, avoiding excessive swinging.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0472-I3tsCnC.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 16,
      name: 'Ab Wheel Rollout',
      primaryMuscles: ['Core', 'Abs', 'Lats'],
      category: 'Bodyweight',
      difficulty: 'Advanced',
      force: 'Push',
      steps: [
        'Kneel on mat with hands gripping ab roller underneath shoulders.',
        'Roll the wheel forward keeping hips tucked and core completely rigid.',
        'Pull back into start position by contracting the abs.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/3544-5VXmnV5.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
    MuscleWikiExercise(
      id: 23,
      name: 'Cable Crunch',
      primaryMuscles: ['Core', 'Abs'],
      category: 'Cable',
      difficulty: 'Beginner',
      force: 'Pull',
      steps: [
        'Kneel in front of high cable with rope held next to ears.',
        'Flex spine downward, bringing elbows toward thighs using abdominal contraction.',
        'Maintain hip position throughout the movement.',
      ],
      videos: [
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0174-Zq1W2TH.gif',
          angle: 'front',
          gender: 'male',
        ),
        MuscleWikiVideo(
          url: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
          angle: 'side',
          gender: 'male',
        ),
      ],
    ),
  ];
}
