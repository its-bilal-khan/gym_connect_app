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
  final Function(String id, int current)? onRemoveFromCart;

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
    this.onRemoveFromCart,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final filtered = products.where((p) {
      final matchesCat = selectedCategory == 'All' || p.category.toLowerCase() == selectedCategory.toLowerCase();
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.providerBrand.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: onSearchChanged,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search supplements, shakes, gear, brands...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
            ),
          ),
        ),

        // Horizontal Category Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: categories.map((c) {
              final isSelected = selectedCategory == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: ChoiceChip(
                  label: Text(
                    c,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.black : AppColors.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: accent,
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? accent : AppColors.border,
                      width: 1,
                    ),
                  ),
                  onSelected: (_) => onCategoryChanged(c),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),

        // Catalog Content (Grid or List)
        Expanded(
          child: isGridView ? _buildGrid(context, filtered) : _buildList(context, filtered),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<StoreProduct> filtered) {
    if (filtered.isEmpty) {
      return _buildEmptyState(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        final double childAspectRatio;

        if (width >= 1500) {
          crossAxisCount = 5;
          childAspectRatio = 0.74;
        } else if (width >= 1100) {
          crossAxisCount = 4;
          childAspectRatio = 0.73;
        } else if (width >= 800) {
          crossAxisCount = 3;
          childAspectRatio = 0.72;
        } else if (width >= 480) {
          crossAxisCount = 2;
          childAspectRatio = 0.69;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 0.64;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final p = filtered[i];
            final inCart = cart[p.id] ?? 0;
            return StoreProductGridCard(
              product: p,
              inCart: inCart,
              onTap: () => ProductDetailScreen.open(
                context,
                product: p,
                onAddToCart: (q) => onAddToCart(p.id, inCart + q - 1),
              ),
              onAddToCart: () {
                HapticFeedback.lightImpact();
                onAddToCart(p.id, inCart);
              },
              onRemoveFromCart: onRemoveFromCart != null
                  ? () {
                      HapticFeedback.lightImpact();
                      onRemoveFromCart!(p.id, inCart);
                    }
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<StoreProduct> filtered) {
    if (filtered.isEmpty) {
      return _buildEmptyState(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 960 : double.infinity),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = filtered[i];
                final inCart = cart[p.id] ?? 0;
                return StoreProductCard(
                  product: p,
                  inCart: inCart,
                  onTap: () => ProductDetailScreen.open(
                    context,
                    product: p,
                    onAddToCart: (q) => onAddToCart(p.id, inCart + q - 1),
                  ),
                  onAddToCart: () {
                    HapticFeedback.lightImpact();
                    onAddToCart(p.id, inCart);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: AppColors.textSecondary, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'NO PRODUCTS FOUND',
            style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search terms or selecting another category.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
