import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/explore_reels_provider.dart';

class ExploreReelsMiniView extends ConsumerWidget {
  final double scale;
  const ExploreReelsMiniView({super.key, this.scale = 0.85});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exploreReelsProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final topReel = state.reels.isNotEmpty ? state.reels.first : null;

    return Transform.scale(
      scale: scale,
      alignment: Alignment.topLeft,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.explore_rounded, color: Colors.deepPurpleAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'EXPLORE FEED LIVE',
                    style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Text(
                  '${state.reels.length} Reels',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_fill_rounded, size: 22, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topReel?.memberName ?? 'No Reels Yet',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          topReel?.routineTitle ?? 'Be the first to record a set!',
                          style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '❤️ ${topReel?.likesCount ?? 0}',
                    style: GoogleFonts.oswald(fontSize: 11, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
