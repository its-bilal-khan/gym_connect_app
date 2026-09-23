import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';
import 'package:gym_connect_app/features/staff/data/staff_pos_repository.dart';
import 'staff_payment_method_modal.dart';
import 'staff_pos_product_tile.dart';
import 'thermal_receipt_dialog.dart';

class StaffPosRegisterSheet extends ConsumerStatefulWidget {
  const StaffPosRegisterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StaffPosRegisterSheet(),
    );
  }

  @override
  ConsumerState<StaffPosRegisterSheet> createState() => _StaffPosRegisterSheetState();
}

class _StaffPosRegisterSheetState extends ConsumerState<StaffPosRegisterSheet> {
  final Map<String, int> _cart = {};
  String _selectedCategory = 'All';
  String _paymentMethod = 'Cash';
  bool _isProcessing = false;

  final List<String> _categories = ['All', 'Supplements', 'Drinks', 'Juice Bar', 'Snacks', 'Gear'];
  final List<String> _methods = ['Cash', 'Credit_Card', 'JazzCash', 'EasyPaisa', 'Khata_Credit'];

  double _calcTotal(List<StoreProduct> products) {
    double total = 0.0;
    _cart.forEach((id, qty) {
      final p = products.where((item) => item.id == id).firstOrNull;
      if (p != null) total += p.price * qty;
    });
    return total;
  }

  Future<void> _processCheckout(List<StoreProduct> products, String customerName) async {
    final saleItems = <PosSaleItem>[];
    _cart.forEach((id, qty) {
      final p = products.where((item) => item.id == id).firstOrNull;
      if (p != null) saleItems.add(PosSaleItem(product: p, quantity: qty, unitPrice: p.price));
    });
    if (saleItems.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _isProcessing = true);

    final receipt = await ref.read(staffPosRepositoryProvider).processPosCheckout(
      items: saleItems,
      paymentMethod: _paymentMethod,
      discount: 0.0,
      customerName: customerName,
      memberId: _paymentMethod == 'Khata_Credit' ? '00000000-0000-0000-0000-000000000002' : null,
    );

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _cart.clear();
    });
    Navigator.pop(context);
    ThermalReceiptDialog.show(context, receipt);
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
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RETAIL POS & KHATA REGISTER', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(c, style: GoogleFonts.inter(fontSize: 11, color: _selectedCategory == c ? Colors.black : AppColors.textPrimary)),
                  selected: _selectedCategory == c,
                  selectedColor: accent,
                  backgroundColor: AppColors.background,
                  onSelected: (val) => setState(() => _selectedCategory = c),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading products: $e', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12))),
              data: (products) {
                final filtered = _selectedCategory == 'All' ? products : products.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    final qty = _cart[p.id] ?? 0;
                    return StaffPosProductTile(
                      product: p,
                      quantity: qty,
                      onAdd: () => setState(() => _cart[p.id] = qty + 1),
                      onRemove: () => setState(() => qty == 1 ? _cart.remove(p.id) : _cart[p.id] = qty - 1),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _methods.map((m) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(m.replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: _paymentMethod == m ? Colors.black : (m == 'Khata_Credit' ? Colors.orangeAccent : AppColors.textPrimary))),
                  selected: _paymentMethod == m,
                  selectedColor: m == 'Khata_Credit' ? Colors.orangeAccent : accent,
                  backgroundColor: AppColors.background,
                  onSelected: (val) => setState(() => _paymentMethod = m),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          productsAsync.maybeWhen(
            data: (products) {
              final total = _calcTotal(products);
              return ElevatedButton(
                onPressed: total > 0 && !_isProcessing ? () {
                  StaffPaymentMethodModal.show(
                    context,
                    totalAmount: total,
                    paymentMethod: _paymentMethod,
                    onConfirm: (name) => _processCheckout(products, name),
                  );
                } : null,
                style: ElevatedButton.styleFrom(backgroundColor: _paymentMethod == 'Khata_Credit' ? Colors.orangeAccent : accent, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(total > 0 ? 'COLLECT PKR ${total.toInt()} (${_paymentMethod.replaceAll('_', ' ')})' : 'ADD ITEMS TO CART', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
