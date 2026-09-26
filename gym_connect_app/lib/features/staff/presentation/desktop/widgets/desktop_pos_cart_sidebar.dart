import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';

class DesktopPosCartSidebar extends StatelessWidget {
  final Map<String, int> cart;
  final List<StoreProduct> products;
  final String paymentMethod;
  final String customerName;
  final bool isProcessing;
  final ValueChanged<String> onSelectPaymentMethod;
  final ValueChanged<String> onCustomerNameChanged;
  final ValueChanged<StoreProduct> onIncrement;
  final ValueChanged<StoreProduct> onDecrement;
  final VoidCallback onClearCart;
  final VoidCallback onCheckout;

  const DesktopPosCartSidebar({
    super.key,
    required this.cart,
    required this.products,
    required this.paymentMethod,
    required this.customerName,
    required this.isProcessing,
    required this.onSelectPaymentMethod,
    required this.onCustomerNameChanged,
    required this.onIncrement,
    required this.onDecrement,
    required this.onClearCart,
    required this.onCheckout,
  });

  double get _total {
    double sum = 0.0;
    cart.forEach((id, qty) {
      final p = products.where((item) => item.id == id).firstOrNull;
      if (p != null) sum += p.price * qty;
    });
    return sum;
  }

  static const _methods = ['Cash', 'Credit_Card', 'JazzCash', 'EasyPaisa', 'Khata_Credit'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'LIVE REGISTER CART',
                  style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white),
                ),
              ),
              if (cart.isNotEmpty)
                TextButton(
                  onPressed: onClearCart,
                  child: Text('Clear', style: GoogleFonts.inter(color: AppColors.error, fontSize: 12)),
                ),
            ],
          ),
          const Divider(color: AppColors.border, height: 20),
          Expanded(child: _buildCartItemsList()),
          const Divider(color: AppColors.border, height: 20),
          _buildPaymentMethods(),
          const SizedBox(height: 12),
          _buildCustomerField(),
          const SizedBox(height: 16),
          _buildTotalAndCheckout(),
        ],
      ),
    );
  }

  Widget _buildCartItemsList() {
    if (cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text('Register cart is empty', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Click any product to add to cart', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      );
    }

    final entries = cart.entries.toList();
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final p = products.where((item) => item.id == entry.key).firstOrNull;
        if (p == null) return const SizedBox();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Image.network(
                    p.effectiveImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.fitness_center_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('PKR ${p.price.toStringAsFixed(0)} each', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.white70), onPressed: () => onDecrement(p)),
                  Text('${entry.value}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(icon: Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary), onPressed: () => onIncrement(p)),
                ],
              ),
              const SizedBox(width: 4),
              Text('PKR ${(p.price * entry.value).toStringAsFixed(0)}', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethods() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _methods.map((m) {
          final isSelected = paymentMethod == m;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(m.replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white)),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.background,
              onSelected: (_) => onSelectPaymentMethod(m),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomerField() {
    return TextField(
      onChanged: onCustomerNameChanged,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        hintText: 'Customer / Member Name (Walk-in)',
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }

  Widget _buildTotalAndCheckout() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TOTAL AMOUNT:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            Text('PKR ${_total.toStringAsFixed(0)}', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (cart.isEmpty || isProcessing) ? null : onCheckout,
            icon: isProcessing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.print_rounded, size: 20),
            label: Text(isProcessing ? 'PROCESSING...' : 'CHARGE & PRINT RECEIPT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
