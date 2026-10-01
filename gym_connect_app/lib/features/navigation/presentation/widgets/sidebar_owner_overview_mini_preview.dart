import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import '../../../dashboard/data/owner_dashboard_repository.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../../store/presentation/providers/store_providers.dart';

class SidebarOwnerOverviewMiniPreview extends ConsumerWidget {
  final String tenantId;

  const SidebarOwnerOverviewMiniPreview({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final metricsAsync = ref.watch(ownerDashboardMetricsProvider(tenantId));
    final pendingPayments =
        ref.watch(pendingPaymentsProvider(tenantId)).asData?.value.length ?? 0;
    final pendingOrders = ref
            .watch(tenantStoreOrdersProvider(tenantId))
            .asData
            ?.value
            .where((o) => o.orderStatus.toLowerCase() == 'pending')
            .length ??
        0;

    return Container(
      width: 480,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111114),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_rounded, color: accent, size: 16),
              const SizedBox(width: 8),
              Text(
                'EXECUTIVE OVERVIEW SNAPSHOT',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accent),
                ),
                child: Text('LIVE',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: accent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          metricsAsync.when(
            loading: () => const Center(
              child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, _) => Text('No telemetry available',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary)),
            data: (m) => Row(
              children: [
                _buildPill('Revenue', m.formattedMonthlyRevenue),
                const SizedBox(width: 8),
                _buildPill('Members', m.formattedActiveMembers),
                const SizedBox(width: 8),
                _buildPill('Check-ins', m.formattedCheckInsToday),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildBadge('6 Workstations Active', Colors.white70),
              _buildBadge(
                pendingOrders > 0
                    ? '$pendingOrders Orders Pending'
                    : 'Orders Fulfilled',
                pendingOrders > 0 ? Colors.amber : Colors.white60,
              ),
              _buildBadge(
                pendingPayments > 0
                    ? '$pendingPayments Slips Review'
                    : 'Payments Clear',
                pendingPayments > 0 ? Colors.orangeAccent : Colors.white60,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 9.5, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.oswald(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 9.5, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}
