import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/store_repository.dart';

enum StoreViewMode { grid, list }

final storeViewModeProvider = NotifierProvider<StoreViewModeNotifier, StoreViewMode>(StoreViewModeNotifier.new);

class StoreViewModeNotifier extends Notifier<StoreViewMode> {
  @override
  StoreViewMode build() => StoreViewMode.grid;

  void toggle() {
    state = state == StoreViewMode.grid ? StoreViewMode.list : StoreViewMode.grid;
  }

  void setMode(StoreViewMode mode) {
    state = mode;
  }
}

final customerOrdersProvider = FutureProvider<List<StoreOrder>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) return [];
  final userId = authState.profile.id;
  final repo = ref.watch(storeRepositoryProvider);
  return repo.fetchCustomerOrders(userId);
});

final tenantStoreOrdersProvider = FutureProvider.family<List<StoreOrder>, String>((ref, tenantId) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.fetchTenantStoreOrders(tenantId);
});

class StoreActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const StoreActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  StoreActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return StoreActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class StoreActionNotifier extends Notifier<StoreActionState> {
  @override
  StoreActionState build() => const StoreActionState();

  StoreRepository get _repo => ref.read(storeRepositoryProvider);

  Future<bool> updateOrderSchedule({
    required String orderId,
    required String tenantId,
    required String status,
    String? estimatedReadyDate,
    String? estimatedReadyTime,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final success = await _repo.updateOrderStatusAndSchedule(
        orderId: orderId,
        status: status,
        estimatedReadyDate: estimatedReadyDate,
        estimatedReadyTime: estimatedReadyTime,
      );

      if (success) {
        state = const StoreActionState(isLoading: false, successMessage: 'Order status updated');
        ref.invalidate(tenantStoreOrdersProvider(tenantId));
        ref.invalidate(customerOrdersProvider);
        return true;
      } else {
        state = const StoreActionState(isLoading: false, errorMessage: 'Failed to update order');
        return false;
      }
    } catch (e) {
      state = StoreActionState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> addProduct({
    required String name,
    required String category,
    required double price,
    required int stockQuantity,
    String? description,
    String? imageUrl,
    String? tenantId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final success = await _repo.addProduct(
        name: name,
        category: category,
        price: price,
        stockQuantity: stockQuantity,
        description: description,
        imageUrl: imageUrl,
        tenantId: tenantId,
      );

      if (success) {
        state = const StoreActionState(isLoading: false, successMessage: 'Product added successfully');
        ref.invalidate(storeProductsProvider);
        return true;
      } else {
        state = const StoreActionState(isLoading: false, errorMessage: 'Failed to add product');
        return false;
      }
    } catch (e) {
      state = StoreActionState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final success = await _repo.deleteProduct(productId);
      if (success) {
        state = const StoreActionState(isLoading: false, successMessage: 'Product deleted');
        ref.invalidate(storeProductsProvider);
        return true;
      } else {
        state = const StoreActionState(isLoading: false, errorMessage: 'Failed to delete product');
        return false;
      }
    } catch (e) {
      state = StoreActionState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final storeActionNotifierProvider = NotifierProvider<StoreActionNotifier, StoreActionState>(StoreActionNotifier.new);
