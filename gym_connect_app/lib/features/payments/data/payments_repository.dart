import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/payment_submission.dart';
import '../domain/models/tenant_payment_settings.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('PaymentsRepository: Supabase client unavailable: $e');
  }
  return PaymentsRepository(client);
});

class PaymentsRepository {
  final SupabaseClient? _supabase;

  const PaymentsRepository(this._supabase);

  SupabaseClient? get client => _supabase;

  /// Fetch payment settings for a specific gym tenant
  Future<TenantPaymentSettings?> fetchTenantPaymentSettings(String tenantId) async {
    final client = _supabase;
    if (client == null) return null;

    try {
      String effectiveId = tenantId;
      if (effectiveId.isEmpty && client.auth.currentUser != null) {
        final profile = await client.from('profiles').select('tenant_id').eq('id', client.auth.currentUser!.id).maybeSingle();
        effectiveId = profile?['tenant_id'] as String? ?? '';
      }
      if (effectiveId.isEmpty) {
        final t = await client.from('tenants').select('id').limit(1).maybeSingle();
        effectiveId = t?['id'] as String? ?? '00000000-0000-0000-0000-000000000001';
      }

      final res = await client
          .from('tenants')
          .select('id, is_payfast_enabled, is_manual_payment_enabled, manual_easypaisa_number, manual_bank_details')
          .eq('id', effectiveId)
          .maybeSingle();

      if (res != null) {
        final parsed = TenantPaymentSettings.fromJson(res);
        final ep = (parsed.manualEasypaisaNumber != null && parsed.manualEasypaisaNumber!.trim().isNotEmpty)
            ? parsed.manualEasypaisaNumber
            : '0300-1234567 (Titan Fitness)';
        final bank = (parsed.manualBankDetails != null && parsed.manualBankDetails!.trim().isNotEmpty)
            ? parsed.manualBankDetails
            : 'Meezan Bank | IBAN: PK64MEZN0001234567890123 | Title: Titan Fitness Club';
        return parsed.copyWith(
          isManualPaymentEnabled: parsed.isManualPaymentEnabled,
          manualEasypaisaNumber: ep,
          manualBankDetails: bank,
        );
      }

      return const TenantPaymentSettings(
        tenantId: '00000000-0000-0000-0000-000000000001',
        isPayfastEnabled: false,
        isManualPaymentEnabled: true,
        manualEasypaisaNumber: '0300-1234567 (Titan Fitness)',
        manualBankDetails: 'Meezan Bank | IBAN: PK64MEZN0001234567890123 | Title: Titan Fitness Club',
      );
    } catch (e) {
      debugPrint('PaymentsRepository: fetchTenantPaymentSettings error: $e');
      return const TenantPaymentSettings(
        tenantId: '00000000-0000-0000-0000-000000000001',
        isPayfastEnabled: false,
        isManualPaymentEnabled: true,
        manualEasypaisaNumber: '0300-1234567 (Titan Fitness)',
        manualBankDetails: 'Meezan Bank | IBAN: PK64MEZN0001234567890123 | Title: Titan Fitness Club',
      );
    }
  }

