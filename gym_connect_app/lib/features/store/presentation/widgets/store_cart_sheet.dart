import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';

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
  String? _pickupCode;
  bool _isPlacing = false;

  Future<void> _placeOrder() async {
    HapticFeedback.heavyImpact();
    setState(() => _isPlacing = true);
    final code = 'PK-${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}';
    await ref.read(storeRepositoryProvider).createStoreOrder(
      pickupCode: code,
      totalAmount: widget.totalAmount,
      cartItems: widget.cart,
      allProducts: widget.allProducts,
    );
    if (!mounted) return;
    setState(() {
      _isPlacing = false;
      _pickupCode = code;
    });
    widget.onClearCart();
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
              Text('CART & COUNTER PICKUP', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          if (_pickupCode != null)
            _buildSuccessCard(accent)
          else ...[
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text('${entry.value}x @ PKR ${p.price.toInt()}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text('PKR ${(p.price * entry.value).toInt()}', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
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
                Text('TOTAL DUE AT COUNTER:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                Text('PKR ${widget.totalAmount.toInt()}', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _isPlacing ? null : _placeOrder,
              child: _isPlacing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text('GENERATE FRONT DESK PICKUP CODE', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessCard(Color accent) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.greenAccent)),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 48),
              const SizedBox(height: 10),
              Text('ORDER SUBMITTED!', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Show this pickup code at the front desk / fuel bar:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: accent)),
                child: Text(_pickupCode!, style: GoogleFonts.oswald(fontSize: 28, fontWeight: FontWeight.bold, color: accent, letterSpacing: 2)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () => Navigator.pop(context),
          child: const Text('DONE'),
        ),
      ],
    );
  }
}
