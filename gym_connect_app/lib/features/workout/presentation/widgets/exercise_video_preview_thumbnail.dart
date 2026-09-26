import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/video_player_controller_factory.dart';
import '../../data/youtube_video_utils.dart';
import '../../domain/models/workout_models.dart';
import 'fullscreen_video_dialog.dart';

/// A high-performance, responsive video preview widget for exercise cards.
///
/// Automatically handles:
/// - YouTube links with official thumbnail previews and glowing volt play overlays.
/// - Direct MP4 / WebM / CDN video streams (including MuscleWiki) with inline muted looping.
/// - Custom thumbnail images with fallback graceful placeholders.
/// - Dual-angle badges when side video is present.
/// - Click-to-fullscreen interactive playback.
class ExerciseVideoPreviewThumbnail extends StatefulWidget {
  final Exercise exercise;
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool autoPlay;

  const ExerciseVideoPreviewThumbnail({
    super.key,
    required this.exercise,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.onTap,
    this.autoPlay = true,
  });

  @override
  State<ExerciseVideoPreviewThumbnail> createState() =>
      _ExerciseVideoPreviewThumbnailState();
}

class _ExerciseVideoPreviewThumbnailState
    extends State<ExerciseVideoPreviewThumbnail> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isHovered = false;

  bool get _hasVideo =>
      widget.exercise.videoUrl != null &&
      widget.exercise.videoUrl!.trim().isNotEmpty;

  bool get _isYouTube =>
      _hasVideo && YoutubeVideoUtils.isYouTubeUrl(widget.exercise.videoUrl);

  String? get _youtubeThumbUrl =>
      _isYouTube ? YoutubeVideoUtils.getThumbnailUrl(widget.exercise.videoUrl, highRes: false) : null;

  @override
  void initState() {
    super.initState();
    _setupVideo();
  }

  @override
  void didUpdateWidget(covariant ExerciseVideoPreviewThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.videoUrl != widget.exercise.videoUrl) {
      _disposeController();
      _setupVideo();
    }
  }

  void _setupVideo() {
    if (!_hasVideo || _isYouTube || !widget.autoPlay) return;

    final url = widget.exercise.videoUrl!.trim();
    // Do not initialize video controller for static images
    final isStaticImage = url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.webp');
    if (isStaticImage) return;

    try {
      final ctrl = createVideoPlayerController(url);
      _controller = ctrl;
      ctrl.initialize().then((_) {
        if (!mounted) {
          ctrl.dispose();
          return;
        }
        ctrl.setLooping(true);
        ctrl.setVolume(0);
        ctrl.play();
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }).catchError((_) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
    } catch (_) {
      _hasError = true;
    }
  }

  void _disposeController() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _hasError = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _handleClick() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      FullscreenVideoDialog.show(context, widget.exercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasVideo &&
        (widget.exercise.thumbnailUrl == null ||
            widget.exercise.thumbnailUrl!.trim().isEmpty)) {
      return _buildNoVideoPlaceholder();
    }

    final hasSideAngle = widget.exercise.sideVideoUrl != null &&
        widget.exercise.sideVideoUrl!.trim().isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleClick,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: _isHovered
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.8),
              width: _isHovered ? 1.4 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMediaContent(),
                _buildOverlayBadges(hasSideAngle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    // 1. YouTube Stream Thumbnail
    if (_isYouTube && _youtubeThumbUrl != null) {
      return Image.network(
        _youtubeThumbUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackThumbnail(),
      );
    }

    // 2. Custom thumbnail image URL
    if (widget.exercise.thumbnailUrl != null &&
        widget.exercise.thumbnailUrl!.trim().isNotEmpty) {
      return Image.network(
        widget.exercise.thumbnailUrl!.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackThumbnail(),
      );
    }

    // 3. Initialized Video Player
    if (!_hasError && _isInitialized && _controller != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }

    // 4. Fallback Thumbnail
    return _buildFallbackThumbnail();
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      color: const Color(0xFF141418),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            color: AppColors.primary.withValues(alpha: 0.2),
            size: widget.height * 0.4,
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.2),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayBadges(bool hasSideAngle) {
    return Stack(
      children: [
        // Gradient overlay at bottom for badge legibility
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Top-Left Source Badge (YouTube / MuscleWiki / HD Stream)
        Positioned(
          top: 4,
          left: 4,
          child: _buildSourceBadge(),
        ),

        // Top-Right Dual Angle Badge
        if (hasSideAngle)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyan.shade900.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6)),
              ),
              child: Text(
                '2 ANGLES',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),

        // Center Play Icon if not playing video inline
        if (!_isInitialized)
          Center(
            child: AnimatedScale(
              scale: _isHovered ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),

        // Bottom-Right "EXPAND" Pill
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isHovered ? AppColors.primary : Colors.white24,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.open_in_full_rounded,
                  size: 9,
                  color: _isHovered ? AppColors.primary : Colors.white70,
                ),
                const SizedBox(width: 3),
                Text(
                  'WATCH',
                  style: GoogleFonts.oswald(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: _isHovered ? AppColors.primary : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceBadge() {
    if (_isYouTube) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_display_rounded, size: 10, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              'YOUTUBE',
              style: GoogleFonts.oswald(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    final isMuscleWiki = widget.exercise.videoUrl?.contains('musclewiki') ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_rounded, size: 10, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            isMuscleWiki ? 'MUSCLEWIKI' : 'HD VIDEO',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVideoPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF111114),
        borderRadius: widget.borderRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              color: Colors.white24,
              size: widget.height * 0.35,
            ),
            const SizedBox(height: 2),
            Text(
              'NO VIDEO',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white30,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
