import 'package:flutter/material.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/calculators/presentation/screens/calculators_hub_screen.dart';
import 'package:gym_connect_app/features/members/presentation/screens/desktop_member_hub_screen.dart';
import 'package:gym_connect_app/features/payments/presentation/screens/gym_owner_payment_approvals_screen.dart';
import 'package:gym_connect_app/features/store/presentation/screens/gym_owner_product_management_screen.dart';
import 'package:gym_connect_app/features/store/presentation/screens/gym_owner_store_orders_screen.dart';
import 'package:gym_connect_app/features/workout/presentation/desktop/desktop_workout_protocol_manager_view.dart';
import '../../../domain/models/workstation_item.dart';
import 'enterprise_workstation_card.dart';

Widget buildEnterpriseCard({
  required BuildContext context,
  required WorkstationId id,
  required double cardWidth,
  required UserProfile profile,
  required String tenantId,
  required int pendingPayments,
  required int pendingOrders,
  required int activeMembers,
  required int productsCount,
  required Widget? dragHandle,
  required bool isFeedback,
}) {
  switch (id) {
    case WorkstationId.members:
      return EnterpriseWorkstationCard(
        width: cardWidth,
        title: 'MEMBERS DIRECTORY & EXCEL INGESTION',
        subtitle: 'Batch Excel/CSV roster upload, database credentials & workout telemetry',
        icon: Icons.groups_rounded,
        badge: '$activeMembers MEMBERS',
        isHighlight: true,
        moduleTag: 'TITAN // MEMBERS HUB',
        dragHandle: dragHandle,
        telemetryPills: [
          '$activeMembers Active Roster',
          'Excel Ingestion Ready',
          'Auto Credentials',
        ],
        onTap: isFeedback ? () {} : () => DesktopMemberHubScreen.open(context, profile: profile),
      );
    case WorkstationId.workout:
      return EnterpriseWorkstationCard(
        width: cardWidth,
        title: 'WORKOUT PROTOCOL STUDIO',
        subtitle: 'Calibrate Ectomorph, Mesomorph, Endomorph 7-day protocol matrices',
        icon: Icons.fitness_center_rounded,
        badge: 'STUDIO',
        isHighlight: true,
        moduleTag: 'TITAN // PROTOCOL STUDIO',
        dragHandle: dragHandle,
        telemetryPills: const [
          '3 Somatotype Tracks',
          'AI Engine Sync',
          'Exercise Video Catalog',
        ],
        onTap: isFeedback ? () {} : () => DesktopWorkoutProtocolManagerView.open(context, profile: profile),
      );
    case WorkstationId.storeOrders:
      final hasPending = pendingOrders > 0;
      return EnterpriseWorkstationCard(
        width: cardWidth,
        title: 'STORE ORDERS & DISPATCH',
        subtitle: hasPending ? '$pendingOrders order(s) waiting for dispatch' : 'All orders dispatched and fulfilled',
        icon: Icons.inventory_2_rounded,
        badge: hasPending ? '$pendingOrders NEW ORDERS' : 'FULFILLED',
        isHighlight: hasPending,
        moduleTag: 'TITAN // STORE DISPATCH',
        dragHandle: dragHandle,
        telemetryPills: [
          hasPending ? '$pendingOrders Awaiting Dispatch' : '0 Pending Orders',
          'Live POS Stream',
          'Instant Receipt',
        ],
        onTap: isFeedback ? () {} : () => GymOwnerStoreOrdersScreen.open(context, tenantId: tenantId),
      );
    case WorkstationId.proShop:
      return EnterpriseWorkstationCard(
        width: cardWidth,
        title: 'PRO SHOP & INVENTORY MANAGER',
        subtitle: 'Upload product photos, set Pakistani pricing, adjust supplement stock levels',
        icon: Icons.storefront_rounded,
        badge: '$productsCount PRODUCTS',
        isHighlight: false,
        moduleTag: 'TITAN // PRO SHOP',
        dragHandle: dragHandle,
        telemetryPills: [
          '$productsCount Products Cataloged',
          'PKR Price Engine',
          'Stock Alerts Armed',
        ],
        onTap: isFeedback ? () {} : () => GymOwnerProductManagementScreen.open(context, tenantId: tenantId),
      );
    case WorkstationId.payments:
      final hasPending = pendingPayments > 0;
      return EnterpriseWorkstationCard(
        width: cardWidth,
        title: 'PENDING PROOF-OF-PAYMENTS',
        subtitle: hasPending ? '$pendingPayments bank transfer slip(s) pending owner review' : 'All payment slips audited & reconciled',
        icon: Icons.receipt_long_rounded,
        badge: hasPending ? '$pendingPayments PENDING' : 'CLEAR',
        isHighlight: hasPending,
        moduleTag: 'TITAN // PAYMENT AUDIT',
        dragHandle: dragHandle,
        telemetryPills: [
          hasPending ? '$pendingPayments Slips to Review' : '0 Pending Slips',
          'Audit Log Armed',
          'Anti-Theft Active',
        ],
        onTap: isFeedback ? () {} : () => GymOwnerPaymentApprovalsScreen.open(context, tenantId: tenantId),
      );
    case WorkstationId.tools:
      return EnterpriseWorkstationCard(
        width: cardWidth,
        title: 'CLINICAL TOOLS & CALCULATORS',
        subtitle: 'Precision Calorie intake (BMR/TDEE), Macronutrient ratios, 1RM, and BMI health',
        icon: Icons.calculate_rounded,
        badge: 'CLINICAL',
        isHighlight: false,
        moduleTag: 'TITAN // CLINICAL TOOLS',
        dragHandle: dragHandle,
        telemetryPills: const [
          'BMR / TDEE Calculator',
          '1RM Estimator',
          'Macronutrient Splitter',
        ],
        onTap: isFeedback ? () {} : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalculatorsHubScreen())),
      );
  }
}
