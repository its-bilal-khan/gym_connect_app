import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/presentation/widgets/receipt_image_viewer_dialog.dart';
import '../../data/store_repository.dart';
import 'owner_order_details_dialog.dart';
import 'owner_order_schedule_dialog.dart';

class OwnerOrderListRow extends StatefulWidget {
  final StoreOrder order;
  final Function(String status, String readyDate, String readyTime) onSchedule;
  final VoidCallback onComplete;

  const OwnerOrderListRow({
    super.key,
    required this.order,
    required this.onSchedule,
    required this.onComplete,
  });

  @override
  State<OwnerOrderListRow> createState() => _OwnerOrderListRowState();
}

class _OwnerOrderListRowState extends State<OwnerOrderListRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final order = widget.order;
    final hasReceipt = order.paymentReceiptUrl != null &&
        order.paymentReceiptUrl!.isNotEmpty;
    final status = order.orderStatus.toLowerCase();
    final isDone = status == 'completed';
    final isReady = status == 'ready_for_pickup';

    final Color statusColor = isDone
        ? Colors.greenAccent
        : (isReady ? const Color(0xFF38BDF8) : Colors.amberAccent);
    final String statusText = isDone
        ? 'COMPLETED'
        : (isReady ? 'READY FOR PICKUP' : 'PENDING');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => OwnerOrderDetailsDialog.show(
          context,
          order: order,
          onSchedule: widget.onSchedule,
          onComplete: widget.onComplete,
        ),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? accent : AppColors.border,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? accent.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: _isHovered ? 12 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Pickup Code Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Text(
                  order.isDelivery ? 'DELIVERY' : order.pickupCode,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Customer Details & Products
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.customerName.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.items.isNotEmpty
                          ? order.items
                              .map((i) => '${i.quantity}x ${i.productName}')
                              .join(', ')
                          : '${order.items.length} Product(s)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Schedule info
              if (order.estimatedReadyDate != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        '${order.estimatedReadyDate}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Receipt Icon (if attached)
              if (hasReceipt) ...[
                Tooltip(
                  message: 'View payment receipt',
                  child: InkWell(
                    onTap: () => ReceiptImageViewerDialog.show(
                      context,
                      imageUrl: order.paymentReceiptUrl!,
                      memberName: order.customerName,
                      amount: order.totalAmount,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.receipt_rounded,
                          size: 16, color: accent),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],

              // Total Price
              Text(
                'PKR ${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.oswald(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),

              // Actions
              if (!isDone)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => OwnerOrderScheduleDialog.show(
                        context,
                        order: order,
                        onSchedule: widget.onSchedule,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accent.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'SCHEDULE',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: widget.onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'COMPLETE',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 13, color: Colors.greenAccent),
                      const SizedBox(width: 4),
                      Text(
                        'FULFILLED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
