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

  void _openCheckout(List<StoreProduct> products) {
    StoreCheckoutScreen.open(
      context,
      cart: _cart,
      allProducts: products,
      totalAmount: _calculateTotal(products),
      onOrderPlaced: () => setState(() => _cart.clear()),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('PRO STORE & SHAKES', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          if (isOwnerOrStaff)
            IconButton(
              tooltip: 'Add New Product',
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error loading store: $err', style: const TextStyle(color: Colors.redAccent))),
        data: (products) => StoreCatalogView(
          products: products,
          isGridView: isGrid,
          cart: _cart,
          searchQuery: _searchQuery,
          selectedCategory: _selectedCategory,
          categories: _categories,
          onSearchChanged: (val) => setState(() => _searchQuery = val.trim()),
          onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
          onAddToCart: (id, current) => setState(() => _cart[id] = current + 1),
        ),
      ),
      bottomNavigationBar: productsAsync.maybeWhen(
        data: (products) {
          final count = _cart.values.fold<int>(0, (sum, q) => sum + q);
          if (count == 0) return const SizedBox.shrink();
          final total = _calculateTotal(products);
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
      ),
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
}
