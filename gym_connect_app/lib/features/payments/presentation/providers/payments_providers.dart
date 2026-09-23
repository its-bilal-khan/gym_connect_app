import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/payments_repository.dart';
import '../../domain/models/payment_submission.dart';
import '../../domain/models/tenant_payment_settings.dart';

/// Provider for a specific tenant's payment settings
final tenantPaymentSettingsProvider =
    FutureProvider.family<TenantPaymentSettings?, String>((ref, tenantId) async {
  if (tenantId.isEmpty) return null;
  final repo = ref.watch(paymentsRepositoryProvider);
  return repo.fetchTenantPaymentSettings(tenantId);
});

/// Provider for current logged-in user's gym payment settings
final currentGymPaymentSettingsProvider =
    FutureProvider<TenantPaymentSettings?>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) return null;
  final tenantId = authState.profile.tenantId;
  if (tenantId == null || tenantId.isEmpty) return null;

  final repo = ref.watch(paymentsRepositoryProvider);
  return repo.fetchTenantPaymentSettings(tenantId);
});

/// Provider for pending payment submissions for a specific gym tenant
final pendingPaymentsProvider =
    FutureProvider.family<List<PaymentSubmission>, String>((ref, tenantId) async {
  if (tenantId.isEmpty) return [];
  final repo = ref.watch(paymentsRepositoryProvider);
  return repo.fetchPendingPayments(tenantId);
});

/// State for payment actions (Submit, Approve, Reject)
class PaymentActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const PaymentActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  PaymentActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return PaymentActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class PaymentActionNotifier extends Notifier<PaymentActionState> {
  @override
  PaymentActionState build() {
    return const PaymentActionState();
  }

  PaymentsRepository get _repository => ref.read(paymentsRepositoryProvider);

  Future<bool> submitManualPaymentProof({
    required String tenantId,
    required double amount,
    required String receiptImageUrl,
    String? invoiceId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final success = await _repository.submitManualPayment(
        tenantId: tenantId,
        amount: amount,
        receiptImageUrl: receiptImageUrl,
        invoiceId: invoiceId,
      );

      if (success) {
        state = const PaymentActionState(
          isLoading: false,
          successMessage: 'Payment submitted for approval',
        );
        ref.invalidate(pendingPaymentsProvider(tenantId));
        return true;
      } else {
        state = const PaymentActionState(
          isLoading: false,
          errorMessage: 'Failed to submit payment. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = PaymentActionState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> approvePayment({
    required String paymentId,
    required String targetUserId,
    required String tenantId,
    double? amount,
    String? invoiceId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final success = await _repository.updatePaymentStatus(
        paymentId: paymentId,
        status: 'approved',
        targetUserId: targetUserId,
        tenantId: tenantId,
        amount: amount,
        invoiceId: invoiceId,
      );

      if (success) {
        state = const PaymentActionState(
          isLoading: false,
          successMessage: 'Payment approved successfully',
        );
        ref.invalidate(pendingPaymentsProvider(tenantId));
        return true;
      } else {
        state = const PaymentActionState(
          isLoading: false,
          errorMessage: 'Failed to approve payment',
        );
        return false;
      }
    } catch (e) {
      state = PaymentActionState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> rejectPayment({
    required String paymentId,
    required String targetUserId,
    required String tenantId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final success = await _repository.updatePaymentStatus(
        paymentId: paymentId,
        status: 'rejected',
        targetUserId: targetUserId,
        tenantId: tenantId,
      );

      if (success) {
        state = const PaymentActionState(
          isLoading: false,
          successMessage: 'Payment rejected',
        );
        ref.invalidate(pendingPaymentsProvider(tenantId));
        return true;
      } else {
        state = const PaymentActionState(
          isLoading: false,
          errorMessage: 'Failed to reject payment',
        );
        return false;
      }
    } catch (e) {
      state = PaymentActionState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final paymentActionNotifierProvider =
    NotifierProvider<PaymentActionNotifier, PaymentActionState>(PaymentActionNotifier.new);
