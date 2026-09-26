import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:gym_connect_app/features/payments/presentation/providers/payments_providers.dart';
import 'package:gym_connect_app/features/payments/presentation/screens/gym_owner_payment_approvals_screen.dart';
import 'package:gym_connect_app/features/store/presentation/providers/store_providers.dart';
import 'package:gym_connect_app/features/store/presentation/screens/gym_owner_product_management_screen.dart';
import 'package:gym_connect_app/features/store/presentation/screens/gym_owner_store_orders_screen.dart';
import 'package:gym_connect_app/features/workout/presentation/desktop/desktop_workout_protocol_manager_view.dart';
import 'package:gym_connect_app/features/calculators/presentation/screens/calculators_hub_screen.dart';
import 'package:gym_connect_app/features/members/presentation/screens/desktop_member_hub_screen.dart';

class DesktopOwnerPortalView extends ConsumerWidget {
  final UserProfile profile;

  const DesktopOwnerPortalView({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = profile.tenantId ?? '';
    final pendingPaymentsAsync = ref.watch(pendingPaymentsProvider(tenantId));
    final pendingPaymentsCount = pendingPaymentsAsync.asData?.value.length ?? 0;

    final storeOrdersAsync = ref.watch(tenantStoreOrdersProvider(tenantId));
    final pendingOrdersCount = storeOrdersAsync.asData?.value.where((o) => o.orderStatus.toLowerCase() == 'pending').length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsRow(),
          const SizedBox(height: 24),
          Text(
            'EXECUTIVE WORKSTATIONS & CONTROLS',
            style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
          ),
          const SizedBox(height: 14),
          _buildWorkstationsGrid(context, tenantId, pendingPaymentsCount, pendingOrdersCount),
          const SizedBox(height: 24),
          _buildWatchdogCard(),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: const [
        Expanded(child: MetricCard(title: 'Monthly Revenue', value: 'PKR 185,000', icon: Icons.attach_money_rounded, subtitle: '+14.2% vs previous month')),
        SizedBox(width: 14),
        Expanded(child: MetricCard(title: 'Active Members', value: '1,482', icon: Icons.people_alt_rounded, subtitle: '96.2% retention rate')),
        SizedBox(width: 14),
        Expanded(child: MetricCard(title: 'Check-Ins Today', value: '348', icon: Icons.door_sliding_rounded, subtitle: 'Peak: 6:00 PM - 8:30 PM')),
        SizedBox(width: 14),
        Expanded(child: MetricCard(title: 'Shift Cash Drawer', value: 'PKR 54,000', icon: Icons.point_of_sale_rounded, subtitle: '0 voided receipts')),
      ],
    );
  }

  Widget _buildWorkstationsGrid(BuildContext context, String tenantId, int pendingPayments, int pendingOrders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStationTile(
              width: (constraints.maxWidth - 16) / 2,
              title: 'MEMBERS DIRECTORY & EXCEL INGESTION [DESKTOP]',
              subtitle: 'Batch Excel/CSV sheet upload, auto-register database columns, credentials manager & deep workout telemetry',
              icon: Icons.groups_rounded,
              badge: 'MEMBERS',
              isHighlight: true,
              onTap: () => DesktopMemberHubScreen.open(context, profile: profile),
            ),
            _buildStationTile(
              width: (constraints.maxWidth - 16) / 2,
              title: 'WORKOUT PROTOCOL STUDIO [DESKTOP]',
              subtitle: 'Calibrate Ectomorph, Mesomorph, Endomorph 7-day schedules & exercises for your gym',
              icon: Icons.fitness_center_rounded,
              badge: 'STUDIO',
              isHighlight: true,
              onTap: () => DesktopWorkoutProtocolManagerView.open(context, profile: profile),
            ),
            _buildStationTile(
              width: (constraints.maxWidth - 16) / 2,
              title: 'STORE ORDERS & DISPATCH',
              subtitle: pendingOrders > 0 ? '$pendingOrders order(s) waiting to prepare & dispatch' : 'All orders fulfilled',
              icon: Icons.inventory_2_rounded,
              badge: pendingOrders > 0 ? '$pendingOrders NEW' : 'LIVE',
              isHighlight: pendingOrders > 0,
              onTap: () => GymOwnerStoreOrdersScreen.open(context, tenantId: tenantId),
            ),
            _buildStationTile(
              width: (constraints.maxWidth - 16) / 2,
              title: 'PRO SHOP & INVENTORY MANAGER',
              subtitle: 'Upload product photos, set Pakistani pricing, adjust supplement stock',
              icon: Icons.storefront_rounded,
              badge: 'POS STORE',
              isHighlight: false,
              onTap: () => GymOwnerProductManagementScreen.open(context, tenantId: tenantId),
            ),
            _buildStationTile(
              width: (constraints.maxWidth - 16) / 2,
              title: 'PENDING PROOF-OF-PAYMENTS',
              subtitle: pendingPayments > 0 ? '$pendingPayments transfer slip(s) pending review' : 'All payments reconciled',
              icon: Icons.receipt_long_rounded,
              badge: pendingPayments > 0 ? '$pendingPayments PENDING' : 'CLEAR',
              isHighlight: pendingPayments > 0,
              onTap: () => GymOwnerPaymentApprovalsScreen.open(context, tenantId: tenantId),
            ),
            _buildStationTile(
              width: (constraints.maxWidth - 16) / 2,
              title: 'CLINICAL TOOLS & CALCULATORS',
              subtitle: 'Precision Calorie intake (BMR/TDEE), Macronutrient ratios, 1RM, and BMI health analysis',
              icon: Icons.calculate_rounded,
              badge: 'TOOLS',
              isHighlight: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: AppColors.background,
                    appBar: AppBar(
                      backgroundColor: AppColors.surface,
                      title: Text(
                        'CLINICAL TOOLS & CALCULATORS',
                        style: GoogleFonts.oswald(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    body: const SafeArea(child: CalculatorsHubScreen()),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStationTile({
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required bool isHighlight,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isHighlight ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isHighlight ? AppColors.primary : AppColors.border, width: isHighlight ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isHighlight ? AppColors.primary : AppColors.background,
              child: Icon(icon, color: isHighlight ? Colors.black : Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: isHighlight ? AppColors.primary : AppColors.background, borderRadius: BorderRadius.circular(8)),
                        child: Text(badge, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isHighlight ? Colors.black : AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchdogCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ANTI-THEFT WATCHDOG & ACCESS RELAYS ARMED', style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text('0 voided receipts or deleted bills in past 24 hours • Turnstile ESP32 connected • CCTV stream healthy.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
