import 'package:flutter/foundation.dart';

@immutable
class OwnerDashboardMetrics {
  final double monthlyRevenue;
  final double previousMonthRevenue;
  final int paidInvoicesCount;
  final int activeMembers;
  final int totalMembers;
  final int checkInsToday;
  final String peakHours;
  final double shiftCashDrawer;
  final String shiftStatus; // 'open' | 'closed'
  final String? activeStaffName;
  final int shiftSalesCount;

  const OwnerDashboardMetrics({
    required this.monthlyRevenue,
    required this.previousMonthRevenue,
    required this.paidInvoicesCount,
    required this.activeMembers,
    required this.totalMembers,
    required this.checkInsToday,
    required this.peakHours,
    required this.shiftCashDrawer,
    required this.shiftStatus,
    this.activeStaffName,
    required this.shiftSalesCount,
  });

  /// Formats an integer or double with commas (e.g., 185000 -> "185,000")
  static String formatNumber(num value) {
    final isNegative = value < 0;
    final absVal = value.abs().toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < absVal.length; i++) {
      if (i > 0 && (absVal.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(absVal[i]);
    }
    return '${isNegative ? '-' : ''}$buffer';
  }

  /// Formatted PKR Monthly Revenue (e.g., "PKR 185,000" or "PKR 0")
  String get formattedMonthlyRevenue => 'PKR ${formatNumber(monthlyRevenue)}';

  /// Formatted Active Members count (e.g., "1,482" or "0")
  String get formattedActiveMembers => formatNumber(activeMembers);

  /// Formatted Today's Check-Ins (e.g., "348" or "0")
  String get formattedCheckInsToday => formatNumber(checkInsToday);

  /// Formatted Shift Cash in drawer (e.g., "PKR 54,000" or "PKR 0")
  String get formattedShiftCashDrawer {
    if (shiftStatus == 'closed' && shiftCashDrawer <= 0) {
      return 'PKR 0';
    }
    return 'PKR ${formatNumber(shiftCashDrawer)}';
  }

  /// Retention rate percentage string: e.g. "96.2% retention rate"
  String get retentionSubtitle {
    if (totalMembers <= 0) return '0 registered members';
    final rate = ((activeMembers / totalMembers) * 100).clamp(0.0, 100.0);
    return '${rate.toStringAsFixed(1)}% retention rate ($activeMembers/$totalMembers)';
  }

  /// Subtitle for Monthly Revenue
  String get revenueGrowthSubtitle {
    if (monthlyRevenue <= 0) {
      return 'No transactions recorded yet';
    }
    if (previousMonthRevenue <= 0) {
      final count = paidInvoicesCount > 0 ? paidInvoicesCount : 1;
      return '$count paid transaction${count > 1 ? 's' : ''} this month';
    }
    final diff = monthlyRevenue - previousMonthRevenue;
    final pct = ((diff / previousMonthRevenue) * 100).clamp(-100.0, 999.0);
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% vs previous month';
  }

  /// Subtitle for Check-Ins Today
  String get checkInsSubtitle {
    if (checkInsToday == 0) {
      return 'No check-ins logged today';
    }
    return peakHours;
  }

  /// Subtitle for Shift Cash Drawer
  String get shiftCashSubtitle {
    if (shiftStatus == 'closed') {
      return 'POS drawer closed • Start shift';
    }
    final staff = (activeStaffName != null && activeStaffName!.isNotEmpty)
        ? ' • Staff: $activeStaffName'
        : '';
    return '$shiftSalesCount sales in shift$staff';
  }

  factory OwnerDashboardMetrics.empty() {
    return const OwnerDashboardMetrics(
      monthlyRevenue: 0.0,
      previousMonthRevenue: 0.0,
      paidInvoicesCount: 0,
      activeMembers: 0,
      totalMembers: 0,
      checkInsToday: 0,
      peakHours: 'Peak: 6:00 PM - 8:30 PM',
      shiftCashDrawer: 0.0,
      shiftStatus: 'closed',
      activeStaffName: null,
      shiftSalesCount: 0,
    );
  }

  factory OwnerDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardMetrics(
      monthlyRevenue: (json['monthly_revenue'] as num?)?.toDouble() ?? 0.0,
      previousMonthRevenue: (json['previous_month_revenue'] as num?)?.toDouble() ?? 0.0,
      paidInvoicesCount: (json['paid_invoices_count'] as num?)?.toInt() ?? 0,
      activeMembers: (json['active_members'] as num?)?.toInt() ?? 0,
      totalMembers: (json['total_members'] as num?)?.toInt() ?? 0,
      checkInsToday: (json['check_ins_today'] as num?)?.toInt() ?? 0,
      peakHours: json['peak_hours'] as String? ?? 'Peak: 6:00 PM - 8:30 PM',
      shiftCashDrawer: (json['shift_cash_drawer'] as num?)?.toDouble() ?? 0.0,
      shiftStatus: json['shift_status'] as String? ?? 'closed',
      activeStaffName: json['active_staff_name'] as String?,
      shiftSalesCount: (json['shift_sales_count'] as num?)?.toInt() ?? 0,
    );
  }
}
