import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/presentation/widgets/receipt_image_viewer_dialog.dart';
import '../../data/store_repository.dart';
import 'owner_order_details_dialog.dart';
import 'owner_order_schedule_dialog.dart';

class OwnerOrderCard extends StatelessWidget {
  final StoreOrder order;
  final Function(String status, String readyDate, String readyTime) onSchedule;
  final VoidCallback onComplete;

  const OwnerOrderCard({
    super.key,
    required this.order,
    required this.onSchedule,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final hasReceipt = order.paymentReceiptUrl != null && order.paymentReceiptUrl!.isNotEmpty;
    final isDone = order.orderStatus.toLowerCase() == 'completed';

    return InkWell(
      onTap: () => OwnerOrderDetailsDialog.show(
        context,
        order: order,
        onSchedule: onSchedule,
        onComplete: onComplete,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.customerName.toUpperCase(), style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  order.isDelivery ? 'DELIVERY' : 'PICKUP: ${order.pickupCode}',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.customerPhone ?? "No Phone"} • Status: ${order.orderStatus.toUpperCase()}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (order.estimatedReadyDate != null) ...[
            const SizedBox(height: 6),
            Text(
              'Scheduled: ${order.estimatedReadyDate} (${order.estimatedReadyTime ?? ""})',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${order.items.length} product(s) ordered', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              Text('PKR ${order.totalAmount.toInt()}', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          if (hasReceipt) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => ReceiptImageViewerDialog.show(context, imageUrl: order.paymentReceiptUrl!, memberName: order.customerName, amount: order.totalAmount),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(order.paymentReceiptUrl!, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.receipt, color: Colors.white38)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Payment Proof Screenshot Attached (Tap to inspect)', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!isDone) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => OwnerOrderScheduleDialog.show(context, order: order, onSchedule: onSchedule),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text('SCHEDULE READY TIME', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text('COMPLETE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }
}
