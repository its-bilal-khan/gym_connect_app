import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/moderation_repository.dart';
import '../../domain/models/models.dart';

enum ModerationViewMode {
  list,
  grid,
}

class ModerationQueueState {
  final List<FlaggedQueueItem> items;
  final ModerationViewMode viewMode;
  final bool isLoading;
  final String? errorMessage;

  const ModerationQueueState({
    this.items = const [],
    this.viewMode = ModerationViewMode.list,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isListView => viewMode == ModerationViewMode.list;

  ModerationQueueState copyWith({
    List<FlaggedQueueItem>? items,
    ModerationViewMode? viewMode,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ModerationQueueState(
      items: items ?? this.items,
      viewMode: viewMode ?? this.viewMode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final moderationQueueProvider =
    NotifierProvider<ModerationQueueNotifier, ModerationQueueState>(
  ModerationQueueNotifier.new,
);

class ModerationQueueNotifier extends Notifier<ModerationQueueState> {
  ModerationRepository get _repo => ref.read(moderationRepositoryProvider);

  @override
  ModerationQueueState build() {
    return const ModerationQueueState();
  }

  Future<void> loadItems(String tenantId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.fetchPendingFlaggedItems(tenantId: tenantId);
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setViewMode(ModerationViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  Future<void> approveItem({required String queueId, required String reviewerId}) async {
    state = state.copyWith(items: state.items.where((i) => i.id != queueId).toList());
    try {
      await _repo.moderateFlaggedItem(
        queueId: queueId,
        status: 'approved',
        reviewerId: reviewerId,
      );
    } catch (_) {}
  }

  Future<bool> clawbackPoints({
    required String queueId,
    required String reviewerId,
    String? auditNotes,
    String? notes,
  }) async {
    state = state.copyWith(items: state.items.where((i) => i.id != queueId).toList());
    try {
      await _repo.moderateFlaggedItem(
        queueId: queueId,
        status: 'deducted',
        reviewerId: reviewerId,
        notes: auditNotes ?? notes ?? 'Fraud detected: Points clawed back',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
