import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';
import '../providers/store_providers.dart';
import '../widgets/owner_order_grid_card.dart';
import '../widgets/owner_order_list_row.dart';
import '../widgets/store_view_mode_toggle.dart';

class GymOwnerStoreOrdersScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const GymOwnerStoreOrdersScreen({super.key, required this.tenantId});

  static Future<void> open(BuildContext context, {required String tenantId}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GymOwnerStoreOrdersScreen(tenantId: tenantId),
      ),
    );
  }

  @override
  ConsumerState<GymOwnerStoreOrdersScreen> createState() =>
      _GymOwnerStoreOrdersScreenState();
}

class _GymOwnerStoreOrdersScreenState
    extends ConsumerState<GymOwnerStoreOrdersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatus = 'ALL';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StoreOrder> _filterOrders(List<StoreOrder> orders) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return orders.where((order) {
      final matchesQuery = query.isEmpty ||
          order.customerName.toLowerCase().contains(query) ||
          (order.customerPhone?.toLowerCase().contains(query) ?? false) ||
          order.pickupCode.toLowerCase().contains(query) ||
          order.items.any((i) => i.productName.toLowerCase().contains(query));

      bool matchesStatus = true;
      final st = order.orderStatus.toLowerCase();
      if (_selectedStatus == 'PENDING') {
        matchesStatus = st == 'pending';
      } else if (_selectedStatus == 'READY FOR PICKUP') {
        matchesStatus = st == 'ready_for_pickup';
      } else if (_selectedStatus == 'COMPLETED') {
        matchesStatus = st == 'completed';
      }

      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final ordersAsync = ref.watch(tenantStoreOrdersProvider(widget.tenantId));
    final viewMode = ref.watch(storeViewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'STORE ORDERS & DISPATCH',
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ordersAsync.maybeWhen(
              data: (orders) {
                final pendingCount = orders
                    .where((o) => o.orderStatus.toLowerCase() == 'pending')
                    .length;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        '${orders.length} ORDERS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color:
                                  Colors.amberAccent.withValues(alpha: 0.45)),
                        ),
                        child: Text(
                          '$pendingCount PENDING DISPATCH',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Subheader Filter & Dual-View Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Top row: Search input + View mode toggle
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText:
                                'Search orders by customer name, phone, pickup code, product...',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textSecondary,
                              size: 19,
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textSecondary,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Dual-View Segmented Toggle Switch (Rule 5)
                    StoreViewModeToggle(
                      currentMode: viewMode,
                      onModeChanged: (mode) {
                        ref.read(storeViewModeProvider.notifier).setMode(mode);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom row: Status Filter Tabs
                ordersAsync.maybeWhen(
                  data: (orders) {
                    final allCount = orders.length;
                    final pendingCount = orders
                        .where((o) => o.orderStatus.toLowerCase() == 'pending')
                        .length;
                    final readyCount = orders
                        .where((o) =>
                            o.orderStatus.toLowerCase() == 'ready_for_pickup')
                        .length;
                    final completedCount = orders
                        .where(
                            (o) => o.orderStatus.toLowerCase() == 'completed')
                        .length;

                    final tabs = [
                      {'label': 'ALL', 'count': allCount},
                      {'label': 'PENDING', 'count': pendingCount},
                      {'label': 'READY FOR PICKUP', 'count': readyCount},
                      {'label': 'COMPLETED', 'count': completedCount},
                    ];

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: tabs.map((tab) {
                          final label = tab['label'] as String;
                          final count = tab['count'] as int;
                          final isSelected = _selectedStatus == label;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedStatus = label),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accent.withValues(alpha: 0.16)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? accent
                                        : AppColors.border,
                                    width: isSelected ? 1.4 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? accent
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? accent.withValues(alpha: 0.3)
                                            : Colors.white
                                                .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Main Orders Listing (Reactive Grid or List)
          Expanded(
            child: RefreshIndicator(
              color: accent,
              onRefresh: () async =>
                  ref.invalidate(tenantStoreOrdersProvider(widget.tenantId)),
              child: ordersAsync.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: accent)),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load store orders',
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$err',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                data: (orders) {
                  final filtered = _filterOrders(orders);

                  if (orders.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'NO STORE ORDERS',
                      subtitle:
                          'Incoming member & customer supplement orders appear here in real-time.',
                    );
                  }

                  if (filtered.isEmpty) {
                    return _buildEmptySearchResults(accent);
                  }

                  if (viewMode == StoreViewMode.grid) {
                    return _buildGridView(filtered);
                  } else {
                    return _buildListView(filtered);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<StoreOrder> orders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width < 760) {
          crossAxisCount = 1;
        } else if (width < 1200) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 280,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return OwnerOrderGridCard(
              order: order,
              onSchedule: (status, readyDate, readyTime) =>
                  _handleSchedule(order, status, readyDate, readyTime),
              onComplete: () => _handleComplete(order),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<StoreOrder> orders) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return OwnerOrderListRow(
          order: order,
          onSchedule: (status, readyDate, readyTime) =>
              _handleSchedule(order, status, readyDate, readyTime),
          onComplete: () => _handleComplete(order),
        );
      },
    );
  }

  Future<void> _handleSchedule(
    StoreOrder order,
    String status,
    String readyDate,
    String readyTime,
  ) async {
    await ref.read(storeActionNotifierProvider.notifier).updateOrderSchedule(
          orderId: order.id,
          tenantId: widget.tenantId,
          status: 'ready_for_pickup',
          estimatedReadyDate: readyDate,
          estimatedReadyTime: readyTime,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order schedule updated! Customer notified.'),
        ),
      );
    }
  }

  Future<void> _handleComplete(StoreOrder order) async {
    await ref.read(storeActionNotifierProvider.notifier).updateOrderSchedule(
          orderId: order.id,
          tenantId: widget.tenantId,
          status: 'completed',
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as collected/fulfilled.'),
        ),
      );
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, size: 54, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySearchResults(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'NO MATCHING ORDERS FOUND',
            style: GoogleFonts.oswald(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search query or selecting a different status filter.',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _selectedStatus = 'ALL');
            },
            child: Text(
              'CLEAR FILTERS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
