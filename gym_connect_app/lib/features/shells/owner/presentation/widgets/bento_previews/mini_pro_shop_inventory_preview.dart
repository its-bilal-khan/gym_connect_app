import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';
import 'package:gym_connect_app/features/store/presentation/providers/store_providers.dart';

/// 1:1 exact scaled live preview of GymOwnerProductManagementScreen matching user screenshot.
class MiniProShopInventoryPreview extends ConsumerWidget {
  final String tenantId;

  const MiniProShopInventoryPreview({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final productsAsync = ref.watch(storeProductsProvider);
    final viewMode = ref.watch(storeViewModeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Container(
          width: 1024,
          height: 492,
          color: const Color(0xFF09090B),
          child: productsAsync.maybeWhen(
            data: (products) => _buildLiveScreen(products, viewMode, accent),
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
    List<StoreProduct> products,
    StoreViewMode viewMode,
    Color accent,
  ) {
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
                'MANAGE PRODUCTS & INVENTORY',
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
                  '${products.length} PRODUCTS',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      'ADD PRODUCT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
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
                            'Search products by name, category, or brand...',
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

              // Row 2: Category Filter Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCatChip('ALL', true, accent),
                  const SizedBox(width: 6),
                  _buildCatChip('SUPPLEMENTS', false, accent),
                  const SizedBox(width: 6),
                  _buildCatChip('GEAR', false, accent),
                  const SizedBox(width: 6),
                  _buildCatChip('SNACKS', false, accent),
                  const SizedBox(width: 6),
                  _buildCatChip('DRINKS', false, accent),
                  const SizedBox(width: 6),
                  _buildCatChip('JUICE BAR', false, accent),
                ],
              ),
            ],
          ),
        ),

        // 3. Product Catalog Grid / List Body
        Expanded(
          child: Container(
            color: const Color(0xFF09090B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: viewMode == StoreViewMode.list
                ? _buildListView(products, accent)
                : _buildGridView(products, accent),
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
          color: isSelected ? accent.withValues(alpha: 0.5) : Colors.transparent,
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

  Widget _buildCatChip(String label, bool isSelected, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? accent.withValues(alpha: 0.16) : AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? accent : AppColors.border,
          width: isSelected ? 1.3 : 1.0,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? accent : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildGridView(List<StoreProduct> products, Color accent) {
    final displayList = products.take(8).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int col = 0; col < 4; col++) ...[
          Expanded(
            child: Column(
              children: [
                if (col < displayList.length)
                  Expanded(
                    child: _buildProductMiniCard(displayList[col], accent),
                  ),
                const SizedBox(height: 10),
                if (col + 4 < displayList.length)
                  Expanded(
                    child: _buildProductMiniCard(displayList[col + 4], accent),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
          if (col < 3) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildProductMiniCard(StoreProduct prod, Color accent) {
    final isOutOfStock = prod.stockQuantity <= 0;
    final isLowStock = prod.stockQuantity > 0 && prod.stockQuantity <= 5;
    final stockColor = isOutOfStock
        ? Colors.redAccent
        : (isLowStock ? Colors.amberAccent : Colors.greenAccent);
    final stockLabel = isOutOfStock
        ? 'OUT OF STOCK'
        : '${prod.stockQuantity} IN STOCK';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: Container(
                  height: 90,
                  width: double.infinity,
                  color: AppColors.background,
                  child: Image.network(
                    prod.effectiveImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: accent.withValues(alpha: 0.3),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    prod.category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: stockColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        stockLabel,
                        style: GoogleFonts.inter(
                          fontSize: 6.5,
                          fontWeight: FontWeight.bold,
                          color: stockColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${prod.providerBrand} • ${prod.servings}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${prod.price.toStringAsFixed(0)}',
                        style: GoogleFonts.oswald(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<StoreProduct> products, Color accent) {
    final displayList = products.take(4).toList();

    return Column(
      children: [
        for (final prod in displayList) ...[
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: AppColors.background,
                      child: Image.network(
                        prod.effectiveImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.fitness_center_rounded,
                            color: accent.withValues(alpha: 0.3),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                prod.category.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              prod.providerBrand,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prod.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${prod.stockQuantity} in stock',
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'PKR ${prod.price.toStringAsFixed(0)}',
                    style: GoogleFonts.oswald(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 13,
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
