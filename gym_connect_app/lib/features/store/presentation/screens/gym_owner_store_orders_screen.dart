import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/store_providers.dart';
import '../widgets/owner_order_card.dart';

class GymOwnerStoreOrdersScreen extends ConsumerWidget {
  final String tenantId;

  const GymOwnerStoreOrdersScreen({super.key, required this.tenantId});

  static Future<void> open(BuildContext context, {required String tenantId}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GymOwnerStoreOrdersScreen(tenantId: tenantId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(tenantStoreOrdersProvider(tenantId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('STORE ORDERS & DISPATCH', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(tenantStoreOrdersProvider(tenantId)),
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
                        const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text('NO STORE ORDERS', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('Incoming member & customer supplement orders appear here.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final order = orders[i];
                return OwnerOrderCard(
                  order: order,
                  onSchedule: (status, readyDate, readyTime) async {
                    await ref.read(storeActionNotifierProvider.notifier).updateOrderSchedule(
                          orderId: order.id,
                          tenantId: tenantId,
                          status: 'ready_for_pickup',
                          estimatedReadyDate: readyDate,
                          estimatedReadyTime: readyTime,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order ready schedule updated! Customer notified.')));
                    }
                  },
                  onComplete: () async {
                    await ref.read(storeActionNotifierProvider.notifier).updateOrderSchedule(
                          orderId: order.id,
                          tenantId: tenantId,
                          status: 'completed',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as collected/completed.')));
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
