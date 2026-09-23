import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';
import '../providers/store_providers.dart';
import '../widgets/add_product_dialog.dart';

class GymOwnerProductManagementScreen extends ConsumerWidget {
  final String tenantId;

  const GymOwnerProductManagementScreen({super.key, required this.tenantId});

  static Future<void> open(BuildContext context, {required String tenantId}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GymOwnerProductManagementScreen(tenantId: tenantId)),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, StoreProduct prod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('DELETE PRODUCT', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Are you sure you want to remove "${prod.name}" from your gym store?', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(storeActionNotifierProvider.notifier).deleteProduct(prod.id);
              if (context.mounted && !success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete product'), backgroundColor: Colors.redAccent));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text('DELETE', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(storeProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('MANAGE PRODUCTS & INVENTORY', style: GoogleFonts.oswald(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Add Product',
            onPressed: () => AddProductDialog.show(context, tenantId: tenantId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: Text('ADD PRODUCT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
        onPressed: () => AddProductDialog.show(context, tenantId: tenantId),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(storeProductsProvider),
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text('Error: $err', style: GoogleFonts.inter(color: Colors.white))),
          data: (products) {
            if (products.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_outlined, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text('NO PRODUCTS IN CATALOG', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text('Tap "+ ADD PRODUCT" to upload your gym supplements & gear.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _buildProductRow(context, ref, products[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, WidgetRef ref, StoreProduct prod) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              prod.effectiveImageUrl,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(width: 54, height: 54, color: AppColors.background, child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prod.category.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                Text(prod.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('PKR ${prod.price.toInt()} • Stock: ${prod.stockQuantity}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            tooltip: 'Delete Product',
            onPressed: () => _confirmDelete(context, ref, prod),
          ),
        ],
      ),
    );
  }
}
