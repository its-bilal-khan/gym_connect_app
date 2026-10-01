import 'package:flutter/material.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/calculators/presentation/screens/calculators_hub_screen.dart';
import 'package:gym_connect_app/features/members/presentation/screens/desktop_member_hub_screen.dart';
import 'package:gym_connect_app/features/payments/presentation/screens/gym_owner_payment_approvals_screen.dart';
import 'package:gym_connect_app/features/store/presentation/screens/gym_owner_product_management_screen.dart';
import 'package:gym_connect_app/features/store/presentation/screens/gym_owner_store_orders_screen.dart';
import 'package:gym_connect_app/features/workout/presentation/desktop/desktop_workout_protocol_manager_view.dart';
import '../../domain/models/workstation_item.dart';
import 'bento_previews/bento_workstation_card.dart';
import 'bento_previews/mini_calculators_hub_preview.dart';
import 'bento_previews/mini_member_table_preview.dart';
import 'bento_previews/mini_payment_approvals_preview.dart';
import 'bento_previews/mini_pro_shop_inventory_preview.dart';
import 'bento_previews/mini_store_orders_preview.dart';
import 'bento_previews/mini_workout_protocol_preview.dart';

Widget buildBentoCard({
  required BuildContext context,
  required WorkstationId id,
  required double cardWidth,
  required UserProfile profile,
  required String tenantId,
  required int pendingPayments,
  required int pendingOrders,
  required Widget? dragHandle,
  required bool isFeedback,
}) {
  switch (id) {
    case WorkstationId.members:
      return BentoWorkstationCard(
        width: cardWidth,
        title: 'MEMBERS DIRECTORY & EXCEL INGESTION [DESKTOP]',
        subtitle: 'Batch Excel/CSV upload, database schema sync & workout telemetry',
        icon: Icons.groups_rounded,
        badge: 'MEMBERS',
        isHighlight: true,
        moduleTag: 'TITAN // MEMBERS HUB',
        dragHandle: dragHandle,
        onTap: isFeedback ? () {} : () => DesktopMemberHubScreen.open(context, profile: profile),
        previewWidget: MiniMemberTablePreview(tenantId: tenantId),
      );
    case WorkstationId.workout:
      return BentoWorkstationCard(
        width: cardWidth,
        title: 'WORKOUT PROTOCOL STUDIO [DESKTOP]',
        subtitle: 'Calibrate Ectomorph, Mesomorph, Endomorph schedules & exercises',
        icon: Icons.fitness_center_rounded,
        badge: 'STUDIO',
        isHighlight: true,
        moduleTag: 'TITAN // PROTOCOL STUDIO',
        dragHandle: dragHandle,
        onTap: isFeedback ? () {} : () => DesktopWorkoutProtocolManagerView.open(context, profile: profile),
        previewWidget: MiniWorkoutProtocolPreview(tenantId: tenantId),
      );
    case WorkstationId.storeOrders:
      return BentoWorkstationCard(
        width: cardWidth,
        title: 'STORE ORDERS & DISPATCH',
        subtitle: pendingOrders > 0 ? '$pendingOrders order(s) waiting to prepare & dispatch' : 'All orders fulfilled',
        icon: Icons.inventory_2_rounded,
        badge: pendingOrders > 0 ? '$pendingOrders NEW' : 'LIVE',
        isHighlight: pendingOrders > 0,
        moduleTag: 'TITAN // STORE DISPATCH',
        dragHandle: dragHandle,
        onTap: isFeedback ? () {} : () => GymOwnerStoreOrdersScreen.open(context, tenantId: tenantId),
        previewWidget: MiniStoreOrdersPreview(tenantId: tenantId),
      );
    case WorkstationId.proShop:
      return BentoWorkstationCard(
        width: cardWidth,
        title: 'PRO SHOP & INVENTORY MANAGER',
        subtitle: 'Upload product photos, set Pakistani pricing, adjust supplement stock',
        icon: Icons.storefront_rounded,
        badge: 'POS STORE',
        isHighlight: false,
        moduleTag: 'TITAN // PRO SHOP',
        dragHandle: dragHandle,
        onTap: isFeedback ? () {} : () => GymOwnerProductManagementScreen.open(context, tenantId: tenantId),
        previewWidget: MiniProShopInventoryPreview(tenantId: tenantId),
      );
    case WorkstationId.payments:
      return BentoWorkstationCard(
        width: cardWidth,
        title: 'PENDING PROOF-OF-PAYMENTS',
        subtitle: pendingPayments > 0 ? '$pendingPayments transfer slip(s) pending review' : 'All payments reconciled',
        icon: Icons.receipt_long_rounded,
        badge: pendingPayments > 0 ? '$pendingPayments PENDING' : 'CLEAR',
        isHighlight: pendingPayments > 0,
        moduleTag: 'TITAN // PAYMENT AUDIT',
        dragHandle: dragHandle,
        onTap: isFeedback ? () {} : () => GymOwnerPaymentApprovalsScreen.open(context, tenantId: tenantId),
        previewWidget: MiniPaymentApprovalsPreview(tenantId: tenantId),
      );
    case WorkstationId.tools:
      return BentoWorkstationCard(
        width: cardWidth,
        title: 'CLINICAL TOOLS & CALCULATORS',
        subtitle: 'BMR/TDEE intake, Macronutrient ratios, 1RM, and BMI health analysis',
        icon: Icons.calculate_rounded,
        badge: 'TOOLS',
        isHighlight: false,
        moduleTag: 'TITAN // CLINICAL TOOLS',
        dragHandle: dragHandle,
        onTap: isFeedback ? () {} : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalculatorsHubScreen())),
        previewWidget: const MiniCalculatorsHubPreview(),
      );
  }
}
