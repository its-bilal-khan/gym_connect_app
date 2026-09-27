import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/owner_dashboard_metrics.dart';

final ownerDashboardRepositoryProvider = Provider<OwnerDashboardRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('OwnerDashboardRepository: Supabase client unavailable: $e');
  }
  return OwnerDashboardRepository(client);
});

final ownerDashboardMetricsProvider =
    FutureProvider.family<OwnerDashboardMetrics, String>((ref, tenantId) async {
  final repo = ref.watch(ownerDashboardRepositoryProvider);
  return repo.fetchMetrics(tenantId);
});

class OwnerDashboardRepository {
  final SupabaseClient? _supabase;

  const OwnerDashboardRepository(this._supabase);

  String _normalizeTenantId(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return '00000000-0000-0000-0000-000000000001';
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (uuidRegex.hasMatch(clean)) return clean;
    return '00000000-0000-0000-0000-000000000001';
  }

  Future<OwnerDashboardMetrics> fetchMetrics(String tenantId) async {
    final client = _supabase;
    if (client == null) {
      return OwnerDashboardMetrics.empty();
    }

    final cleanTid = _normalizeTenantId(tenantId);

    // 1. Try server-side PostgreSQL RPC function
    try {
      final rpcRes = await client.rpc(
        'get_owner_dashboard_metrics',
        params: {'p_tenant_id': cleanTid},
      );
      if (rpcRes != null && rpcRes is Map<String, dynamic>) {
        return OwnerDashboardMetrics.fromJson(rpcRes);
      }
    } catch (e) {
      debugPrint('OwnerDashboardRepository: RPC get_owner_dashboard_metrics unavailable, falling back to direct table queries: $e');
    }

    // 2. Direct table queries fallback
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfPrevMonth = DateTime(now.year, now.month - 1, 1);
      final startOfDay = DateTime(now.year, now.month, now.day);

      // A. Query Invoices for revenue
      double monthlyRev = 0.0;
      double prevMonthRev = 0.0;
      int paidCount = 0;

      try {
        final invoices = await client
            .from('invoices')
            .select('id, paid_amount, created_at, status')
            .eq('tenant_id', cleanTid)
            .eq('status', 'paid')
            .gte('created_at', startOfPrevMonth.toIso8601String());

        for (final inv in (invoices as List<dynamic>)) {
          final amt = (inv['paid_amount'] as num?)?.toDouble() ?? 0.0;
          final createdStr = inv['created_at']?.toString();
          if (createdStr != null) {
            final dt = DateTime.tryParse(createdStr);
            if (dt != null) {
              if (dt.isAfter(startOfMonth) || dt.isAtSameMomentAs(startOfMonth)) {
                monthlyRev += amt;
                paidCount++;
              } else if (dt.isAfter(startOfPrevMonth) || dt.isAtSameMomentAs(startOfPrevMonth)) {
                prevMonthRev += amt;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('OwnerDashboardRepository: invoices query error: $e');
      }

      // Add fulfilled store orders to revenue
      try {
        final orders = await client
            .from('store_orders')
            .select('total_amount, order_status, is_paid, created_at')
            .eq('tenant_id', cleanTid)
            .gte('created_at', startOfMonth.toIso8601String());

        for (final ord in (orders as List<dynamic>)) {
          final status = (ord['order_status'] ?? '').toString().toLowerCase();
          final isFinalized = status == 'completed' || status == 'delivered';
          if (isFinalized) {
            monthlyRev += (ord['total_amount'] as num?)?.toDouble() ?? 0.0;
            paidCount++;
          }
        }
      } catch (e) {
        debugPrint('OwnerDashboardRepository: store_orders query error: $e');
      }

      // B. Query Members
      int totalMembers = 0;
      int activeMembers = 0;

      try {
        final profiles = await client
            .from('profiles')
            .select('id, is_active')
            .eq('tenant_id', cleanTid)
            .eq('role', 'member');

        final profileList = profiles as List<dynamic>;
        totalMembers = profileList.length;

        // Try getting active from member_subscriptions
        final todayStr = now.toIso8601String().split('T').first;
        final activeSubs = await client
            .from('member_subscriptions')
            .select('member_id')
            .eq('tenant_id', cleanTid)
            .eq('status', 'active')
            .gte('end_date', todayStr);

        final subList = activeSubs as List<dynamic>;
        final activeIds = subList.map((s) => s['member_id']?.toString()).toSet();
        activeMembers = activeIds.length;

        if (activeMembers == 0 && totalMembers > 0) {
          activeMembers = profileList.where((p) => p['is_active'] != false).length;
        }
      } catch (e) {
        debugPrint('OwnerDashboardRepository: members query error: $e');
      }

      // C. Query Attendance Logs Today
      int checkInsToday = 0;
      String peakHours = 'Peak: 6:00 PM - 8:30 PM';

      try {
        final attendance = await client
            .from('attendance_logs')
            .select('id, check_in_time, access_result')
            .eq('tenant_id', cleanTid)
            .eq('access_result', 'granted')
            .gte('check_in_time', startOfDay.toIso8601String());

        final attList = attendance as List<dynamic>;
        checkInsToday = attList.length;
        if (checkInsToday > 0) {
          peakHours = 'Peak: 6:00 PM - 8:30 PM ($checkInsToday entries)';
        }
      } catch (e) {
        debugPrint('OwnerDashboardRepository: attendance query error: $e');
      }

      // D. Query Active POS Shift
      double shiftCash = 0.0;
      String shiftStatus = 'closed';
      String? staffName;
      int shiftSalesCount = 0;

      try {
        final shift = await client
            .from('pos_shifts')
            .select('id, opening_cash, status, profiles(full_name)')
            .eq('tenant_id', cleanTid)
            .eq('status', 'open')
            .order('opened_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (shift != null) {
          final shiftId = shift['id'] as String;
          shiftStatus = 'open';
          final opening = (shift['opening_cash'] as num?)?.toDouble() ?? 0.0;
          final staffMap = shift['profiles'] as Map<String, dynamic>?;
          staffName = staffMap?['full_name'] as String? ?? 'Reception Cashier';

          // Cash sales in this shift
          final shiftInvoices = await client
              .from('invoices')
              .select('paid_amount, payments(payment_method)')
              .eq('shift_id', shiftId)
              .eq('status', 'paid');

          double cashSales = 0.0;
          shiftSalesCount = (shiftInvoices as List<dynamic>).length;
          for (final inv in shiftInvoices) {
            final amt = (inv['paid_amount'] as num?)?.toDouble() ?? 0.0;
            final payments = inv['payments'] as List?;
            final method = (payments != null && payments.isNotEmpty)
                ? payments.first['payment_method']?.toString().toLowerCase()
                : 'cash';
            if (method == 'cash') {
              cashSales += amt;
            }
          }

          // Petty cash expenses in this shift
          double petty = 0.0;
          final pettyList = await client
              .from('petty_cash_expenses')
              .select('amount')
              .eq('shift_id', shiftId);

          for (final p in (pettyList as List<dynamic>)) {
            petty += (p['amount'] as num?)?.toDouble() ?? 0.0;
          }

          shiftCash = opening + cashSales - petty;
        }
      } catch (e) {
        debugPrint('OwnerDashboardRepository: pos_shifts query error: $e');
      }

      return OwnerDashboardMetrics(
        monthlyRevenue: monthlyRev,
        previousMonthRevenue: prevMonthRev,
        paidInvoicesCount: paidCount,
        activeMembers: activeMembers,
        totalMembers: totalMembers,
        checkInsToday: checkInsToday,
        peakHours: peakHours,
        shiftCashDrawer: shiftCash,
        shiftStatus: shiftStatus,
        activeStaffName: staffName,
        shiftSalesCount: shiftSalesCount,
      );
    } catch (e) {
      debugPrint('OwnerDashboardRepository: fetchMetrics critical error: $e');
      return OwnerDashboardMetrics.empty();
    }
  }
}
