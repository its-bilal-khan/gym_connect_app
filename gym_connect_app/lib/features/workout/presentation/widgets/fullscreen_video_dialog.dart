import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/services/video_cache_manager.dart';
import '../../../../core/services/video_player_controller_factory.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/youtube_video_utils.dart';
import '../../domain/models/cdn_video_item.dart';
import '../../domain/models/workout_models.dart';
import 'youtube_embed_player.dart';

class FullscreenVideoDialog extends StatefulWidget {
  final Exercise exercise;
  final bool initialFrontAngle;

  const FullscreenVideoDialog({
    super.key,
    required this.exercise,
    this.initialFrontAngle = true,
  });

  static Future<void> show(
    BuildContext context,
    Exercise exercise, {
    bool isFrontAngle = true,
  }) {
    return showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) => FullscreenVideoDialog(
        exercise: exercise,
        initialFrontAngle: isFrontAngle,
      ),
    );
  }

  @override
  State<FullscreenVideoDialog> createState() => _FullscreenVideoDialogState();
}

class _FullscreenVideoDialogState extends State<FullscreenVideoDialog> {
  late bool _isFront;
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool? _isVerticalOverride;
  String? _overrideUrl;
  bool _usingFallbackCdn = false;

  @override
  void initState() {
    super.initState();
    _isFront = widget.initialFrontAngle;
    _initMedia();
  }

  bool get _hasSideVideo =>
      widget.exercise.sideVideoUrl != null &&
      widget.exercise.sideVideoUrl!.trim().isNotEmpty;

  String get _activeUrl {
    if (_overrideUrl != null && _overrideUrl!.isNotEmpty) {
      return _overrideUrl!;
    }
    return (_isFront || !_hasSideVideo
            ? widget.exercise.videoUrl
            : widget.exercise.sideVideoUrl) ??
        widget.exercise.videoUrl ??
        '';
  }

  bool get _isYouTube => YoutubeVideoUtils.isYouTubeUrl(_activeUrl);
  bool get _isVertical =>
      _isVerticalOverride ?? YoutubeVideoUtils.isShorts(_activeUrl);

  bool get _isAnimatedImage {
    final lower = _activeUrl.toLowerCase();
    return lower.contains('.gif') ||
        lower.contains('.webp') ||
        lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg');
  }

  String? _findVerifiedCdnStream() {
    final name = widget.exercise.name.toLowerCase();
    final muscle = widget.exercise.targetMuscle.toLowerCase();

    for (final v in CdnVideoLibrary.verifiedVideos) {
      final t = v.title.toLowerCase();
      if ((name.contains('curl') && t.contains('curl')) ||
          (name.contains('bench') && t.contains('bench')) ||
          (name.contains('pushup') && t.contains('push-up')) ||
          (name.contains('squat') && t.contains('squat')) ||
          (name.contains('press') && t.contains('press')) ||
          (name.contains('lat') && t.contains('lat')) ||
          (name.contains('pull') && t.contains('pull')) ||
          (name.contains('dip') && t.contains('dip')) ||
          (name.contains('row') && t.contains('row'))) {
        return _isFront ? v.primaryVideoUrl : (v.sideVideoUrl ?? v.primaryVideoUrl);
      }
    }

    for (final v in CdnVideoLibrary.verifiedVideos) {
      if (v.targetMuscle.toLowerCase() == muscle) {
        return _isFront ? v.primaryVideoUrl : (v.sideVideoUrl ?? v.primaryVideoUrl);
      }
    }

    if (CdnVideoLibrary.verifiedVideos.isNotEmpty) {
      return CdnVideoLibrary.verifiedVideos.first.primaryVideoUrl;
    }
    return null;
  }

