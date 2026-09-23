import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreProduct {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stockQuantity;
  final String description;
  final String providerBrand;
  final String servings;
  final Map<String, String> nutritionFacts;
  final List<String> flavors;

  const StoreProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stockQuantity,
    this.description = '',
    this.providerBrand = 'Titan Fitness Pro Shop',
    this.servings = 'Standard Pack',
    this.nutritionFacts = const {},
    this.flavors = const [],
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final cat = (json['category'] as String? ?? 'General').toLowerCase();
    String defaultBrand = 'Titan Pro Shop Official';
    String defaultServings = 'Standard';
    List<String> defaultFlavors = [];
    Map<String, String> defaultNutri = {};

    if (cat.contains('supplement') || json['name'].toString().toLowerCase().contains('whey')) {
      defaultBrand = 'Optimum Nutrition Pakistan';
      defaultServings = '60 Servings • 2.27 KG';
      defaultFlavors = ['Double Rich Chocolate', 'Vanilla Ice Cream', 'Cookies & Cream'];
      defaultNutri = {'Protein': '24g', 'BCAAs': '5.5g', 'Calories': '120 kcal', 'Carbs': '3g'};
    } else if (cat.contains('creatine')) {
      defaultBrand = 'MuscleTech Essential Series';
      defaultServings = '80 Servings • 400g';
      defaultFlavors = ['Unflavored Pure'];
      defaultNutri = {'Creatine': '5g', 'Purity': '99.9%', 'Calories': '0 kcal'};
    } else if (cat.contains('pre-workout') || json['name'].toString().toLowerCase().contains('c4')) {
      defaultBrand = 'Cellucor Official';
      defaultServings = '30 Servings • 195g';
      defaultFlavors = ['Icy Blue Razz', 'Fruit Punch', 'Watermelon'];
      defaultNutri = {'Caffeine': '150mg', 'Beta-Alanine': '1.6g', 'Citrulline': '1g'};
    } else if (cat.contains('shake') || cat.contains('drink') || cat.contains('juice')) {
      defaultBrand = 'In-Gym Fresh Cold Bar';
      defaultServings = 'Fresh 500ml Chilled Bottle';
      defaultFlavors = ['Banana Peanut Butter', 'Mixed Berry Blast', 'Choco Almond'];
      defaultNutri = {'Protein': '32g', 'Fresh Milk': '300ml', 'Energy': '280 kcal'};
    } else if (cat.contains('gear') || cat.contains('strap')) {
      defaultBrand = 'Titan Heavy Duty Gear';
      defaultServings = 'Pair (Left + Right)';
      defaultFlavors = ['Matte Black / Neon Volt'];
      defaultNutri = {'Material': 'Reinforced Cotton', 'Max Load': '400 KG'};
    }

    return StoreProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Product',
      category: json['category'] as String? ?? 'General',
      price: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (json['stock_quantity'] as int?) ?? 0,
      description: json['description'] as String? ?? '',
      providerBrand: json['provider_brand'] as String? ?? defaultBrand,
      servings: json['servings'] as String? ?? defaultServings,
      nutritionFacts: defaultNutri,
      flavors: defaultFlavors,
    );
  }
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('StoreRepository: Supabase client unavailable: $e');
  }
  return StoreRepository(client);
});

final storeProductsProvider = FutureProvider<List<StoreProduct>>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.fetchInGymProducts();
});

class StoreRepository {
  final SupabaseClient? _supabase;

  const StoreRepository(this._supabase);

  Future<List<StoreProduct>> fetchInGymProducts() async {
    final client = _supabase;
    if (client == null) return [];

    try {
      final res = await client
          .from('products')
          .select('id, name, category, selling_price, stock_quantity, description')
          .eq('is_active', true)
          .order('category', ascending: true);

      return (res as List).map((row) => StoreProduct.fromJson(row as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('StoreRepository: fetchInGymProducts error: $e');
      return [];
    }
  }

  Future<bool> createStoreOrder({
    required String pickupCode,
    required double totalAmount,
    required Map<String, int> cartItems,
    required List<StoreProduct> allProducts,
  }) async {
    final client = _supabase;
    if (client == null) return false;

    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final profile = await client.from('profiles').select('tenant_id').eq('id', userId).maybeSingle();
      final tenantId = profile?['tenant_id'] as String?;
      if (tenantId == null) return false;

      final orderRes = await client.from('store_orders').insert({
        'tenant_id': tenantId,
        'member_id': userId,
        'pickup_code': pickupCode,
        'order_status': 'pending',
        'total_amount': totalAmount,
        'is_paid': false,
      }).select('id').single();

      final orderId = orderRes['id'] as String;

      final itemsToInsert = <Map<String, dynamic>>[];
      for (final entry in cartItems.entries) {
        final prod = allProducts.firstWhere((p) => p.id == entry.key);
        itemsToInsert.add({
          'order_id': orderId,
          'product_id': prod.id,
          'quantity': entry.value,
          'unit_price': prod.price,
          'total_price': prod.price * entry.value,
        });
      }

      if (itemsToInsert.isNotEmpty) {
        await client.from('store_order_items').insert(itemsToInsert);
      }
      return true;
    } catch (e) {
      debugPrint('StoreRepository: createStoreOrder error: $e');
      return false;
    }
  }
}
