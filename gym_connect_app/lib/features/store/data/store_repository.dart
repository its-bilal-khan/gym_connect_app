import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreProduct {
  final String id;
  final String tenantId;
  final String name;
  final String category;
  final double price;
  final int stockQuantity;
  final String imageUrl;
  final String description;
  final String providerBrand;
  final String servings;
  final Map<String, String> nutritionFacts;
  final List<String> flavors;

  const StoreProduct({
    required this.id,
    this.tenantId = '',
    required this.name,
    required this.category,
    required this.price,
    required this.stockQuantity,
    this.imageUrl = '',
    this.description = '',
    this.providerBrand = 'Titan Fitness Pro Shop',
    this.servings = 'Standard Pack',
    this.nutritionFacts = const {},
    this.flavors = const [],
  });

  String get effectiveImageUrl {
    if (imageUrl.isNotEmpty) return imageUrl;
    final cat = category.toLowerCase();
    if (cat.contains('supplement') || name.toLowerCase().contains('whey')) {
      return 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?auto=format&fit=crop&w=800&q=80';
    } else if (cat.contains('creatine')) {
      return 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?auto=format&fit=crop&w=800&q=80';
    } else if (cat.contains('pre-workout') || name.toLowerCase().contains('c4')) {
      return 'https://images.unsplash.com/photo-1546483875-ad9014c88eba?auto=format&fit=crop&w=800&q=80';
    } else if (cat.contains('drink') || cat.contains('shake') || cat.contains('juice')) {
      return 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=800&q=80';
    } else if (cat.contains('snack') || cat.contains('bar')) {
      return 'https://images.unsplash.com/photo-1622484216800-4b2105e4cb31?auto=format&fit=crop&w=800&q=80';
    }
    return 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=800&q=80';
  }

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
      tenantId: json['tenant_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Product',
      category: json['category'] as String? ?? 'General',
      price: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (json['stock_quantity'] as int?) ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      providerBrand: json['provider_brand'] as String? ?? defaultBrand,
      servings: json['servings'] as String? ?? defaultServings,
      nutritionFacts: defaultNutri,
      flavors: defaultFlavors,
    );
  }
}

class StoreOrderItem {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const StoreOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory StoreOrderItem.fromJson(Map<String, dynamic> json) {
    String name = 'Gym Product';
    final prod = json['products'];
    if (prod is Map<String, dynamic> && prod['name'] != null) {
      name = prod['name'].toString();
    }

