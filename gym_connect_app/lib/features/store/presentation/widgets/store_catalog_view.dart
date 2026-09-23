import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';
import '../product_detail_screen.dart';
import 'store_product_card.dart';
import 'store_product_grid_card.dart';

class StoreCatalogView extends StatelessWidget {
  final List<StoreProduct> products;
  final bool isGridView;
  final Map<String, int> cart;
  final String searchQuery;
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final Function(String id, int current) onAddToCart;

  const StoreCatalogView({
    super.key,
    required this.products,
    required this.isGridView,
    required this.cart,
    required this.searchQuery,
    required this.selectedCategory,
    required this.categories,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final filtered = products.where((p) {
      final matchesCat = selectedCategory == 'All' || p.category.toLowerCase() == selectedCategory.toLowerCase();
      final matchesSearch = searchQuery.isEmpty || p.name.toLowerCase().contains(searchQuery.toLowerCase()) || p.providerBrand.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: onSearchChanged,
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
            children: categories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(c, style: GoogleFonts.inter(fontSize: 11, color: selectedCategory == c ? Colors.black : AppColors.textPrimary)),
                selected: selectedCategory == c,
                selectedColor: accent,
                backgroundColor: AppColors.surface,
                onSelected: (_) => onCategoryChanged(c),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: isGridView ? _buildGrid(context, filtered) : _buildList(context, filtered),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<StoreProduct> filtered) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final p = filtered[i];
        final inCart = cart[p.id] ?? 0;
        return StoreProductGridCard(
          product: p,
          inCart: inCart,
          onTap: () => ProductDetailScreen.open(context, product: p, onAddToCart: (q) => onAddToCart(p.id, inCart + q - 1)),
          onAddToCart: () {
            HapticFeedback.lightImpact();
            onAddToCart(p.id, inCart);
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<StoreProduct> filtered) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = filtered[i];
        final inCart = cart[p.id] ?? 0;
        return StoreProductCard(
          product: p,
          inCart: inCart,
          onTap: () => ProductDetailScreen.open(context, product: p, onAddToCart: (q) => onAddToCart(p.id, inCart + q - 1)),
          onAddToCart: () {
            HapticFeedback.lightImpact();
            onAddToCart(p.id, inCart);
          },
        );
      },
    );
  }
}
