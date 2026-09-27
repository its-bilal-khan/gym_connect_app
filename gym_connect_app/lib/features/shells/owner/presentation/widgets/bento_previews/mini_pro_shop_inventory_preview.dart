import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';

/// Mini live preview matching the exact signature layout of GymOwnerProductManagementScreen.
class MiniProShopInventoryPreview extends ConsumerWidget {
  final String tenantId;

  const MiniProShopInventoryPreview({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final productsAsync = ref.watch(storeProductsProvider);

    return Container(
      color: const Color(0xFF0F0F13),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: productsAsync.maybeWhen(
        data: (products) {
          final prod = products.isNotEmpty ? products.first : null;
          final totalCount = products.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Inventory Count + Iconic "+ Add Product" Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CATALOG: $totalCount PRODUCTS',
                      style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 10, color: Colors.black),
                        const SizedBox(width: 2),
                        Text(
                          'ADD PRODUCT',
                          style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Product Category Strip
              Row(
                children: [
                  _buildCatChip('ALL', true, accent),
                  const SizedBox(width: 4),
                  _buildCatChip('SUPPLEMENTS', false, accent),
                  const SizedBox(width: 4),
                  _buildCatChip('GEAR', false, accent),
                ],
              ),
              const SizedBox(height: 6),

              // Actual Product Shelf Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.storefront_rounded, size: 14, color: accent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              prod != null ? prod.name : 'Optimum Nutrition Gold Whey',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              prod != null
                                  ? '${prod.category} • ${prod.providerBrand}'
                                  : 'Supplements • Optimum Nutrition',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 8, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            prod != null ? 'PKR ${prod.price.toStringAsFixed(0)}' : 'PKR 18,500',
                            style: GoogleFonts.oswald(fontSize: 10.0, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              prod != null ? '${prod.stockQuantity} IN STOCK' : '24 IN STOCK',
                              style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        orElse: () => Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2)),
      ),
    );
  }

  Widget _buildCatChip(String label, bool isSelected, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isSelected ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: isSelected ? accent : AppColors.textSecondary),
      ),
    );
  }
}
