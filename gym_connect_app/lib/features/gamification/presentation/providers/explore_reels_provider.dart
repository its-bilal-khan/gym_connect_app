import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/explore_reels_repository.dart';
import '../../domain/models/models.dart';
import 'explore_reels_state.dart';

final exploreReelsProvider =
    NotifierProvider<ExploreReelsNotifier, ExploreReelsState>(ExploreReelsNotifier.new);

class ExploreReelsNotifier extends Notifier<ExploreReelsState> {
  ExploreReelsRepository get _repo => ref.read(exploreReelsRepositoryProvider);

  @override
  ExploreReelsState build() {
    Future.microtask(() => loadReels());
    return const ExploreReelsState();
  }

  Future<void> loadReels({String? tenantId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final reels = await _repo.fetchExploreReels(tenantId: tenantId);
      state = state.copyWith(
        reels: reels,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setActiveIndex(int index) {
    if (index >= 0 && index < state.reels.length) {
      state = state.copyWith(activeIndex: index);
    }
  }

  void setViewMode(ExploreReelsViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  Future<void> toggleLike(String reelId) async {
    final isCurrentlyLiked = state.isLiked(reelId);
    final updatedLiked = Set<String>.from(state.likedReelIds);

    if (isCurrentlyLiked) {
      updatedLiked.remove(reelId);
    } else {
      updatedLiked.add(reelId);
    }

    // Optimistic UI update
    final updatedReels = state.reels.map((r) {
      if (r.id == reelId) {
        final newCount = isCurrentlyLiked ? (r.likesCount - 1).clamp(0, 999999) : r.likesCount + 1;
        return WorkoutMicroReel(
          id: r.id,
          tenantId: r.tenantId,
          userId: r.userId,
          memberName: r.memberName,
          videoUrl: r.videoUrl,
          thumbnailUrl: r.thumbnailUrl,
          durationSeconds: r.durationSeconds,
          routineTitle: r.routineTitle,
          streakDaysAtRecord: r.streakDaysAtRecord,
          isPublicExplore: r.isPublicExplore,
          isFlagged: r.isFlagged,
          likesCount: newCount,
          createdAt: r.createdAt,
        );
      }
      return r;
    }).toList();

    state = state.copyWith(
      likedReelIds: updatedLiked,
      reels: updatedReels,
    );

    try {
      await _repo.toggleLike(reelId: reelId, increment: !isCurrentlyLiked);
    } catch (_) {}
  }
}
