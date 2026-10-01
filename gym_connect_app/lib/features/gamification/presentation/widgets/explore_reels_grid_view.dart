import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/models.dart';
import '../providers/explore_reels_provider.dart';

class ExploreReelsGridView extends ConsumerWidget {
  final List<WorkoutMicroReel> reels;

  const ExploreReelsGridView({super.key, required this.reels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view_rounded, size: 36, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text('NO REELS AVAILABLE', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ),
      );
    }

    final accent = Theme.of(context).colorScheme.primary;
    final notifier = ref.read(exploreReelsProvider.notifier);
    final state = ref.watch(exploreReelsProvider);

    return GridView.builder(
      itemCount: reels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final reel = reels[index];
        final isLiked = state.isLiked(reel.id);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Icon(Icons.play_circle_outline_rounded, size: 44, color: accent.withValues(alpha: 0.7)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                  child: Text('${reel.durationSeconds}s', style: GoogleFonts.oswald(fontSize: 10, color: Colors.white)),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reel.memberName ?? 'Gym Member',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      reel.routineTitle ?? 'Workout Highlight',
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('🔥 ${reel.streakDaysAtRecord}d', style: GoogleFonts.inter(fontSize: 9, color: Colors.deepOrangeAccent)),
                        GestureDetector(
                          onTap: () => notifier.toggleLike(reel.id),
                          child: Row(
                            children: [
                              Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 13, color: isLiked ? Colors.redAccent : Colors.white70),
                              const SizedBox(width: 3),
                              Text('${reel.likesCount}', style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
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
