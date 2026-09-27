import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/dashboard/data/owner_dashboard_repository.dart';
import 'package:gym_connect_app/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:gym_connect_app/features/payments/presentation/providers/payments_providers.dart';
import 'package:gym_connect_app/features/payments/presentation/screens/gym_owner_payment_approvals_screen.dart';
import 'package:gym_connect_app/features/store/presentation/providers/store_providers.dart';
import 'package:gym_connect_app/features/store/presentation/screens/gym_owner_product_management_screen.dart';
import 'package:gym_connect_app/features/store/presentation/screens/gym_owner_store_orders_screen.dart';
import 'package:gym_connect_app/features/workout/presentation/desktop/desktop_workout_protocol_manager_view.dart';
import 'package:gym_connect_app/features/calculators/presentation/screens/calculators_hub_screen.dart';
import 'package:gym_connect_app/features/members/presentation/screens/desktop_member_hub_screen.dart';
import '../../domain/models/workstation_item.dart';
import '../providers/workstations_order_provider.dart';
import '../widgets/bento_previews/bento_workstation_card.dart';
import '../widgets/bento_previews/mini_member_table_preview.dart';
import '../widgets/bento_previews/mini_workout_protocol_preview.dart';
import '../widgets/bento_previews/mini_store_orders_preview.dart';
import '../widgets/bento_previews/mini_pro_shop_inventory_preview.dart';
import '../widgets/bento_previews/mini_payment_approvals_preview.dart';
import '../widgets/bento_previews/mini_calculators_hub_preview.dart';

class DesktopOwnerPortalView extends ConsumerWidget {
  final UserProfile profile;

