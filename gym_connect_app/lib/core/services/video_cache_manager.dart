import 'video_cache_stub.dart'
    if (dart.library.io) 'video_cache_io.dart'
    if (dart.library.html) 'video_cache_web.dart';

abstract class VideoCacheManager {
  static VideoCacheManager? _instance;
  static VideoCacheManager get instance => _instance ??= createVideoCacheManager();

  /// Gets the local cached file path for a video URL, downloading it if not yet cached.
  /// On mobile/desktop, returns a local filesystem path (e.g. /data/user/0/.../cache/video.mp4).
  /// On web, returns the original remote URL.
  Future<String> getOrCacheVideo(
    String remoteUrl, {
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
  });

  /// Checks if the video is already cached locally.
  Future<bool> isVideoCached(String remoteUrl);

  /// Returns total disk size in bytes of cached videos.
  Future<int> getCacheSizeBytes();

  /// Clears all cached video files.
  Future<void> clearCache();
}
