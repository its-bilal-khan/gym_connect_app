import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../store/data/store_repository.dart';
import '../../../../store/presentation/in_gym_store_screen.dart';
import 'store_pickup_success_card.dart';

class InGymStoreSheet extends ConsumerStatefulWidget {
  const InGymStoreSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const InGymStoreSheet(),
    );
  }

  @override
  ConsumerState<InGymStoreSheet> createState() => _InGymStoreSheetState();
}

class _InGymStoreSheetState extends ConsumerState<InGymStoreSheet> {
  final Map<String, int> _cart = {};
  String? _pickupCode;
  bool _isSubmitting = false;

  double _calculateTotal(List<StoreProduct> products) {
    double total = 0.0;
    _cart.forEach((id, qty) {
      final p = products.where((item) => item.id == id).firstOrNull;
      if (p != null) total += p.price * qty;
    });
    return total;
  }

  Future<void> _placeOrder(List<StoreProduct> products, double total) async {
    setState(() => _isSubmitting = true);
    final code = 'PK-${(1000 + (DateTime.now().millisecondsSinceEpoch % 8999))}';
    await ref.read(storeRepositoryProvider).createStoreOrder(
      pickupCode: code,
      totalAmount: total,
      cartItems: _cart,
      allProducts: products,
    );
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _pickupCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    final productsAsync = ref.watch(storeProductsProvider);

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
              Text('IN-GYM STORE & SHAKES', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
            ],
          ),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              InGymStoreScreen.open(context);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: accent.withValues(alpha: 0.3))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Open Full E-Commerce Store & PDP', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: accent),
                ],
              ),
            ),
          ),
          if (_pickupCode != null)
            Expanded(child: StorePickupSuccessCard(pickupCode: _pickupCode!, onClose: () => Navigator.pop(context)))
          else ...[
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading inventory: $e', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12))),
                data: (products) => ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final qty = _cart[p.id] ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: AppColors.surface, radius: 18, child: Icon(Icons.bolt_rounded, color: accent, size: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text('PKR ${p.price.toInt()} • ${p.category}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          if (qty > 0) ...[
                            IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.textSecondary, size: 22), onPressed: () => setState(() => qty == 1 ? _cart.remove(p.id) : _cart[p.id] = qty - 1)),
                            Text('$qty', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                          IconButton(icon: const Icon(Icons.add_circle_rounded, color: Colors.cyanAccent, size: 22), onPressed: () => setState(() => _cart[p.id] = qty + 1)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            productsAsync.maybeWhen(
              data: (products) {
                final total = _calculateTotal(products);
                return ElevatedButton(
                  onPressed: total > 0 && !_isSubmitting ? () => _placeOrder(products, total) : null,
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(total > 0 ? 'ORDER (PKR ${total.toInt()})' : 'SELECT ITEMS', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}
