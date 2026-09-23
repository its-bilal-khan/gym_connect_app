import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../data/store_repository.dart';

class ProductDetailScreen extends StatefulWidget {
  final StoreProduct product;
  final ValueChanged<int> onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  static Future<void> open(BuildContext context, {required StoreProduct product, required ValueChanged<int> onAddToCart}) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product, onAddToCart: onAddToCart)),
    );
  }

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedFlavorIndex = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('PRODUCT DETAILS', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCard(p, accent),
            const SizedBox(height: 16),
            Text(p.providerBrand.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(p.name, style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PKR ${p.price.toInt()}', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.stockQuantity > 0 ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.stockQuantity > 0 ? Colors.greenAccent : Colors.redAccent),
                  ),
                  child: Text(
                    p.stockQuantity > 0 ? 'IN STOCK (${p.stockQuantity})' : 'OUT OF STOCK',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: p.stockQuantity > 0 ? Colors.greenAccent : Colors.redAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (p.nutritionFacts.isNotEmpty) _buildNutritionGrid(p),
            if (p.flavors.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('SELECT FLAVOR', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(p.flavors.length, (i) => ChoiceChip(
                  label: Text(p.flavors[i], style: GoogleFonts.inter(fontSize: 11, color: _selectedFlavorIndex == i ? Colors.black : AppColors.textPrimary)),
                  selected: _selectedFlavorIndex == i,
                  selectedColor: accent,
                  backgroundColor: AppColors.surface,
                  onSelected: (val) => setState(() => _selectedFlavorIndex = i),
                )),
              ),
            ],
            const SizedBox(height: 16),
            Text('DESCRIPTION & PROTOCOL', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(
              p.description.isNotEmpty ? p.description : 'Official authentic product supplied directly by ${p.providerBrand} for verified club members.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(p, accent),
    );
  }

  Widget _buildImageCard(StoreProduct p, Color accent) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, size: 70, color: accent.withValues(alpha: 0.8)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: Text(p.servings, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionGrid(StoreProduct p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: p.nutritionFacts.entries.map((e) => Column(
          children: [
            Text(e.value, style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
            Text(e.key, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildBottomBar(StoreProduct p, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.remove_rounded, size: 18, color: AppColors.textPrimary), onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1)),
                Text('$_quantity', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                IconButton(icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.textPrimary), onPressed: () => setState(() => _quantity++)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: p.stockQuantity > 0 ? () {
                HapticFeedback.heavyImpact();
                widget.onAddToCart(_quantity);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Added $_quantity x ${p.name} to cart!'),
                  backgroundColor: AppColors.surface,
                ));
              } : null,
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: Text('ADD TO CART (PKR ${(p.price * _quantity).toInt()})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
