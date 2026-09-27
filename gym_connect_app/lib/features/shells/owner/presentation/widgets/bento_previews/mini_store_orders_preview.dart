import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';
import 'package:gym_connect_app/features/store/presentation/providers/store_providers.dart';

/// 1:1 exact scaled live preview of GymOwnerStoreOrdersScreen matching user screenshot.
class MiniStoreOrdersPreview extends ConsumerWidget {
  final String tenantId;

  const MiniStoreOrdersPreview({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final ordersAsync = ref.watch(tenantStoreOrdersProvider(tenantId));
    final viewMode = ref.watch(storeViewModeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Container(
          width: 1024,
          height: 492,
          color: const Color(0xFF09090B),
          child: ordersAsync.maybeWhen(
            data: (orders) => _buildLiveScreen(orders, viewMode, accent),
            orElse: () => _buildLiveScreen([], viewMode, accent),
          ),
        );

        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: 1024,
            height: 492,
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildLiveScreen(
    List<StoreOrder> orders,
    StoreViewMode viewMode,
    Color accent,
  ) {
    final pendingCount =
        orders.where((o) => o.orderStatus.toLowerCase() == 'pending').length;
    final readyCount = orders
        .where((o) => o.orderStatus.toLowerCase() == 'ready_for_pickup')
        .length;
    final completedCount =
        orders.where((o) => o.orderStatus.toLowerCase() == 'completed').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top AppBar Row
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.surface,
          child: Row(
            children: [
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                'STORE ORDERS & DISPATCH',
                style: GoogleFonts.oswald(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${orders.length} ORDERS',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              if (pendingCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    '$pendingCount PENDING DISPATCH',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 2. Subheader Filter & View Mode Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Row 1: Search Input + Dual-View Switch
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Search orders by customer name, phone, pickup code, product...',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewBadge(
                          icon: Icons.grid_view_rounded,
                          label: 'Grid View',
                          isSelected: viewMode == StoreViewMode.grid,
                          accent: accent,
                        ),
                        const SizedBox(width: 2),
                        _buildViewBadge(
                          icon: Icons.view_list_rounded,
                          label: 'List View',
                          isSelected: viewMode == StoreViewMode.list,
                          accent: accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Status Filter Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabChip('ALL', orders.length, true, accent),
                  const SizedBox(width: 6),
                  _buildTabChip('PENDING', pendingCount, false, accent),
                  const SizedBox(width: 6),
                  _buildTabChip(
                      'READY FOR PICKUP', readyCount, false, accent),
                  const SizedBox(width: 6),
                  _buildTabChip('COMPLETED', completedCount, false, accent),
                ],
              ),
            ],
          ),
        ),

        // 3. Orders Catalog Grid / List Body
        Expanded(
          child: Container(
            color: const Color(0xFF09090B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: viewMode == StoreViewMode.list
                ? _buildListView(orders, accent)
                : _buildGridView(orders, accent),
          ),
        ),
      ],
    );
  }

  Widget _buildViewBadge({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? accent.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isSelected ? accent.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isSelected ? accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(
      String label, int count, bool isSelected, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isSelected ? accent.withValues(alpha: 0.16) : AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? accent : AppColors.border,
          width: isSelected ? 1.3 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? accent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<StoreOrder> orders, Color accent) {
    final displayList = orders.take(6).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int col = 0; col < 3; col++) ...[
          Expanded(
            child: Column(
              children: [
                if (col < displayList.length)
                  Expanded(
                    child: _buildOrderMiniCard(displayList[col], accent),
                  ),
                const SizedBox(height: 10),
                if (col + 3 < displayList.length)
                  Expanded(
                    child: _buildOrderMiniCard(displayList[col + 3], accent),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
          if (col < 2) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildOrderMiniCard(StoreOrder order, Color accent) {
    final status = order.orderStatus.toLowerCase();
    final isDone = status == 'completed';
    final isReady = status == 'ready_for_pickup';
    final Color statusColor = isDone
        ? Colors.greenAccent
        : (isReady ? const Color(0xFF38BDF8) : Colors.amberAccent);
    final String statusText = isDone
        ? 'COMPLETED'
        : (isReady ? 'READY FOR PICKUP' : 'PENDING');
    final hasReceipt = order.paymentReceiptUrl != null &&
        order.paymentReceiptUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Name + Code + Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.customerName.toUpperCase(),
                      style: GoogleFonts.oswald(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      order.isDelivery ? 'DELIVERY' : order.pickupCode,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${order.items.length} Product(s)',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Middle: Products / Proof indicator
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  hasReceipt
                      ? Icons.receipt_long_rounded
                      : Icons.inventory_2_outlined,
                  size: 13,
                  color: accent,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    order.items.isNotEmpty
                        ? '${order.items.first.quantity}x ${order.items.first.productName}'
                        : 'Store Product Order',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer: Price + Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PKR ${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.oswald(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (!isDone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'DISPATCH ORDER',
                    style: GoogleFonts.inter(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'COMPLETED',
                    style: GoogleFonts.inter(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<StoreOrder> orders, Color accent) {
    final displayList = orders.take(4).toList();

    return Column(
      children: [
        for (final order in displayList) ...[
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.pickupCode,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          order.customerName.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          order.items.isNotEmpty
                              ? order.items.first.productName
                              : 'Order item',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'PKR ${order.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.oswald(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.orderStatus.toLowerCase() == 'completed'
                          ? Colors.greenAccent.withValues(alpha: 0.15)
                          : accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.orderStatus.toLowerCase() == 'completed'
                          ? 'FULFILLED'
                          : 'DISPATCH',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: order.orderStatus.toLowerCase() == 'completed'
                            ? Colors.greenAccent
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
