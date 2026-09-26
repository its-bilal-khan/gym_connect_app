import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/models/cdn_video_item.dart';
import 'youtube_video_utils.dart';

class OnlineExerciseVideoService {
  static final OnlineExerciseVideoService instance =
      OnlineExerciseVideoService._internal();

  OnlineExerciseVideoService._internal();

  List<CdnVideoItem>? _cachedCatalog;
  bool _isLoading = false;

  static const String _onlineDatasetUrl =
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/data/exercises.json';

  static const String _cdnBaseUrl =
      'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/';

  bool get hasLoaded => _cachedCatalog != null && _cachedCatalog!.isNotEmpty;

  /// Fetches the online exercise catalog (1,300+ exercises) with in-memory caching.
  Future<List<CdnVideoItem>> getCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCatalog != null && _cachedCatalog!.isNotEmpty) {
      return _cachedCatalog!;
    }

    if (_isLoading) {
      // If already fetching, wait briefly or return verified library
      await Future.delayed(const Duration(milliseconds: 300));
      if (_cachedCatalog != null) return _cachedCatalog!;
    }

    _isLoading = true;
    try {
      final response = await http
          .get(Uri.parse(_onlineDatasetUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final items = <CdnVideoItem>[];
          for (final raw in decoded) {
            if (raw is! Map) continue;
            final item = _parseOnlineItem(raw);
            if (item != null) items.add(item);
          }
          if (items.isNotEmpty) {
            _cachedCatalog = items;
            _isLoading = false;
            return items;
          }
        }
      }
    } catch (e) {
      debugPrint('OnlineExerciseVideoService: network error $e, fallback to verified');
    } finally {
      _isLoading = false;
    }

    // Fallback if offline or parsing issue
    _cachedCatalog = CdnVideoLibrary.verifiedVideos;
    return _cachedCatalog!;
  }

  /// Real-time search across the online database by query keyword and muscle group.
  Future<List<CdnVideoItem>> searchOnline({
    String query = '',
    String muscle = 'All',
  }) async {
    final catalog = await getCatalog();
    final q = query.trim().toLowerCase();
    final m = muscle.trim().toLowerCase();

    final matches = catalog.where((item) {
      final matchesQuery = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.targetMuscle.toLowerCase().contains(q) ||
          item.equipment.toLowerCase().contains(q) ||
          item.tips.toLowerCase().contains(q);

      final matchesMuscle = m == 'all' || item.targetMuscle.toLowerCase() == m;

      return matchesQuery && matchesMuscle;
    }).toList();

    // Cap at 60 for snappy UI rendering
    return matches.take(60).toList();
  }

  /// Creates a custom stream item from user-entered URL (YouTube, Vimeo, S3, Cloudflare, etc.).
  CdnVideoItem createCustomItem({
    required String title,
    required String primaryVideoUrl,
    String? sideVideoUrl,
    String targetMuscle = 'Chest',
    String equipment = 'Other',
    String tips = '',
  }) {
    final cleanPrimary = primaryVideoUrl.trim();
    final formattedPrimary = YoutubeVideoUtils.isYouTubeUrl(cleanPrimary)
        ? YoutubeVideoUtils.toEmbedUrl(cleanPrimary, autoPlay: true, loop: true, mute: true)
        : cleanPrimary;

    final cleanSide = sideVideoUrl?.trim();
    final formattedSide = (cleanSide != null && cleanSide.isNotEmpty)
        ? (YoutubeVideoUtils.isYouTubeUrl(cleanSide)
            ? YoutubeVideoUtils.toEmbedUrl(cleanSide, autoPlay: true, loop: true, mute: true)
            : cleanSide)
        : null;

    final isYt = YoutubeVideoUtils.isYouTubeUrl(cleanPrimary);

    return CdnVideoItem(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty
          ? (isYt ? 'YouTube Exercise Demo' : 'Custom Online Stream')
          : title.trim(),
      targetMuscle: targetMuscle,
      equipment: equipment,
      primaryVideoUrl: formattedPrimary,
      sideVideoUrl: formattedSide,
      tips: tips.trim().isEmpty
          ? 'Maintain controlled tempo, brace core, and focus on clean movement biomechanics.'
          : tips.trim(),
      cdnProvider: isYt
          ? 'YouTube Embed API (Autoplay & Loop • Copyright-Safe)'
          : 'Custom Web / Cloud Stream',
      quality: isYt ? 'YouTube HD Auto-Loop' : 'Web Stream Preview',
    );
  }

  CdnVideoItem? _parseOnlineItem(Map raw) {
    final name = raw['name']?.toString() ?? '';
    final gifPath = raw['gif_url']?.toString() ?? '';
    if (name.isEmpty || gifPath.isEmpty) return null;

    final mediaId = raw['media_id']?.toString() ?? name;
    final bodyPart = raw['body_part']?.toString().toLowerCase() ?? '';
    final target = raw['target']?.toString().toLowerCase() ?? '';
    final equipment = raw['equipment']?.toString() ?? 'Bodyweight';

    final muscle = _mapToMuscleGroup(bodyPart, target);
    final title = _toTitleCase(name);
    final eq = _toTitleCase(equipment.replaceAll('body weight', 'Bodyweight'));

    final primaryUrl = '$_cdnBaseUrl$gifPath';
    final tips = _generateTips(raw, muscle, eq);

    return CdnVideoItem(
      id: 'online-$mediaId',
      title: title,
      targetMuscle: muscle,
      equipment: eq,
      primaryVideoUrl: primaryUrl,
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips: tips,
      cdnProvider: 'jsDelivr Cloud CDN (1,300+ Library)',
      quality: 'Animated 60fps HD Demo',
    );
  }

  String _mapToMuscleGroup(String bodyPart, String target) {
    if (bodyPart == 'chest' || target.contains('pectoral')) return 'Chest';
    if (bodyPart == 'back' ||
        target.contains('lat') ||
        target.contains('trap') ||
        target.contains('spine')) {
      return 'Back';
    }
    if (bodyPart == 'upper legs' ||
        bodyPart == 'lower legs' ||
        target.contains('quad') ||
        target.contains('hamstring') ||
        target.contains('glute') ||
        target.contains('calve')) {
      return 'Legs';
    }
    if (bodyPart == 'upper arms' ||
        bodyPart == 'lower arms' ||
        target.contains('bicep') ||
        target.contains('tricep') ||
        target.contains('forearm')) {
      return 'Arms';
    }
    if (bodyPart == 'shoulders' || target.contains('delt')) {
      return 'Shoulders';
    }
    if (bodyPart == 'waist' ||
        target.contains('abs') ||
        target.contains('core') ||
        target.contains('oblique')) {
      return 'Core';
    }
    return 'Full Body';
  }

  String _generateTips(Map raw, String muscle, String eq) {
    final instructions = raw['instructions'];
    if (instructions is Map && instructions['en'] is List) {
      final list = instructions['en'] as List;
      if (list.isNotEmpty) {
        return list.take(2).join(' ');
      }
    }
    return 'Perform $eq exercise targeting $muscle with steady cadence and strict posture.';
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
