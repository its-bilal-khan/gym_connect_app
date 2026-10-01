import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../dashboard/data/owner_dashboard_repository.dart';
import '../../../../dashboard/presentation/widgets/metric_card.dart';

class OwnerPortalMetricsRow extends ConsumerWidget {
  final String tenantId;

  const OwnerPortalMetricsRow({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(ownerDashboardMetricsProvider(tenantId));

    return metricsAsync.when(
      loading: () => Row(
        children: const [
          Expanded(child: MetricCard(title: 'Monthly Revenue', value: '...', icon: Icons.attach_money_rounded, subtitle: 'Connecting live Supabase...')),
          SizedBox(width: 14),
          Expanded(child: MetricCard(title: 'Active Members', value: '...', icon: Icons.people_alt_rounded, subtitle: 'Counting roster...')),
          SizedBox(width: 14),
          Expanded(child: MetricCard(title: 'Check-Ins Today', value: '...', icon: Icons.door_sliding_rounded, subtitle: 'Fetching gate logs...')),
          SizedBox(width: 14),
          Expanded(child: MetricCard(title: 'Shift Cash Drawer', value: '...', icon: Icons.point_of_sale_rounded, subtitle: 'Querying shift...')),
        ],
      ),
      error: (e, _) => Row(
        children: const [
          Expanded(child: MetricCard(title: 'Monthly Revenue', value: 'PKR 0', icon: Icons.attach_money_rounded, subtitle: '0 transactions')),
          SizedBox(width: 14),
          Expanded(child: MetricCard(title: 'Active Members', value: '0', icon: Icons.people_alt_rounded, subtitle: '0 registered members')),
          SizedBox(width: 14),
          Expanded(child: MetricCard(title: 'Check-Ins Today', value: '0', icon: Icons.door_sliding_rounded, subtitle: 'No check-ins today')),
          SizedBox(width: 14),
          Expanded(child: MetricCard(title: 'Shift Cash Drawer', value: 'PKR 0', icon: Icons.point_of_sale_rounded, subtitle: 'POS drawer closed')),
        ],
      ),
      data: (metrics) => Row(
        children: [
          Expanded(
            child: MetricCard(
              title: 'Monthly Revenue',
              value: metrics.formattedMonthlyRevenue,
              icon: Icons.attach_money_rounded,
              subtitle: metrics.revenueGrowthSubtitle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              title: 'Active Members',
              value: metrics.formattedActiveMembers,
              icon: Icons.people_alt_rounded,
              subtitle: metrics.retentionSubtitle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              title: 'Check-Ins Today',
              value: metrics.formattedCheckInsToday,
              icon: Icons.door_sliding_rounded,
              subtitle: metrics.checkInsSubtitle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              title: 'Shift Cash Drawer',
              value: metrics.formattedShiftCashDrawer,
              icon: Icons.point_of_sale_rounded,
              subtitle: metrics.shiftCashSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}
