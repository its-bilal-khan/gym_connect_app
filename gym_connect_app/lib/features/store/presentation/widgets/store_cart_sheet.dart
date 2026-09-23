import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';
import '../screens/store_checkout_screen.dart';

class StoreCartSheet extends ConsumerStatefulWidget {
  final Map<String, int> cart;
  final List<StoreProduct> allProducts;
  final double totalAmount;
  final VoidCallback onClearCart;

  const StoreCartSheet({
    super.key,
    required this.cart,
    required this.allProducts,
    required this.totalAmount,
    required this.onClearCart,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, int> cart,
    required List<StoreProduct> allProducts,
    required double totalAmount,
    required VoidCallback onClearCart,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoreCartSheet(cart: cart, allProducts: allProducts, totalAmount: totalAmount, onClearCart: onClearCart),
    );
  }

  @override
  ConsumerState<StoreCartSheet> createState() => _StoreCartSheetState();
}

class _StoreCartSheetState extends ConsumerState<StoreCartSheet> {
  void _openCheckout() {
    Navigator.pop(context);
    StoreCheckoutScreen.open(
      context,
      cart: widget.cart,
      allProducts: widget.allProducts,
      totalAmount: widget.totalAmount,
      onOrderPlaced: widget.onClearCart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MY SHOPPING CART', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: widget.cart.entries.map((entry) {
                final p = widget.allProducts.firstWhere((item) => item.id == entry.key);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(p.effectiveImageUrl, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.inventory_2_rounded, color: Colors.white24)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('${entry.value}x @ PKR ${p.price.toInt()}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text('PKR ${(p.price * entry.value).toInt()}', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ESTIMATED TOTAL:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Text('PKR ${widget.totalAmount.toInt()}', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _openCheckout,
            child: Text('PROCEED TO CHECKOUT & PAYMENT ➔', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
