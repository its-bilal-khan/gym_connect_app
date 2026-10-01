import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/models.dart';
import '../providers/explore_reels_provider.dart';

class ExploreReelsCarouselView extends ConsumerWidget {
  final List<WorkoutMicroReel> reels;

  const ExploreReelsCarouselView({super.key, required this.reels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_collection_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text('NO REELS IN EXPLORE FEED YET', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Record your first Set 1 micro-clip to appear on the gym feed!', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final notifier = ref.read(exploreReelsProvider.notifier);
    final state = ref.watch(exploreReelsProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: reels.length,
      onPageChanged: (i) => notifier.setActiveIndex(i),
      itemBuilder: (context, index) {
        final reel = reels[index];
        final isLiked = state.isLiked(reel.id);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill_rounded, size: 64, color: accent.withValues(alpha: 0.8)),
                    const SizedBox(height: 8),
                    Text('${reel.durationSeconds}s Highlight', style: GoogleFonts.oswald(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: accent.withValues(alpha: 0.2),
                          child: Text(
                            reel.memberName?.isNotEmpty == true ? reel.memberName![0].toUpperCase() : 'M',
                            style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reel.memberName ?? 'Gym Member',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: Colors.deepOrangeAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: Text('🔥 ${reel.streakDaysAtRecord}d', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reel.routineTitle ?? 'Workout Micro-Clip',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 20,
                right: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isLiked ? Colors.redAccent : Colors.white,
                        size: 28,
                      ),
                      onPressed: () => notifier.toggleLike(reel.id),
                    ),
                    Text(
                      '${reel.likesCount}',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
