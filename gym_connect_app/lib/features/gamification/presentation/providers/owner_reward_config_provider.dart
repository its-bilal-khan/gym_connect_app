import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/moderation_repository.dart';
import '../../domain/models/models.dart';

class OwnerRewardConfigState {
  final TenantRewardConfig config;
  final List<MonthlyPodiumArchive> ledger;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool isSavedSuccess;

  const OwnerRewardConfigState({
    this.config = const TenantRewardConfig(),
    this.ledger = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.isSavedSuccess = false,
  });

  OwnerRewardConfigState copyWith({
    TenantRewardConfig? config,
    List<MonthlyPodiumArchive>? ledger,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? isSavedSuccess,
  }) {
    return OwnerRewardConfigState(
      config: config ?? this.config,
      ledger: ledger ?? this.ledger,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isSavedSuccess: isSavedSuccess ?? this.isSavedSuccess,
    );
  }
}

final ownerRewardConfigProvider =
    NotifierProvider<OwnerRewardConfigNotifier, OwnerRewardConfigState>(
  OwnerRewardConfigNotifier.new,
);

class OwnerRewardConfigNotifier extends Notifier<OwnerRewardConfigState> {
  ModerationRepository get _repo => ref.read(moderationRepositoryProvider);

  @override
  OwnerRewardConfigState build() {
    return const OwnerRewardConfigState();
  }

  Future<void> loadConfigAndLedger(String tenantId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final config = await _repo.fetchTenantRewardConfig(tenantId);
      final ledger = await _repo.fetchFulfillmentLedger(tenantId: tenantId);
      state = state.copyWith(
        config: config,
        ledger: ledger,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> saveConfig({
    required String tenantId,
    required TenantRewardConfig newConfig,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, isSavedSuccess: false);
    try {
      await _repo.updateTenantRewardConfig(tenantId: tenantId, config: newConfig);
      state = state.copyWith(config: newConfig, isSaving: false, isSavedSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }
}
