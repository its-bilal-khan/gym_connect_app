import 'video_cache_manager.dart';

VideoCacheManager createVideoCacheManager() => VideoCacheWeb();

class VideoCacheWeb implements VideoCacheManager {
  final Set<String> _cachedUrls = {};

  @override
  Future<String> getOrCacheVideo(
    String remoteUrl, {
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
  }) async {
    _cachedUrls.add(remoteUrl);
    if (onProgress != null) onProgress(1.0);
    return remoteUrl;
  }

  @override
  Future<bool> isVideoCached(String remoteUrl) async {
    return _cachedUrls.contains(remoteUrl);
  }

  @override
  Future<int> getCacheSizeBytes() async {
    return _cachedUrls.length * 1024 * 1024 * 2; // Approximate estimation
  }

  @override
  Future<void> clearCache() async {
    _cachedUrls.clear();
  }
}
