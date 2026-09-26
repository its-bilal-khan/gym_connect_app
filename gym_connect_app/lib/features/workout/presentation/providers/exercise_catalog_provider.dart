import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/workout_repository.dart';
import '../../domain/models/workout_models.dart';

class ExerciseCatalogState {
  final List<Exercise> allExercises;
  final bool isLoading;
  final String searchQuery;
  final String selectedMuscle;
  final bool onlyWithVideos;
  final String? actionMessage;
  final String? errorMessage;

  const ExerciseCatalogState({
    this.allExercises = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedMuscle = 'All',
    this.onlyWithVideos = false,
    this.actionMessage,
    this.errorMessage,
  });

  int get totalExercises => allExercises.length;
  int get withVideoCount => allExercises.where((e) => e.videoUrl != null && e.videoUrl!.isNotEmpty).length;

  List<Exercise> get filteredExercises {
    return allExercises.where((ex) {
      final matchesSearch = searchQuery.isEmpty ||
          ex.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          ex.targetMuscle.toLowerCase().contains(searchQuery.toLowerCase()) ||
          ex.equipment.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesMuscle = selectedMuscle == 'All' ||
          ex.targetMuscle.toLowerCase() == selectedMuscle.toLowerCase();

      final matchesVideo = !onlyWithVideos || (ex.videoUrl != null && ex.videoUrl!.isNotEmpty);

      return matchesSearch && matchesMuscle && matchesVideo;
    }).toList();
  }

  ExerciseCatalogState copyWith({
    List<Exercise>? allExercises,
    bool? isLoading,
    String? searchQuery,
    String? selectedMuscle,
    bool? onlyWithVideos,
    String? actionMessage,
    String? errorMessage,
  }) {
    return ExerciseCatalogState(
      allExercises: allExercises ?? this.allExercises,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMuscle: selectedMuscle ?? this.selectedMuscle,
      onlyWithVideos: onlyWithVideos ?? this.onlyWithVideos,
      actionMessage: actionMessage,
      errorMessage: errorMessage,
    );
  }
}

final exerciseCatalogNotifierProvider =
    NotifierProvider<ExerciseCatalogNotifier, ExerciseCatalogState>(ExerciseCatalogNotifier.new);

class ExerciseCatalogNotifier extends Notifier<ExerciseCatalogState> {
  late WorkoutRepository _repo;

  @override
  ExerciseCatalogState build() {
    _repo = ref.read(workoutRepositoryProvider);
    Future.microtask(() => loadCatalog());
    return const ExerciseCatalogState(isLoading: true);
  }

  Future<void> loadCatalog({bool force = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repo.fetchExerciseCatalog(forceRefresh: force);
      state = state.copyWith(allExercises: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load exercises: $e');
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedMuscle(String muscle) {
    state = state.copyWith(selectedMuscle: muscle);
  }

  void toggleOnlyWithVideos() {
    state = state.copyWith(onlyWithVideos: !state.onlyWithVideos);
  }

  Future<bool> addOrUpdateExercise(
    Exercise exercise, {
    String? tenantId,
    bool isGlobal = true,
  }) async {
    try {
      final saved = await _repo.saveOrUpdateExercise(exercise, tenantId: tenantId, isGlobal: isGlobal);
      final updatedList = List<Exercise>.from(state.allExercises);
      final idx = updatedList.indexWhere((e) => e.id == saved.id);
      if (idx >= 0) {
        updatedList[idx] = saved;
      } else {
        updatedList.insert(0, saved);
      }
      state = state.copyWith(
        allExercises: updatedList,
        actionMessage: 'Exercise "${saved.name}" successfully updated.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save exercise: $e');
      return false;
    }
  }

  Future<bool> attachOrUpdateVideo({
    required String exerciseId,
    required String videoUrl,
    String? sideVideoUrl,
    String? exerciseName,
  }) async {
    try {
      await _repo.updateExerciseVideo(
        exerciseId: exerciseId,
        videoUrl: videoUrl.trim(),
        sideVideoUrl: sideVideoUrl?.trim(),
        exerciseName: exerciseName,
      );

      final updatedList = state.allExercises.map((e) {
        if (e.id == exerciseId ||
            (exerciseName != null &&
                e.name.toLowerCase().trim() ==
                    exerciseName.toLowerCase().trim())) {
          return e.copyWith(
            videoUrl: videoUrl.trim(),
            sideVideoUrl: sideVideoUrl?.trim() ?? e.sideVideoUrl,
          );
        }
        return e;
      }).toList();

      state = state.copyWith(
        allExercises: updatedList,
        actionMessage: 'Video successfully attached!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update video: $e');
      return false;
    }
  }

  Future<bool> deleteExercise(String exerciseId) async {
    try {
      await _repo.deleteExercise(exerciseId);
      final updatedList = state.allExercises.where((e) => e.id != exerciseId).toList();
      state = state.copyWith(
        allExercises: updatedList,
        actionMessage: 'Exercise deleted from master catalog.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete exercise: $e');
      return false;
    }
  }
}
