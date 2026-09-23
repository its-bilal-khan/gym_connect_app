import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../store/data/store_repository.dart';

class StaffPosProductTile extends StatelessWidget {
  final StoreProduct product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const StaffPosProductTile({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  'PKR ${product.price.toInt()} • Stock: ${product.stockQuantity}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (quantity > 0) ...[
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.textSecondary, size: 20),
              onPressed: onRemove,
            ),
            Text(
              '$quantity',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: Colors.cyanAccent, size: 20),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