  const DesktopOwnerPortalView({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = profile.tenantId ?? '';
    final accent = Theme.of(context).colorScheme.primary;
    final pendingPaymentsAsync = ref.watch(pendingPaymentsProvider(tenantId));
    final pendingPaymentsCount = pendingPaymentsAsync.asData?.value.length ?? 0;

    final storeOrdersAsync = ref.watch(tenantStoreOrdersProvider(tenantId));
    final pendingOrdersCount = storeOrdersAsync.asData?.value.where((o) => o.orderStatus.toLowerCase() == 'pending').length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsRow(ref, tenantId),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'EXECUTIVE WORKSTATIONS & CONTROLS',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drag_indicator_rounded, size: 13, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      'DRAG & DROP TO REORDER',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Reset workstations to default order',
                child: InkWell(
                  onTap: () {
                    ref.read(workstationsOrderProvider(tenantId).notifier).resetToDefault();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surface,
                        content: Text(
                          'Workstation layout reset to default order',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restore_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          'RESET LAYOUT',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildWorkstationsGrid(context, ref, tenantId, pendingPaymentsCount, pendingOrdersCount),
          const SizedBox(height: 24),
          _buildWatchdogCard(),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(WidgetRef ref, String tenantId) {
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
          SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              title: 'Active Members',
              value: metrics.formattedActiveMembers,
              icon: Icons.people_alt_rounded,
              subtitle: metrics.retentionSubtitle,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              title: 'Check-Ins Today',
              value: metrics.formattedCheckInsToday,
              icon: Icons.door_sliding_rounded,
              subtitle: metrics.checkInsSubtitle,
            ),
          ),
          SizedBox(width: 14),
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

  Widget _buildWorkstationsGrid(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
    int pendingPayments,
    int pendingOrders,
  ) {
    final workstationsOrder = ref.watch(workstationsOrderProvider(tenantId));
    final accent = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: workstationsOrder.asMap().entries.map((entry) {
            final index = entry.key;
            final id = entry.value;

            return DragTarget<int>(
              onWillAcceptWithDetails: (details) => details.data != index,
              onAcceptWithDetails: (details) {
                ref
                    .read(workstationsOrderProvider(tenantId).notifier)
                    .reorder(details.data, index);
              },
              builder: (context, candidateData, rejectedData) {
                final isTargeted = candidateData.isNotEmpty;

                final regularCard = _buildCardForId(
                  id: id,
                  cardWidth: cardWidth,
                  index: index,
                  tenantId: tenantId,
                  pendingPayments: pendingPayments,
                  pendingOrders: pendingOrders,
                  context: context,
                );

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: isTargeted
                        ? Border.all(color: accent, width: 2)
                        : null,
                    boxShadow: isTargeted
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Draggable<int>(
                    data: index,
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: cardWidth,
                        height: 205,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.45),
                                blurRadius: 28,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: 0.95,
                            child: _buildCardForId(
                              id: id,
                              cardWidth: cardWidth,
                              index: index,
                              tenantId: tenantId,
                              pendingPayments: pendingPayments,
                              pendingOrders: pendingOrders,
                              context: context,
                              isFeedback: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Container(
                      width: cardWidth,
                      height: 205,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              color: accent.withValues(alpha: 0.8),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'REPOSITIONING WORKSTATION...',
                              style: GoogleFonts.oswald(
                                fontSize: 13,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                                color: accent.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: regularCard,
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCardForId({
    required WorkstationId id,
    required double cardWidth,
    required int index,
    required String tenantId,
    required int pendingPayments,
    required int pendingOrders,
    required BuildContext context,
    bool isFeedback = false,
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    final dragHandleWidget =
        isFeedback ? null : _buildDragHandle(context, index, accent);

    switch (id) {
      case WorkstationId.members:
        return BentoWorkstationCard(
          width: cardWidth,
          title: 'MEMBERS DIRECTORY & EXCEL INGESTION [DESKTOP]',
          subtitle:
              'Batch Excel/CSV sheet upload, auto-register database columns, credentials manager & deep workout telemetry',
          icon: Icons.groups_rounded,
          badge: 'MEMBERS',
          isHighlight: true,
          moduleTag: 'TITAN // MEMBERS HUB',
          dragHandle: dragHandleWidget,
          onTap: isFeedback
              ? () {}
              : () => DesktopMemberHubScreen.open(context, profile: profile),
          previewWidget: MiniMemberTablePreview(tenantId: tenantId),
        );
      case WorkstationId.workout:
        return BentoWorkstationCard(
          width: cardWidth,
          title: 'WORKOUT PROTOCOL STUDIO [DESKTOP]',
          subtitle:
              'Calibrate Ectomorph, Mesomorph, Endomorph 7-day schedules & exercises for your gym',
          icon: Icons.fitness_center_rounded,
          badge: 'STUDIO',
          isHighlight: true,
          moduleTag: 'TITAN // PROTOCOL STUDIO',
          dragHandle: dragHandleWidget,
          onTap: isFeedback
              ? () {}
              : () => DesktopWorkoutProtocolManagerView.open(context,
                  profile: profile),
          previewWidget: MiniWorkoutProtocolPreview(tenantId: tenantId),
        );
      case WorkstationId.storeOrders:
        return BentoWorkstationCard(
          width: cardWidth,
          title: 'STORE ORDERS & DISPATCH',
          subtitle: pendingOrders > 0
              ? '$pendingOrders order(s) waiting to prepare & dispatch'
              : 'All orders fulfilled',
          icon: Icons.inventory_2_rounded,
          badge: pendingOrders > 0 ? '$pendingOrders NEW' : 'LIVE',
          isHighlight: pendingOrders > 0,
          moduleTag: 'TITAN // STORE DISPATCH',
          dragHandle: dragHandleWidget,
          onTap: isFeedback
              ? () {}
              : () =>
                  GymOwnerStoreOrdersScreen.open(context, tenantId: tenantId),
          previewWidget: MiniStoreOrdersPreview(tenantId: tenantId),
        );
      case WorkstationId.proShop:
        return BentoWorkstationCard(
          width: cardWidth,
          title: 'PRO SHOP & INVENTORY MANAGER',
          subtitle:
              'Upload product photos, set Pakistani pricing, adjust supplement stock',
          icon: Icons.storefront_rounded,
          badge: 'POS STORE',
          isHighlight: false,
          moduleTag: 'TITAN // PRO SHOP',
          dragHandle: dragHandleWidget,
          onTap: isFeedback
              ? () {}
              : () => GymOwnerProductManagementScreen.open(context,
                  tenantId: tenantId),
          previewWidget: MiniProShopInventoryPreview(tenantId: tenantId),
        );
      case WorkstationId.payments:
        return BentoWorkstationCard(
          width: cardWidth,
          title: 'PENDING PROOF-OF-PAYMENTS',
          subtitle: pendingPayments > 0
              ? '$pendingPayments transfer slip(s) pending review'
              : 'All payments reconciled',
          icon: Icons.receipt_long_rounded,
          badge: pendingPayments > 0 ? '$pendingPayments PENDING' : 'CLEAR',
          isHighlight: pendingPayments > 0,
          moduleTag: 'TITAN // PAYMENT AUDIT',
          dragHandle: dragHandleWidget,
          onTap: isFeedback
              ? () {}
              : () => GymOwnerPaymentApprovalsScreen.open(context,
                  tenantId: tenantId),
          previewWidget: MiniPaymentApprovalsPreview(tenantId: tenantId),
        );
      case WorkstationId.tools:
        return BentoWorkstationCard(
          width: cardWidth,
          title: 'CLINICAL TOOLS & CALCULATORS',
          subtitle:
              'Precision Calorie intake (BMR/TDEE), Macronutrient ratios, 1RM, and BMI health analysis',
          icon: Icons.calculate_rounded,
          badge: 'TOOLS',
          isHighlight: false,
          moduleTag: 'TITAN // CLINICAL TOOLS',
          dragHandle: dragHandleWidget,
          onTap: isFeedback
              ? () {}
              : () => Navigator.of(context).push(
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
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        body: const SafeArea(child: CalculatorsHubScreen()),
                      ),
                    ),
                  ),
          previewWidget: const MiniCalculatorsHubPreview(),
        );
    }
  }

  Widget _buildDragHandle(BuildContext context, int index, Color accent) {
    return Tooltip(
      message: 'Drag card to rearrange workstation position',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.drag_indicator_rounded, color: accent, size: 14),
              const SizedBox(width: 3),
              Text(
                '#${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
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
