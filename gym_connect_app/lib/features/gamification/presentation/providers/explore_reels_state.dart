import '../../domain/models/models.dart';

enum ExploreReelsViewMode {
  carousel,
  grid,
}

class ExploreReelsState {
  final List<WorkoutMicroReel> reels;
  final int activeIndex;
  final ExploreReelsViewMode viewMode;
  final Set<String> likedReelIds;
  final bool isMuted;
  final bool isLoading;
  final String? errorMessage;

  const ExploreReelsState({
    this.reels = const [],
    this.activeIndex = 0,
    this.viewMode = ExploreReelsViewMode.carousel,
    this.likedReelIds = const {},
    this.isMuted = false,
    this.isLoading = false,
    this.errorMessage,
  });

  WorkoutMicroReel? get currentReel {
    if (reels.isEmpty || activeIndex < 0 || activeIndex >= reels.length) return null;
    return reels[activeIndex];
  }

  bool isLiked(String reelId) => likedReelIds.contains(reelId);

  ExploreReelsState copyWith({
    List<WorkoutMicroReel>? reels,
    int? activeIndex,
    ExploreReelsViewMode? viewMode,
    Set<String>? likedReelIds,
    bool? isMuted,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExploreReelsState(
      reels: reels ?? this.reels,
      activeIndex: activeIndex ?? this.activeIndex,
      viewMode: viewMode ?? this.viewMode,
      likedReelIds: likedReelIds ?? this.likedReelIds,
      isMuted: isMuted ?? this.isMuted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
