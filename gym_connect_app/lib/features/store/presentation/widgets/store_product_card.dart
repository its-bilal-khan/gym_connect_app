import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';

class StoreProductCard extends StatelessWidget {
  final StoreProduct product;
  final int inCart;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const StoreProductCard({
    super.key,
    required this.product,
    required this.inCart,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.inventory_2_rounded, color: accent, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.providerBrand,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
                  ),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  Text(
                    product.servings,
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${product.price.toInt()}',
                    style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryAccent),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                inCart > 0 ? Icons.check_circle_rounded : Icons.add_circle_rounded,
                color: inCart > 0 ? Colors.greenAccent : accent,
              ),
              onPressed: onAddToCart,
            ),
          ],
        ),
      ),
    );
  }
}
