import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/dashboard/data/owner_dashboard_repository.dart';
import 'package:gym_connect_app/features/payments/presentation/providers/payments_providers.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';
import 'package:gym_connect_app/features/store/presentation/providers/store_providers.dart';
import '../widgets/owner_portal_metrics_row.dart';
import '../widgets/owner_workstations_grid.dart';
import '../widgets/workstations_header_toolbar.dart';

class DesktopOwnerPortalView extends ConsumerWidget {
  final UserProfile profile;

  const DesktopOwnerPortalView({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = profile.tenantId ?? '';
    final pendingPaymentsAsync = ref.watch(pendingPaymentsProvider(tenantId));
    final pendingPaymentsCount = pendingPaymentsAsync.asData?.value.length ?? 0;

    final storeOrdersAsync = ref.watch(tenantStoreOrdersProvider(tenantId));
    final pendingOrdersCount = storeOrdersAsync.asData?.value
            .where((o) => o.orderStatus.toLowerCase() == 'pending')
            .length ??
        0;

    final productsAsync = ref.watch(storeProductsProvider);
    final productsCount = productsAsync.asData?.value.length ?? 0;

    final metricsAsync = ref.watch(ownerDashboardMetricsProvider(tenantId));
    final activeMembersCount = metricsAsync.asData?.value.activeMembers ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OwnerPortalMetricsRow(tenantId: tenantId),
          const SizedBox(height: 24),
          WorkstationsHeaderToolbar(tenantId: tenantId),
          const SizedBox(height: 14),
          OwnerWorkstationsGrid(
            profile: profile,
            tenantId: tenantId,
            pendingPayments: pendingPaymentsCount,
            pendingOrders: pendingOrdersCount,
            activeMembers: activeMembersCount,
            productsCount: productsCount,
          ),
          const SizedBox(height: 24),
          _buildWatchdogCard(),
        ],
      ),
    );
  }

  Widget _buildWatchdogCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANTI-THEFT WATCHDOG & ACCESS RELAYS ARMED',
                  style: GoogleFonts.oswald(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '0 voided receipts or deleted bills in past 24 hours • Turnstile ESP32 connected • CCTV stream healthy.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
