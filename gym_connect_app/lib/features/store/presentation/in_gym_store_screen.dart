import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/domain/models/user_role.dart';
import '../../auth/presentation/providers/auth_notifier.dart';
import '../../auth/presentation/providers/auth_state.dart';
import '../../../core/theme/app_colors.dart';
import '../data/store_repository.dart';
import 'providers/store_providers.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/store_checkout_screen.dart';
import 'widgets/add_product_dialog.dart';
import 'widgets/store_cart_sheet.dart';
import 'widgets/store_catalog_view.dart';

class InGymStoreScreen extends ConsumerStatefulWidget {
  const InGymStoreScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InGymStoreScreen()),
    );
  }

  @override
  ConsumerState<InGymStoreScreen> createState() => _InGymStoreScreenState();
}

class _InGymStoreScreenState extends ConsumerState<InGymStoreScreen> {
  final Map<String, int> _cart = {};
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Supplements', 'Drinks', 'Juice Bar', 'Snacks', 'Gear'];

  double _calculateTotal(List<StoreProduct> products) {
    double total = 0.0;
    _cart.forEach((id, qty) {
      final p = products.where((item) => item.id == id).firstOrNull;
      if (p != null) total += p.price * qty;
    });
    return total;
  }

  void _updateCart(String id, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.remove(id);
      } else {
        _cart[id] = qty;
      }
    });
  }

  void _openCheckout(List<StoreProduct> products) {
    StoreCheckoutScreen.open(
      context,
      cart: _cart,
      allProducts: products,
      totalAmount: _calculateTotal(products),
      onOrderPlaced: () => setState(() => _cart.clear()),
    );
  }

  void _openCartSheet(List<StoreProduct> products) {
    StoreCartSheet.show(
      context,
      cart: _cart,
      allProducts: products,
      totalAmount: _calculateTotal(products),
      onClearCart: () => setState(() => _cart.clear()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(storeProductsProvider);
    final viewMode = ref.watch(storeViewModeProvider);
    final isGrid = viewMode == StoreViewMode.grid;
    final accent = Theme.of(context).colorScheme.primary;

    final authState = ref.watch(authNotifierProvider);
    final isOwnerOrStaff = (authState is AuthAuthenticated) &&
        (authState.activeRole == UserRole.owner || authState.activeRole == UserRole.staff);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'PRO STORE & POS REGISTER',
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ENTERPRISE WORKSTATION',
                  style: GoogleFonts.oswald(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: accent,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isOwnerOrStaff)
            IconButton(
              tooltip: 'Add New Product',
              icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              onPressed: () => AddProductDialog.show(context),
            ),
          IconButton(
            tooltip: isGrid ? 'Switch to List View' : 'Switch to Grid View',
            icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded, color: AppColors.primary),
            onPressed: () => ref.read(storeViewModeProvider.notifier).toggle(),
          ),
          IconButton(
            tooltip: 'Track My Orders',
            icon: const Icon(Icons.local_shipping_outlined, color: AppColors.textPrimary),
            onPressed: () => OrderTrackingScreen.open(context),
          ),
          // Mobile cart icon
          if (!isDesktop)
            productsAsync.maybeWhen(
              data: (products) {
                final count = _cart.values.fold<int>(0, (sum, q) => sum + q);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_rounded, color: AppColors.textPrimary),
                      onPressed: count > 0 ? () => _openCartSheet(products) : null,
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: productsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error loading store: $err', style: const TextStyle(color: Colors.redAccent))),
        data: (products) {
          final catalogWidget = StoreCatalogView(
            products: products,
            isGridView: isGrid,
            cart: _cart,
            searchQuery: _searchQuery,
            selectedCategory: _selectedCategory,
            categories: _categories,
            onSearchChanged: (val) => setState(() => _searchQuery = val.trim()),
            onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
            onAddToCart: (id, current) => _updateCart(id, current + 1),
            onRemoveFromCart: (id, current) => _updateCart(id, current - 1),
          );

          if (!isDesktop) {
            return catalogWidget;
          }

          // Desktop Split Layout (Catalog + Right-Side POS Register Drawer)
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: catalogWidget),
              Container(
                width: 380,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(left: BorderSide(color: AppColors.border, width: 1.5)),
                ),
                child: _buildDesktopRegisterDrawer(context, products, accent),
              ),
            ],
          );
        },
      ),
      // Mobile bottom bar only when on small screen & cart not empty
      bottomNavigationBar: (!isDesktop)
          ? productsAsync.maybeWhen(
              data: (products) {
                final count = _cart.values.fold<int>(0, (sum, q) => sum + q);
                if (count == 0) return const SizedBox.shrink();
                final total = _calculateTotal(products);
                return Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openCheckout(products),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$count ITEMS IN CART', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('CHECKOUT • PKR ${total.toInt()} ➔', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            )
          : null,
    );
  }

  Widget _buildDesktopRegisterDrawer(
    BuildContext context,
    List<StoreProduct> products,
    Color accent,
  ) {
    final count = _cart.values.fold<int>(0, (sum, q) => sum + q);
    final total = _calculateTotal(products);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drawer Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.point_of_sale_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POS REGISTER CART',
                      style: GoogleFonts.oswald(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$count ${count == 1 ? 'item' : 'items'} in current session',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (_cart.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _cart.clear()),
                  child: Text(
                    'CLEAR',
                    style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),

        // Cart Items List or Empty State
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.shopping_bag_outlined, color: AppColors.textSecondary, size: 36),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'REGISTER CART IS EMPTY',
                          style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Click "+ ADD" on any product from the catalog to ring up an order.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cart.entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = _cart.entries.elementAt(index);
                    final p = products.where((item) => item.id == entry.key).firstOrNull;
                    if (p == null) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              p.effectiveImageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stackTrace) => Container(
                                width: 44,
                                height: 44,
                                color: AppColors.surface,
                                child: const Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'PKR ${p.price.toInt()} each',
                                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _updateCart(p.id, entry.value - 1),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.remove, size: 14, color: Colors.white),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '${entry.value}',
                                  style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              InkWell(
                                onTap: () => _updateCart(p.id, entry.value + 1),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.add, size: 14, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Bottom Totals & Charge Button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SUBTOTAL:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  Text('PKR ${total.toInt()}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL AMOUNT:',
                    style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'PKR ${total.toInt()}',
                    style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _cart.isEmpty ? null : () => _openCheckout(products),
                  icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                  label: Text(
                    'CHARGE & CHECKOUT • PKR ${total.toInt()}',
                    style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
