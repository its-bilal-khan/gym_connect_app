import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/domain/models/user_profile.dart';
import '../../../../dashboard/presentation/widgets/metric_card.dart';
import '../../../../payments/presentation/providers/payments_providers.dart';
import '../../../../payments/presentation/screens/gym_owner_payment_approvals_screen.dart';
import '../../../../store/presentation/providers/store_providers.dart';
import '../../../../store/presentation/screens/gym_owner_product_management_screen.dart';
import '../../../../store/presentation/screens/gym_owner_store_orders_screen.dart';

class OwnerOverviewTab extends ConsumerWidget {
  final UserProfile profile;

  const OwnerOverviewTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final tenantId = profile.tenantId ?? '';

    final pendingPaymentsAsync = ref.watch(pendingPaymentsProvider(tenantId));
    final pendingPaymentsCount = pendingPaymentsAsync.asData?.value.length ?? 0;

    final storeOrdersAsync = ref.watch(tenantStoreOrdersProvider(tenantId));
    final pendingOrdersCount = storeOrdersAsync.asData?.value.where((o) => o.orderStatus.toLowerCase() == 'pending').length ?? 0;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'EXECUTIVE OVERVIEW',
                    style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text('LIVE SYNC', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              title: 'STORE ORDERS & DISPATCH',
              subtitle: pendingOrdersCount > 0 ? '$pendingOrdersCount incoming order${pendingOrdersCount > 1 ? 's' : ''} to prepare & schedule' : 'All customer store orders dispatched',
              icon: Icons.inventory_2_rounded,
              highlight: pendingOrdersCount > 0,
              onTap: () => GymOwnerStoreOrdersScreen.open(context, tenantId: tenantId),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              title: 'PRO SHOP & INVENTORY MANAGER',
              subtitle: 'Add, upload photo, edit prices, or delete supplements & gear',
              icon: Icons.storefront_rounded,
              highlight: false,
              onTap: () => GymOwnerProductManagementScreen.open(context, tenantId: tenantId),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              title: 'PENDING PROOF-OF-PAYMENTS',
              subtitle: pendingPaymentsCount > 0 ? '$pendingPaymentsCount member receipt${pendingPaymentsCount > 1 ? 's' : ''} waiting for approval' : 'All payment proofs reviewed',
              icon: Icons.receipt_long_rounded,
              highlight: pendingPaymentsCount > 0,
              onTap: () => GymOwnerPaymentApprovalsScreen.open(context, tenantId: tenantId),
            ),
            const SizedBox(height: 14),
            const MetricCard(title: 'Monthly Revenue', value: 'PKR 185,000', icon: Icons.attach_money_rounded, subtitle: '+14.2% vs previous month'),
            const SizedBox(height: 12),
            const MetricCard(title: 'Active Members', value: '1,482', icon: Icons.people_alt_rounded, subtitle: '96.2% retention rate'),
            const SizedBox(height: 12),
            const MetricCard(title: 'Gate Check-Ins Today', value: '348', icon: Icons.door_sliding_rounded, subtitle: 'Peak: 6:00 PM - 8:30 PM'),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool highlight,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: highlight ? AppColors.primary : AppColors.border, width: highlight ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: highlight ? AppColors.primary : AppColors.border,
              radius: 18,
              child: Icon(icon, color: highlight ? Colors.black : Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: highlight ? AppColors.primary : AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
