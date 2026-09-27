import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/store/presentation/providers/store_providers.dart';

/// Mini live preview matching the exact signature layout of OwnerOrderCard in GymOwnerStoreOrdersScreen.
class MiniStoreOrdersPreview extends ConsumerWidget {
  final String tenantId;

  const MiniStoreOrdersPreview({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final ordersAsync = ref.watch(tenantStoreOrdersProvider(tenantId));

    return Container(
      color: const Color(0xFF0F0F13),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ordersAsync.maybeWhen(
        data: (orders) {
          final order = orders.isNotEmpty ? orders.first : null;
          final isPending = order == null || order.orderStatus.toLowerCase() == 'pending';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Pickup Code Pill + Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      order != null ? 'PICKUP: ${order.pickupCode}' : 'PICKUP: PK-9912',
                      style: GoogleFonts.jetBrainsMono(fontSize: 8, fontWeight: FontWeight.bold, color: accent),
                    ),
                  ),
                  Text(
                    order != null ? 'PKR ${order.totalAmount.toStringAsFixed(0)}' : 'PKR 18,500',
                    style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Customer & Item Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_rounded, size: 12, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order != null
                            ? '${order.customerName} • ${order.items.isNotEmpty ? order.items.first.productName : "Optimum Nutrition Whey"}'
                            : 'Zain Malik • Optimum Nutrition Gold Whey',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Bottom Actions: Status Pill + Iconic Dispatch Button
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPending ? Colors.amber : Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isPending ? 'PENDING DISPATCH' : 'COMPLETED',
                            style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, color: isPending ? Colors.amber : Colors.greenAccent),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DISPATCH ORDER',
                          style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        orElse: () => Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2)),
      ),
    );
  }
}
