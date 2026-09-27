import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';
import '../providers/store_providers.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/owner_product_grid_card.dart';
import '../widgets/owner_product_list_row.dart';
import '../widgets/store_view_mode_toggle.dart';

class GymOwnerProductManagementScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const GymOwnerProductManagementScreen({super.key, required this.tenantId});

  static Future<void> open(BuildContext context, {required String tenantId}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GymOwnerProductManagementScreen(tenantId: tenantId),
      ),
    );
  }

  @override
  ConsumerState<GymOwnerProductManagementScreen> createState() =>
      _GymOwnerProductManagementScreenState();
}

class _GymOwnerProductManagementScreenState
    extends ConsumerState<GymOwnerProductManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'ALL';

  static const List<String> _categories = [
    'ALL',
    'SUPPLEMENTS',
    'GEAR',
    'SNACKS',
    'DRINKS',
    'JUICE BAR',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, StoreProduct prod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'DELETE PRODUCT',
          style: GoogleFonts.oswald(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${prod.name}" from your gym store catalog? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(storeActionNotifierProvider.notifier)
                  .deleteProduct(prod.id);
              if (context.mounted && !success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not delete product'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<StoreProduct> _filterProducts(List<StoreProduct> products) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return products.where((prod) {
      final matchesQuery = query.isEmpty ||
          prod.name.toLowerCase().contains(query) ||
          prod.category.toLowerCase().contains(query) ||
          prod.providerBrand.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == 'ALL' ||
          prod.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final productsAsync = ref.watch(storeProductsProvider);
    final viewMode = ref.watch(storeViewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'MANAGE PRODUCTS & INVENTORY',
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            productsAsync.maybeWhen(
              data: (products) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '${products.length} PRODUCTS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => AddProductDialog.show(context, tenantId: widget.tenantId),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'ADD PRODUCT',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Subheader Filter & Dual-View Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Column(
              children: [
                // Top row: Search input + View mode toggle
                Row(
                  children: [
                    // Search bar
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search products by name, category, or brand...',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textSecondary,
                              size: 19,
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textSecondary,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Dual-View Mode Segmented Toggle Switch (Rule 5)
                    StoreViewModeToggle(
                      currentMode: viewMode,
                      onModeChanged: (mode) {
                        ref.read(storeViewModeProvider.notifier).setMode(mode);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom row: Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCategory = cat),
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.16)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? accent
                                    : AppColors.border,
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected ? accent : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Main Listing Body (Reactive Grid or List)
          Expanded(
            child: RefreshIndicator(
              color: accent,
              onRefresh: () async => ref.invalidate(storeProductsProvider),
              child: productsAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: accent)),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load products',
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$err',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                data: (products) {
                  final filtered = _filterProducts(products);

                  if (products.isEmpty) {
                    return _buildEmptyCatalog(context, accent);
                  }

                  if (filtered.isEmpty) {
                    return _buildEmptySearchResults(accent);
                  }

                  if (viewMode == StoreViewMode.grid) {
                    return _buildGridView(filtered);
                  } else {
                    return _buildListView(filtered);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<StoreProduct> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 4;
        if (width < 640) {
          crossAxisCount = 1;
        } else if (width < 960) {
          crossAxisCount = 2;
        } else if (width < 1280) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 290,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final prod = products[index];
            return OwnerProductGridCard(
              product: prod,
              onDelete: () => _confirmDelete(context, prod),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<StoreProduct> products) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final prod = products[index];
        return OwnerProductListRow(
          product: prod,
          onDelete: () => _confirmDelete(context, prod),
        );
      },
    );
  }

  Widget _buildEmptyCatalog(BuildContext context, Color accent) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(Icons.inventory_2_outlined, size: 54, color: accent),
              ),
              const SizedBox(height: 18),
              Text(
                'NO PRODUCTS IN CATALOG',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "+ ADD PRODUCT" to upload your gym supplements, gear, & drinks.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => AddProductDialog.show(context, tenantId: widget.tenantId),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'ADD FIRST PRODUCT',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySearchResults(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'NO MATCHING PRODUCTS',
            style: GoogleFonts.oswald(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search query or selecting a different category filter.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _selectedCategory = 'ALL');
            },
            child: Text(
              'CLEAR FILTERS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
