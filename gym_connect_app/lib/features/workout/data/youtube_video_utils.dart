abstract final class YoutubeVideoUtils {
  static final RegExp _ytRegExp = RegExp(
    r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtu\.be\/|youtube(?:-nocookie)?\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\w-]{11})',
    caseSensitive: false,
  );

  /// Returns true if the given URL is a valid YouTube video or shorts link.
  static bool isYouTubeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return _ytRegExp.hasMatch(url.trim());
  }

  /// Returns true if the given URL is a vertical YouTube Shorts link.
  static bool isShorts(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.trim().toLowerCase().contains('/shorts/');
  }

  /// Extracts the clean 11-character YouTube video ID.
  static String? extractVideoId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final match = _ytRegExp.firstMatch(url.trim());
    return match?.group(1);
  }

  /// Converts any standard YouTube link into a high-performance,
  /// copyright-safe embed URL with auto-play and seamless infinite looping.
  ///
  /// According to YouTube IFrame API specs, looping a single video requires:
  /// - `loop=1`
  /// - `playlist={VIDEO_ID}` (sets playlist to itself to loop indefinitely)
  /// - `mute=1` (required by browser autoplay policies)
  /// - `autoplay=1`
  /// - `playsinline=1` (mobile inline playback)
  static String toEmbedUrl(
    String url, {
    bool autoPlay = true,
    bool loop = true,
    bool mute = true,
    bool showControls = false,
  }) {
    final videoId = extractVideoId(url);
    if (videoId == null) return url.trim();

    final params = <String>[
      'autoplay=${autoPlay ? 1 : 0}',
      'mute=${mute ? 1 : 0}',
    ];
    if (loop) {
      params.add('loop=1');
      params.add('playlist=$videoId');
    }
    params.add('controls=${showControls ? 1 : 0}');
    params.add('rel=0');
    params.add('playsinline=1');
    params.add('modestbranding=1');
    params.add('disablekb=1');
    params.add('fs=0');
    params.add('iv_load_policy=3');
    params.add('showinfo=0');
    params.add('autohide=1');
    params.add('enablejsapi=1');

    return 'https://www.youtube-nocookie.com/embed/$videoId?${params.join('&')}';
  }

  /// Returns the HQ or Max-Res thumbnail image URL for the YouTube video.
  static String? getThumbnailUrl(String? url, {bool highRes = false}) {
    final videoId = extractVideoId(url);
    if (videoId == null) return null;
    final quality = highRes ? 'maxresdefault' : 'hqdefault';
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }
}
