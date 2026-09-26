import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/youtube_video_utils.dart';

import 'youtube_embed_view_stub.dart'
    if (dart.library.html) 'youtube_embed_view_web.dart';

class YoutubeEmbedPlayer extends StatelessWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool loop;
  final bool mute;
  final bool showControls;
  final double? aspectRatio;

  const YoutubeEmbedPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
    this.loop = true,
    this.mute = true,
    this.showControls = false,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubeVideoUtils.extractVideoId(videoUrl);
    if (videoId == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 36),
            const SizedBox(height: 8),
            Text(
              'Invalid YouTube Link',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final embedUrl = YoutubeVideoUtils.toEmbedUrl(
      videoUrl,
      autoPlay: autoPlay,
      loop: loop,
      mute: mute,
      showControls: showControls,
    );

    final isWeb = kIsWeb && isPlatformWeb;
    final isShorts = YoutubeVideoUtils.isShorts(videoUrl);
    final effectiveRatio = aspectRatio ?? (isShorts ? (9 / 16) : (16 / 9));

    return AspectRatio(
      aspectRatio: effectiveRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: IgnorePointer(
            ignoring: !showControls,
            child: isWeb
                ? buildPlatformYoutubeEmbed(
                    embedUrl: embedUrl,
                    videoId: videoId,
                  )
                : _buildNonWebFallback(context, videoId, embedUrl),
          ),
        ),
      ),
    );
  }

  Widget _buildNonWebFallback(
    BuildContext context,
    String videoId,
    String embedUrl,
  ) {
    final thumb = YoutubeVideoUtils.getThumbnailUrl(videoUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumb != null)
          Image.network(
            thumb,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.fitness_center_rounded,
                  color: Colors.white24, size: 48),
            ),
          ),
        Container(
          color: Colors.black.withValues(alpha: 0.65),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'YOUTUBE EMBED STREAM',
                      style: GoogleFonts.oswald(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AUTO-PLAY & SEAMLESS LOOP ENABLED',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(videoUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open YouTube Stream'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: GoogleFonts.oswald(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