  Future<void> _initMedia() async {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _hasError = false;
    _isVerticalOverride = null;

    final url = _activeUrl;
    if (url.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (_isYouTube) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    if (_isAnimatedImage) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Client-Side Video Cache: On mobile/desktop downloads once to local cache dir, on web uses URL
      final localOrRemote = await VideoCacheManager.instance.getOrCacheVideo(url);
      final ctrl = createVideoPlayerController(localOrRemote);
      _controller = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.play();
    } catch (e) {
      // Auto fallback for MuscleWiki 401 or browser web CORS issues
      final fallback = _findVerifiedCdnStream();
      if (fallback != null && fallback != url && !_usingFallbackCdn) {
        _overrideUrl = fallback;
        _usingFallbackCdn = true;
        if (_isAnimatedImage) {
          _hasError = false;
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        try {
          final cachedFallback =
              await VideoCacheManager.instance.getOrCacheVideo(fallback);
          final fallbackCtrl = createVideoPlayerController(cachedFallback);
          _controller = fallbackCtrl;
          await fallbackCtrl.initialize();
          await fallbackCtrl.setLooping(true);
          await fallbackCtrl.play();
          _hasError = false;
        } catch (_) {
          _hasError = true;
        }
      } else {
        _hasError = true;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final ctrl = _controller;
    final isVideoReady = !_isLoading && ctrl != null && ctrl.value.isInitialized;
    final isYouTube = _isYouTube;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name.toUpperCase(),
                          style: GoogleFonts.oswald(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              widget.exercise.targetMuscle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isYouTube
                                    ? Colors.redAccent.withValues(alpha: 0.25)
                                    : (_isAnimatedImage
                                        ? Colors.cyanAccent.withValues(alpha: 0.2)
                                        : accent.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isYouTube
                                    ? '🔴 YOUTUBE EMBED • AUTOPLAY LOOP'
                                    : (_isAnimatedImage
                                        ? '⚡ CLIENT CACHED • ZERO QUOTA'
                                        : '⚡ CLIENT CACHED • SAVES API QUOTA'),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isYouTube
                                      ? Colors.redAccent
                                      : (_isAnimatedImage
                                          ? Colors.cyanAccent
                                          : accent),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: _isLoading
                    ? CircularProgressIndicator(color: accent)
                    : _hasError
                        ? _buildErrorView(accent)
                        : isYouTube
                            ? ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: _isVertical ? 420 : 960,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: YoutubeEmbedPlayer(
                                    videoUrl: _activeUrl,
                                    autoPlay: true,
                                    loop: true,
                                    aspectRatio: _isVertical ? (9 / 16) : (16 / 9),
                                  ),
                                ),
                              )
                            : _isAnimatedImage
                                ? InteractiveViewer(
                                    child: Image.network(
                                      _activeUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            color: accent,
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.fitness_center_rounded,
                                                color: Colors.white38,
                                                size: 50),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Demonstration Stream Unavailable',
                                              style: GoogleFonts.inter(
                                                  color: Colors.white60,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  )
                                : isVideoReady
                                    ? AspectRatio(
                                        aspectRatio: ctrl.value.aspectRatio,
                                        child: VideoPlayer(ctrl),
                                      )
                                    : const Icon(Icons.fitness_center_rounded,
                                        color: Colors.white38, size: 50),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isYouTube) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VIDEO ASPECT RATIO',
                          style: GoogleFonts.oswald(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: Colors.white70,
                          ),
                        ),
                        Row(
                          children: [
                            _angleBtn(
                              '9:16 SHORTS',
                              _isVertical,
                              () => setState(() => _isVerticalOverride = true),
                            ),
                            const SizedBox(width: 8),
                            _angleBtn(
                              '16:9 WIDE',
                              !_isVertical,
                              () => setState(() => _isVerticalOverride = false),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_hasSideVideo) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CAMERA ANGLE',
                          style: GoogleFonts.oswald(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: Colors.white70,
                          ),
                        ),
                        Row(
                          children: [
                            _angleBtn('FRONT', _isFront, () {
                              setState(() => _isFront = true);
                              _initMedia();
                            }),
                            const SizedBox(width: 8),
                            _angleBtn('SIDE', !_isFront, () {
                              setState(() => _isFront = false);
                              _initMedia();
                            }),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    widget.exercise.tips.isNotEmpty
                        ? widget.exercise.tips
                        : 'Maintain controlled tempo, brace core, and focus on clean movement biomechanics.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _angleBtn(String label, bool active, VoidCallback onTap) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? accent : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? accent : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(Color accent) {
    final isMw = _activeUrl.contains('musclewiki.com');
    final cdnStream = _findVerifiedCdnStream();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.videocam_off_rounded,
                color: Colors.redAccent, size: 40),
          ),
          const SizedBox(height: 14),
          Text(
            isMw
                ? 'MuscleWiki Direct Stream Restricted'
                : 'Unable to load stream preview',
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              isMw
                  ? 'MuscleWiki ka Free (BASIC) account direct streaming ko allow nahi karta (Testing tier \$10/mo darkar hai). Niche diye button se High-Speed Cloud video foran chalayein:'
                  : 'Remote video stream load nahi ho saki. Niche diye button se cloud stream chalayein ya retry karein.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          if (cdnStream != null) ...[
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _overrideUrl = cdnStream;
                  _usingFallbackCdn = true;
                  _hasError = false;
                });
                _initMedia();
              },
              icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
              label: const Text('PLAY HIGH-SPEED CLOUD VIDEO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle:
                    GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _hasError = false);
              _initMedia();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry Stream'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