    return StoreOrderItem(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: name,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StoreOrder {
  final String id;
  final String tenantId;
  final String userId;
  final String customerName;
  final String? customerPhone;
  final String pickupCode;
  final String fulfillmentType; // 'pickup' or 'delivery'
  final String? deliveryAddress;
  final String? deliveryPhone;
  final String orderStatus; // 'pending', 'confirmed', 'ready_for_pickup', 'completed', 'cancelled'
  final String? estimatedReadyDate;
  final String? estimatedReadyTime;
  final String paymentMethod;
  final String? paymentReceiptUrl;
  final double totalAmount;
  final bool isPaid;
  final DateTime createdAt;
  final List<StoreOrderItem> items;

  const StoreOrder({
    required this.id,
    required this.tenantId,
    required this.userId,
    this.customerName = 'Customer',
    this.customerPhone,
    required this.pickupCode,
    this.fulfillmentType = 'pickup',
    this.deliveryAddress,
    this.deliveryPhone,
    required this.orderStatus,
    this.estimatedReadyDate,
    this.estimatedReadyTime,
    this.paymentMethod = 'manual_transfer',
    this.paymentReceiptUrl,
    required this.totalAmount,
    this.isPaid = false,
    required this.createdAt,
    this.items = const [],
  });

  bool get isDelivery => fulfillmentType.toLowerCase() == 'delivery';
  bool get isPickup => !isDelivery;

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    String name = json['customer_name'] as String? ?? 'Customer';
    final profile = json['profiles'];
    if (profile is Map<String, dynamic> && profile['full_name'] != null) {
      name = profile['full_name'].toString();
    }

    final itemsRaw = json['store_order_items'] as List<dynamic>? ?? [];
    final items = itemsRaw.map((e) => StoreOrderItem.fromJson(e as Map<String, dynamic>)).toList();

    return StoreOrder(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['member_id'] as String? ?? '',
      customerName: name,
      customerPhone: json['customer_phone'] as String? ?? json['delivery_phone'] as String?,
      pickupCode: json['pickup_code'] as String? ?? 'PK-0000',
      fulfillmentType: json['fulfillment_type'] as String? ?? 'pickup',
      deliveryAddress: json['delivery_address'] as String?,
      deliveryPhone: json['delivery_phone'] as String?,
      orderStatus: json['order_status'] as String? ?? 'pending',
      estimatedReadyDate: json['estimated_ready_date'] as String?,
      estimatedReadyTime: json['estimated_ready_time'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'manual_transfer',
      paymentReceiptUrl: json['payment_receipt_url'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['is_paid'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      items: items,
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

  Future<List<StoreProduct>> fetchInGymProducts({String? tenantId}) async {
    final client = _supabase;
    if (client == null) return [];

    try {
      var query = client
          .from('products')
          .select('id, tenant_id, name, category, selling_price, stock_quantity, description, image_url')
          .eq('is_active', true);

      if (tenantId != null && tenantId.isNotEmpty) {
        query = query.eq('tenant_id', tenantId);
      }

      final res = await query.order('created_at', ascending: false);
      return (res as List).map((row) => StoreProduct.fromJson(row as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('StoreRepository: fetchInGymProducts error: $e');
      return [];
    }
  }

  Future<String?> createStoreOrder({
    required String pickupCode,
    required double totalAmount,
    required Map<String, int> cartItems,
    required List<StoreProduct> allProducts,
    String fulfillmentType = 'pickup',
    String? deliveryAddress,
    String? deliveryPhone,
    String? customerName,
    String paymentMethod = 'manual_transfer',
    String? paymentReceiptUrl,
    String? tenantId,
  }) async {
    final client = _supabase;
    if (client == null) return null;

    final userId = client.auth.currentUser?.id;
    String effectiveTenantId = tenantId ?? '';

    try {
      // 1. If tenantId not provided, check if any product in cart has tenantId
      if (effectiveTenantId.isEmpty && allProducts.isNotEmpty) {
        final matchedProd = allProducts.where((p) => cartItems.containsKey(p.id) && p.tenantId.isNotEmpty).firstOrNull;
        if (matchedProd != null) {
          effectiveTenantId = matchedProd.tenantId;
        }
      }

      // 2. Fall back to user profile tenantId
      if (effectiveTenantId.isEmpty && userId != null) {
        final profile = await client.from('profiles').select('tenant_id, full_name, phone').eq('id', userId).maybeSingle();
        effectiveTenantId = profile?['tenant_id'] as String? ?? '';
        customerName ??= profile?['full_name'] as String?;
        deliveryPhone ??= profile?['phone'] as String?;
      }

      // 3. Fall back to first tenant in database
      if (effectiveTenantId.isEmpty) {
        final t = await client.from('tenants').select('id').limit(1).maybeSingle();
        effectiveTenantId = t?['id'] as String? ?? '00000000-0000-0000-0000-000000000001';
      }

      final orderRes = await client.from('store_orders').insert({
        'tenant_id': effectiveTenantId,
        'member_id': userId,
        'user_id': userId,
        'pickup_code': pickupCode,
        'fulfillment_type': fulfillmentType,
        'delivery_address': deliveryAddress,
        'delivery_phone': deliveryPhone,
        'customer_name': customerName ?? 'Customer',
        'customer_phone': deliveryPhone,
        'order_status': 'pending',
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'payment_receipt_url': paymentReceiptUrl,
        'is_paid': paymentReceiptUrl != null && paymentReceiptUrl.isNotEmpty,
        'created_at': DateTime.now().toIso8601String(),
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

      return orderId;
    } catch (e) {
      debugPrint('StoreRepository: createStoreOrder error: $e');
      return null;
    }
  }

  Future<List<StoreOrder>> fetchCustomerOrders(String userId) async {
    final client = _supabase;
    if (client == null || userId.isEmpty) return [];

    try {
      final res = await client
          .from('store_orders')
          .select('*, store_order_items(*, products(name, image_url))')
          .or('user_id.eq.$userId,member_id.eq.$userId')
          .order('created_at', ascending: false);

      return (res as List).map((row) => StoreOrder.fromJson(row as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('StoreRepository: fetchCustomerOrders error: $e');
      return [];
    }
  }

  Future<List<StoreOrder>> fetchTenantStoreOrders(String tenantId) async {
    final client = _supabase;
    if (client == null) return [];

    try {
      String effectiveId = tenantId;
      if (effectiveId.isEmpty && client.auth.currentUser != null) {
        final profile = await client.from('profiles').select('tenant_id').eq('id', client.auth.currentUser!.id).maybeSingle();
        effectiveId = profile?['tenant_id'] as String? ?? '';
      }

      var query = client
          .from('store_orders')
          .select('*, store_order_items(*, products(name, image_url))');

      if (effectiveId.isNotEmpty) {
        query = query.eq('tenant_id', effectiveId);
      }

      final res = await query.order('created_at', ascending: false);
      return (res as List).map((row) => StoreOrder.fromJson(row as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('StoreRepository: fetchTenantStoreOrders error: $e');
      return [];
    }
  }

  Future<bool> updateOrderStatusAndSchedule({
    required String orderId,
    required String status,
    String? estimatedReadyDate,
    String? estimatedReadyTime,
  }) async {
    final client = _supabase;
    if (client == null) return false;

    try {
      final payload = <String, dynamic>{
        'order_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (estimatedReadyDate != null) payload['estimated_ready_date'] = estimatedReadyDate;
      if (estimatedReadyTime != null) payload['estimated_ready_time'] = estimatedReadyTime;

      await client.from('store_orders').update(payload).eq('id', orderId);
      return true;
    } catch (e) {
      debugPrint('StoreRepository: updateOrderStatusAndSchedule error: $e');
      return false;
    }
  }

  /// Gym Owner: Add a new product to inventory
  Future<bool> addProduct({
    required String name,
    required String category,
    required double price,
    required int stockQuantity,
    String? description,
    String? imageUrl,
    String? tenantId,
  }) async {
    final client = _supabase;
    if (client == null) return false;

    try {
      String effectiveTenantId = tenantId ?? '';
      if (effectiveTenantId.isEmpty && client.auth.currentUser != null) {
        final profile = await client.from('profiles').select('tenant_id').eq('id', client.auth.currentUser!.id).maybeSingle();
        effectiveTenantId = profile?['tenant_id'] as String? ?? '';
      }
      if (effectiveTenantId.isEmpty) {
        final t = await client.from('tenants').select('id').limit(1).maybeSingle();
        effectiveTenantId = t?['id'] as String? ?? '00000000-0000-0000-0000-000000000001';
      }

      final sku = 'PROD-${DateTime.now().millisecondsSinceEpoch % 100000}';
      await client.from('products').insert({
        'tenant_id': effectiveTenantId,
        'name': name,
        'category': category,
        'sku': sku,
        'cost_price': price * 0.7,
        'selling_price': price,
        'stock_quantity': stockQuantity,
        'description': description ?? '',
        'image_url': imageUrl ?? '',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('StoreRepository: addProduct error: $e');
      return false;
    }
  }

  /// Gym Owner: Delete a product
  Future<bool> deleteProduct(String productId) async {
    final client = _supabase;
    if (client == null || productId.isEmpty) return false;

    try {
      await client.from('products').delete().eq('id', productId);
      return true;
    } catch (e) {
      debugPrint('StoreRepository: deleteProduct error: $e');
      return false;
    }
  }

  /// Gym Owner: Upload product photo to Supabase storage
  Future<String?> uploadProductImage({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/jpeg',
  }) async {
    final client = _supabase;
    if (client == null) return null;

    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = 1000 + (DateTime.now().microsecond % 9000);
      final storagePath = 'products/${timestamp}_$random.$ext';

      String bucketName = 'product_images';
      try {
        await client.storage.from(bucketName).uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );
      } catch (_) {
        bucketName = 'payment_receipts';
        await client.storage.from(bucketName).uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );
      }

      return client.storage.from(bucketName).getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('StoreRepository: uploadProductImage error: $e');
      return null;
    }
  }
}
