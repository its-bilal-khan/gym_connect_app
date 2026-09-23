import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class OrderStatusStepper extends StatelessWidget {
  final String status;
  final bool isDelivery;
  final String? readyDate;
  final String? readyTime;

  const OrderStatusStepper({
    super.key,
    required this.status,
    required this.isDelivery,
    this.readyDate,
    this.readyTime,
  });

  int get _stepIndex {
    switch (status.toLowerCase()) {
      case 'completed':
        return 3;
      case 'ready_for_pickup':
        return 2;
      case 'confirmed':
        return 1;
      case 'pending':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _stepIndex;
    final steps = [
      {'title': 'Order Placed', 'desc': 'Payment proof received'},
      {'title': 'Payment Verified', 'desc': 'Gym staff preparing items'},
      {'title': isDelivery ? 'Out for Delivery' : 'Ready for Pickup', 'desc': readyDate != null ? '$readyDate • ${readyTime ?? ""}' : 'Awaiting schedule'},
      {'title': isDelivery ? 'Delivered' : 'Collected', 'desc': 'Completed & closed'},
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final isDone = i <= current;
        final isCurrent = i == current;
        final isLast = i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.primary : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDone ? AppColors.primary : AppColors.border, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      isDone ? Icons.check_rounded : Icons.circle_rounded,
                      size: isDone ? 14 : 6,
                      color: isDone ? Colors.black : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 34,
                    color: i < current ? AppColors.primary : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[i]['title']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: isDone ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    steps[i]['desc']!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isCurrent && i == 2 && readyDate != null ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isCurrent && i == 2 && readyDate != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
