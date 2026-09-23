import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/presentation/widgets/receipt_image_viewer_dialog.dart';
import '../../data/store_repository.dart';
import 'owner_order_schedule_dialog.dart';

class OwnerOrderDetailsDialog extends StatelessWidget {
  final StoreOrder order;
  final Function(String status, String readyDate, String readyTime) onSchedule;
  final VoidCallback onComplete;

  const OwnerOrderDetailsDialog({
    super.key,
    required this.order,
    required this.onSchedule,
    required this.onComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required StoreOrder order,
    required Function(String status, String readyDate, String readyTime) onSchedule,
    required VoidCallback onComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OwnerOrderDetailsDialog(
        order: order,
        onSchedule: onSchedule,
        onComplete: onComplete,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard', style: GoogleFonts.inter(fontSize: 12)),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasReceipt = order.paymentReceiptUrl != null && order.paymentReceiptUrl!.isNotEmpty;
    final isDone = order.orderStatus.toLowerCase() == 'completed';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    Color statusColor;
    String statusLabel;
    switch (order.orderStatus.toLowerCase()) {
      case 'ready_for_pickup':
        statusColor = Colors.cyanAccent;
        statusLabel = 'READY FOR PICKUP';
        break;
      case 'completed':
        statusColor = Colors.greenAccent;
        statusLabel = 'COMPLETED / COLLECTED';
        break;
      case 'cancelled':
        statusColor = Colors.redAccent;
        statusLabel = 'CANCELLED';
        break;
      default:
        statusColor = Colors.amber;
        statusLabel = 'PENDING VERIFICATION';
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDER #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                      style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Placed on ${order.createdAt.toLocal().toString().split('.').first}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Customer Information Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text('CUSTOMER DETAILS', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(order.customerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                              InkWell(
                                onTap: () => _copyToClipboard(context, order.customerPhone!, 'Customer Phone'),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone_rounded, color: AppColors.primary, size: 14),
                                      const SizedBox(width: 4),
                                      Text(order.customerPhone!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 12),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                order.isDelivery ? Icons.local_shipping_outlined : Icons.storefront_rounded,
                                size: 16,
                                color: order.isDelivery ? Colors.amber : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order.isDelivery
                                      ? 'Delivery: ${order.deliveryAddress ?? "Address not provided"}'
                                      : 'Gym Pickup Code: ${order.pickupCode}',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment Proof Section (Large Thumbnail Preview)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasReceipt ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
                        width: hasReceipt ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.receipt_long_rounded, color: hasReceipt ? AppColors.primary : AppColors.textSecondary, size: 18),
                                const SizedBox(width: 8),
                                Text('PAYMENT PROOF & RECEIPT', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (hasReceipt ? AppColors.primary : Colors.white10).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hasReceipt ? 'RECEIPT ATTACHED' : order.paymentMethod.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: hasReceipt ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (hasReceipt) ...[
                          InkWell(
                            onTap: () => ReceiptImageViewerDialog.show(
                              context,
                              imageUrl: order.paymentReceiptUrl!,
                              memberName: order.customerName,
                              amount: order.totalAmount,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Image.network(
                                    order.paymentReceiptUrl!,
                                    height: 220,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (_, child, p) => p == null ? child : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
                                    errorBuilder: (_, _, _) => Container(
                                      height: 120,
                                      color: Colors.black26,
                                      child: const Center(child: Text('Unable to load receipt image', style: TextStyle(color: Colors.white54))),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    color: Colors.black.withValues(alpha: 0.75),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.fullscreen_rounded, color: AppColors.primary, size: 18),
                                        const SizedBox(width: 6),
                                        Text('TAP TO EXPAND & ZOOM RECEIPT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please verify the transaction ID, date, and amount match PKR ${order.totalAmount.toInt()} before dispatching.',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No screenshot attached. Payment method: ${order.paymentMethod.toUpperCase()} (Collect cash upon handover).',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Items Ordered Breakdown
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ORDERED ITEMS (${order.items.length})', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('TOTAL: PKR ${order.totalAmount.toInt()}', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                        Text('Qty: ${item.quantity} × PKR ${item.unitPrice.toInt()}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Text('PKR ${item.totalPrice.toInt()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),

                  if (order.estimatedReadyDate != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Scheduled Ready Time: ${order.estimatedReadyDate} (${order.estimatedReadyTime ?? "Anytime"})',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Buttons
          if (!isDone)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      OwnerOrderScheduleDialog.show(context, order: order, onSchedule: onSchedule);
                    },
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text('SCHEDULE READY TIME', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onComplete();
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text('MARK COMPLETED', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('CLOSE DETAILS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