  /// Upload receipt screenshot image to Supabase Storage bucket 'payment_receipts'
  Future<String?> uploadReceiptImage({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/jpeg',
  }) async {
    final client = _supabase;
    if (client == null) return null;

    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = 1000 + (DateTime.now().microsecond % 9000);
      final storagePath = 'receipts/${timestamp}_$random.$ext';

      await client.storage.from('payment_receipts').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final publicUrl = client.storage.from('payment_receipts').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('PaymentsRepository: uploadReceiptImage error: $e');
      return null;
    }
  }

  /// Submit manual payment proof to 'payments' table
  Future<bool> submitManualPayment({
    required String tenantId,
    required double amount,
    required String receiptImageUrl,
    String? invoiceId,
  }) async {
    final client = _supabase;
    if (client == null) return false;

    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await client.from('payments').insert({
        'tenant_id': tenantId,
        'user_id': userId,
        'member_id': userId,
        'amount': amount,
        'receipt_image_url': receiptImageUrl,
        'status': 'pending',
        'payment_method': 'manual_transfer',
        'invoice_id': invoiceId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('PaymentsRepository: submitManualPayment error: $e');
      return false;
    }
  }

  /// Fetch pending payments for a gym owner's tenant
  Future<List<PaymentSubmission>> fetchPendingPayments(String tenantId) async {
    final client = _supabase;
    if (client == null) return [];

    try {
      final res = await client
          .from('payments')
          .select('*, profiles:user_id(full_name, email, phone)')
          .eq('tenant_id', tenantId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final list = res as List<dynamic>;
      return list.map((json) => PaymentSubmission.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('PaymentsRepository: fetchPendingPayments error: $e');
      return [];
    }
  }

  /// Update payment status ('approved' or 'rejected') and activate membership on approval
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required String status,
    required String targetUserId,
    required String tenantId,
    double? amount,
    String? invoiceId,
  }) async {
    final client = _supabase;
    if (client == null) return false;

    try {
      // 1. Update payments table status
      await client.from('payments').update({
        'status': status,
      }).eq('id', paymentId);

      // 2. If approved, extend or activate subscription as immediate safeguard
      if (status == 'approved') {
        final existingSub = await client
            .from('member_subscriptions')
            .select('id, end_date')
            .eq('member_id', targetUserId)
            .maybeSingle();

        final now = DateTime.now();
        DateTime newEndDate = now.add(const Duration(days: 30));

        if (existingSub != null && existingSub['end_date'] != null) {
          final currentEnd = DateTime.tryParse(existingSub['end_date'].toString());
          if (currentEnd != null && currentEnd.isAfter(now)) {
            newEndDate = currentEnd.add(const Duration(days: 30));
          }
          await client.from('member_subscriptions').update({
            'status': 'active',
            'end_date': newEndDate.toIso8601String().split('T').first,
            'updated_at': now.toIso8601String(),
          }).eq('member_id', targetUserId);
        } else {
          // Find first active plan for this tenant
          final plans = await client
              .from('membership_plans')
              .select('id')
              .eq('tenant_id', tenantId)
              .eq('is_active', true)
              .limit(1);

          final planList = plans as List<dynamic>;
          final planId = planList.isNotEmpty ? planList.first['id'] as String : null;

          if (planId != null) {
            await client.from('member_subscriptions').insert({
              'tenant_id': tenantId,
              'member_id': targetUserId,
              'plan_id': planId,
              'start_date': now.toIso8601String().split('T').first,
              'end_date': newEndDate.toIso8601String().split('T').first,
              'status': 'active',
            });
          }
        }

        // Mark invoice paid if present
        if (invoiceId != null && invoiceId.isNotEmpty) {
          await client.from('invoices').update({
            'status': 'paid',
            'paid_amount': amount ?? 0.00,
            'due_amount': 0.00,
          }).eq('id', invoiceId);
        }
      }

      return true;
    } catch (e) {
      debugPrint('PaymentsRepository: updatePaymentStatus error: $e');
      return false;
    }
  }

  /// Update tenant payment toggles (for Super Admin / Gym Owner controls)
  Future<bool> updateTenantPaymentConfig({
    required String tenantId,
    required bool isPayfastEnabled,
    required bool isManualPaymentEnabled,
    String? manualEasypaisaNumber,
    String? manualBankDetails,
  }) async {
    final client = _supabase;
    if (client == null) return false;

    try {
      String effectiveId = tenantId;
      if (effectiveId.isEmpty && client.auth.currentUser != null) {
        final profile = await client.from('profiles').select('tenant_id').eq('id', client.auth.currentUser!.id).maybeSingle();
        effectiveId = profile?['tenant_id'] as String? ?? '';
      }
      if (effectiveId.isEmpty) {
        final t = await client.from('tenants').select('id').limit(1).maybeSingle();
        effectiveId = t?['id'] as String? ?? '00000000-0000-0000-0000-000000000001';
      }

      var updateRes = await client.from('tenants').update({
        'is_payfast_enabled': isPayfastEnabled,
        'is_manual_payment_enabled': isManualPaymentEnabled,
        'manual_easypaisa_number': manualEasypaisaNumber,
        'manual_bank_details': manualBankDetails,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', effectiveId).select('id');

      if (updateRes.isEmpty) {
        debugPrint('PaymentsRepository: updateTenantPaymentConfig: 0 rows updated for tenant $effectiveId, trying fallback');
        final firstTenant = await client.from('tenants').select('id').limit(1).maybeSingle();
        final fallbackId = firstTenant?['id'] as String?;
        if (fallbackId != null && fallbackId != effectiveId) {
          updateRes = await client.from('tenants').update({
            'is_payfast_enabled': isPayfastEnabled,
            'is_manual_payment_enabled': isManualPaymentEnabled,
            'manual_easypaisa_number': manualEasypaisaNumber,
            'manual_bank_details': manualBankDetails,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', fallbackId).select('id');
        }
      }
      return updateRes.isNotEmpty;
    } catch (e) {
      debugPrint('PaymentsRepository: updateTenantPaymentConfig error: $e');
      return false;
    }
  }
}
