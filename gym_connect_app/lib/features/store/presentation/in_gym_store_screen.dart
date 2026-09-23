import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../data/store_repository.dart';
import 'product_detail_screen.dart';
import 'widgets/store_cart_sheet.dart';
import 'widgets/store_product_card.dart';

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

  void _openCart(List<StoreProduct> products) {
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
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('IN-GYM STORE & SHAKES', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          productsAsync.maybeWhen(
            data: (products) {
              final count = _cart.values.fold<int>(0, (sum, q) => sum + q);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_rounded, color: AppColors.textPrimary),
                    onPressed: count > 0 ? () => _openCart(products) : null,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading store: $err', style: const TextStyle(color: Colors.redAccent))),
        data: (products) => _buildCatalog(products, accent),
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
              onPressed: () => _openCart(products),
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

  Widget _buildCatalog(List<StoreProduct> products, Color accent) {
    final filtered = products.where((p) {
      final matchesCat = _selectedCategory == 'All' || p.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || p.providerBrand.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search supplements, shakes, gear...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _categories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(c, style: GoogleFonts.inter(fontSize: 11, color: _selectedCategory == c ? Colors.black : AppColors.textPrimary)),
                selected: _selectedCategory == c,
                selectedColor: accent,
                backgroundColor: AppColors.surface,
                onSelected: (val) => setState(() => _selectedCategory = c),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = filtered[i];
              final inCart = _cart[p.id] ?? 0;
              return StoreProductCard(
                product: p,
                inCart: inCart,
                onTap: () => ProductDetailScreen.open(context, product: p, onAddToCart: (q) => setState(() => _cart[p.id] = inCart + q)),
                onAddToCart: () {
                  HapticFeedback.lightImpact();
                  setState(() => _cart[p.id] = inCart + 1);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
