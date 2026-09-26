import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/staff/data/staff_pos_repository.dart';
import 'package:gym_connect_app/features/staff/presentation/widgets/thermal_receipt_dialog.dart';
import 'package:gym_connect_app/features/store/data/store_repository.dart';
import 'desktop_pos_cart_sidebar.dart';
import 'desktop_pos_product_grid.dart';

class DesktopPosRegisterScreen extends ConsumerStatefulWidget {
  const DesktopPosRegisterScreen({super.key});

  @override
  ConsumerState<DesktopPosRegisterScreen> createState() => _DesktopPosRegisterScreenState();
}

class _DesktopPosRegisterScreenState extends ConsumerState<DesktopPosRegisterScreen> {
  final Map<String, int> _cart = {};
  String _selectedCategory = 'All';
  String _paymentMethod = 'Cash';
  String _customerName = 'Walk-in Customer';
  String _searchQuery = '';
  bool _isProcessing = false;

  final List<String> _categories = ['All', 'Supplements', 'Drinks', 'Juice Bar', 'Snacks', 'Gear'];

  Future<void> _processCheckout(List<StoreProduct> products) async {
    final saleItems = <PosSaleItem>[];
    _cart.forEach((id, qty) {
      final p = products.where((item) => item.id == id).firstOrNull;
      if (p != null) saleItems.add(PosSaleItem(product: p, quantity: qty, unitPrice: p.price));
    });
    if (saleItems.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final receipt = await ref.read(staffPosRepositoryProvider).processPosCheckout(
        items: saleItems,
        paymentMethod: _paymentMethod,
        discount: 0.0,
        customerName: _customerName,
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _cart.clear();
      });
      ThermalReceiptDialog.show(context, receipt);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(storeProductsProvider);

    return productsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error loading products: $e', style: const TextStyle(color: AppColors.error))),
      data: (products) {
        final filtered = products.where((p) {
          final matchesCat = _selectedCategory == 'All' || p.category.toLowerCase() == _selectedCategory.toLowerCase();
          final matchesSearch = _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesCat && matchesSearch;
        }).toList();

        return Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCatalogHeader(),
                    const SizedBox(height: 14),
                    _buildCategoryFilters(),
                    Expanded(
                      child: DesktopPosProductGrid(
                        products: filtered,
                        cart: _cart,
                        onAdd: (p) => setState(() => _cart[p.id] = (_cart[p.id] ?? 0) + 1),
                        onRemove: (p) => setState(() {
                          final count = _cart[p.id] ?? 0;
                          if (count <= 1) {
                            _cart.remove(p.id);
                          } else {
                            _cart[p.id] = count - 1;
                          }
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DesktopPosCartSidebar(
              cart: _cart,
              products: products,
              paymentMethod: _paymentMethod,
              customerName: _customerName,
              isProcessing: _isProcessing,
              onSelectPaymentMethod: (m) => setState(() => _paymentMethod = m),
              onCustomerNameChanged: (val) => _customerName = val.isEmpty ? 'Walk-in Customer' : val,
              onIncrement: (p) => setState(() => _cart[p.id] = (_cart[p.id] ?? 0) + 1),
              onDecrement: (p) => setState(() {
                final count = _cart[p.id] ?? 0;
                if (count <= 1) {
                  _cart.remove(p.id);
                } else {
                  _cart[p.id] = count - 1;
                }
              }),
              onClearCart: () => setState(() => _cart.clear()),
              onCheckout: () => _processCheckout(products),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCatalogHeader() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search products or scan barcode...',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((c) {
          final isSelected = _selectedCategory == c;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(c, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white)),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              onSelected: (_) => setState(() => _selectedCategory = c),
            ),
          );
        }).toList(),
      ),
    );
  }
}
