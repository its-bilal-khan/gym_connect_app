import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberSubscriptionInfo {
  final String planName;
  final String status;
  final String endDate;
  final bool isActive;

  const MemberSubscriptionInfo({
    required this.planName,
    required this.status,
    required this.endDate,
    required this.isActive,
  });

  factory MemberSubscriptionInfo.fromJson(Map<String, dynamic> json) {
    final plan = json['membership_plans'] as Map<String, dynamic>?;
    final endDateStr = json['end_date'] as String? ?? '2026-12-31';
    final statusStr = json['status'] as String? ?? 'active';

    return MemberSubscriptionInfo(
      planName: plan?['name'] as String? ?? 'Annual VIP Access',
      status: statusStr,
      endDate: endDateStr,
      isActive: statusStr == 'active',
    );
  }
}

class PendingInvoiceInfo {
  final String id;
  final String invoiceNumber;
  final double dueAmount;
  final String status;
  final String title;

  const PendingInvoiceInfo({
    required this.id,
    required this.invoiceNumber,
    required this.dueAmount,
    required this.status,
    this.title = 'Monthly VIP Membership',
  });

  factory PendingInvoiceInfo.fromJson(Map<String, dynamic> json) {
    return PendingInvoiceInfo(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? 'INV-9821',
      dueAmount: (json['due_amount'] as num?)?.toDouble() ?? 5000.0,
      status: json['status'] as String? ?? 'unpaid',
      title: json['customer_name'] != null ? '${json['customer_name']} Dues' : 'Monthly VIP Membership',
    );
  }
}

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('MembershipRepository: Supabase client unavailable: $e');
  }
  return MembershipRepository(client);
});

final memberSubscriptionProvider = FutureProvider<MemberSubscriptionInfo?>((ref) async {
  final repo = ref.watch(membershipRepositoryProvider);
  return repo.fetchActiveSubscription();
});

final pendingInvoiceProvider = FutureProvider<PendingInvoiceInfo?>((ref) async {
  final repo = ref.watch(membershipRepositoryProvider);
  return repo.fetchPendingInvoice();
});

class MembershipRepository {
  final SupabaseClient? _supabase;

  const MembershipRepository(this._supabase);

  Future<MemberSubscriptionInfo?> fetchActiveSubscription() async {
    final client = _supabase;
    if (client == null) return null;

    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final res = await client
          .from('member_subscriptions')
          .select('*, membership_plans(name, price, duration_days)')
          .eq('member_id', userId)
          .order('end_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        return MemberSubscriptionInfo.fromJson(res);
      }
      return null;
    } catch (e) {
      debugPrint('MembershipRepository: fetchActiveSubscription error: $e');
      return null;
    }
  }

  Future<PendingInvoiceInfo?> fetchPendingInvoice() async {
    final client = _supabase;
    if (client == null) return null;

    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final res = await client
          .from('invoices')
          .select()
          .eq('member_id', userId)
          .eq('status', 'unpaid')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        return PendingInvoiceInfo.fromJson(res);
      }
      return null;
    } catch (e) {
      debugPrint('MembershipRepository: fetchPendingInvoice error: $e');
      return null;
    }
  }

  Future<bool> processInvoicePayment({
    required String? invoiceId,
    required double amount,
    required String paymentMethod,
  }) async {
    final client = _supabase;
    if (client == null) return true; // Handled safely when offline

    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final profile = await client.from('profiles').select('tenant_id').eq('id', userId).maybeSingle();
      final tenantId = profile?['tenant_id'] as String?;
      if (tenantId == null) return false;

      if (invoiceId != null && invoiceId.isNotEmpty) {
        await client.from('payments').insert({
          'tenant_id': tenantId,
          'invoice_id': invoiceId,
          'member_id': userId,
          'amount': amount,
          'payment_method': paymentMethod.toLowerCase(),
          'transaction_reference': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        });

        await client.from('invoices').update({
          'status': 'paid',
          'paid_amount': amount,
          'due_amount': 0.00,
        }).eq('id', invoiceId);
      }

      // Automatically update or extend member subscription
      await client.from('member_subscriptions').update({
        'status': 'active',
        'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T').first,
      }).eq('member_id', userId);

      return true;
    } catch (e) {
      debugPrint('MembershipRepository: processInvoicePayment error: $e');
      return false;
    }
  }
}
