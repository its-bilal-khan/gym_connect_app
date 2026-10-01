import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/explore_reels_provider.dart';
import '../providers/explore_reels_state.dart';
import 'explore_reels_carousel_view.dart';
import 'explore_reels_grid_view.dart';

class ExploreReelsSheet extends ConsumerWidget {
  const ExploreReelsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ExploreReelsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exploreReelsProvider);
    final notifier = ref.read(exploreReelsProvider.notifier);
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.explore_rounded, color: Colors.deepPurpleAccent, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GYM EXPLORE FEED', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('60-90s workout highlights & transformation micro-clips', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // Rule 5 Dual-View Standard Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.view_carousel_rounded,
                          size: 18,
                          color: state.viewMode == ExploreReelsViewMode.carousel ? accent : AppColors.textSecondary,
                        ),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        tooltip: 'Carousel Feed',
                        onPressed: () => notifier.setViewMode(ExploreReelsViewMode.carousel),
                      ),
                      Container(width: 1, height: 16, color: AppColors.border),
                      IconButton(
                        icon: Icon(
                          Icons.grid_view_rounded,
                          size: 18,
                          color: state.viewMode == ExploreReelsViewMode.grid ? accent : AppColors.textSecondary,
                        ),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        tooltip: 'Grid View',
                        onPressed: () => notifier.setViewMode(ExploreReelsViewMode.grid),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.errorMessage != null
                      ? Center(child: Text(state.errorMessage!, style: GoogleFonts.inter(color: AppColors.error)))
                      : state.viewMode == ExploreReelsViewMode.carousel
                          ? ExploreReelsCarouselView(reels: state.reels)
                          : ExploreReelsGridView(reels: state.reels),
            ),
          ],
        ),
      ),
    );
  }
}
