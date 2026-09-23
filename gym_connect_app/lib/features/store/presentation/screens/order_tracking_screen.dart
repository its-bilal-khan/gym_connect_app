import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';
import '../providers/store_providers.dart';
import '../widgets/order_status_stepper.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String? initialOrderId;

  const OrderTrackingScreen({super.key, this.initialOrderId});

  static Future<void> open(BuildContext context, {String? initialOrderId}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(initialOrderId: initialOrderId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('ORDER TRACKING & PICKUP', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(customerOrdersProvider),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text('Error loading orders: $err', style: GoogleFonts.inter(color: Colors.white))),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text('NO ACTIVE ORDERS', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('Orders placed in the Pro Shop will appear here.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, i) => _buildOrderCard(orders[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(StoreOrder order) {
    final hasSchedule = order.estimatedReadyDate != null && order.estimatedReadyDate!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  order.isDelivery ? 'HOME DELIVERY' : 'PICKUP: ${order.pickupCode}',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              Text('PKR ${order.totalAmount.toInt()}', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          if (hasSchedule) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ready For ${order.isDelivery ? "Delivery" : "Pickup"}: ${order.estimatedReadyDate} (${order.estimatedReadyTime ?? "Standard Hours"})',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          OrderStatusStepper(
            status: order.orderStatus,
            isDelivery: order.isDelivery,
            readyDate: order.estimatedReadyDate,
            readyTime: order.estimatedReadyTime,
          ),
          if (order.isDelivery && order.deliveryAddress != null) ...[
            const SizedBox(height: 14),
            Text('Delivery Address: ${order.deliveryAddress}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
