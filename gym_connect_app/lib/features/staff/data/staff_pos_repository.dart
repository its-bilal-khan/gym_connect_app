import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../store/data/store_repository.dart';

class PosSaleItem {
  final StoreProduct product;
  final int quantity;
  final double unitPrice;
  double get totalPrice => unitPrice * quantity;

  const PosSaleItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });
}

class PosReceipt {
  final String invoiceNumber;
  final String cashierName;
  final DateTime dateTime;
  final List<PosSaleItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final String? customerName;
  final bool isKhata;

  const PosReceipt({
    required this.invoiceNumber,
    required this.cashierName,
    required this.dateTime,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.customerName,
    this.isKhata = false,
  });
}

final staffPosRepositoryProvider = Provider<StaffPosRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('StaffPosRepository: Supabase client unavailable: $e');
  }
  return StaffPosRepository(client);
});

class StaffPosRepository {
  final SupabaseClient? _supabase;

  const StaffPosRepository(this._supabase);

  Future<PosReceipt> processPosCheckout({
    required List<PosSaleItem> items,
    required String paymentMethod,
    required double discount,
    String? customerName,
    String? memberId,
    String? shiftId,
    String? tenantId,
    String cashierName = 'Staff Cashier',
  }) async {
    final client = _supabase;
    final now = DateTime.now();
    final invoiceNumber = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${1000 + (now.millisecondsSinceEpoch % 8999)}';

    double subtotal = 0.0;
    for (final item in items) {
      subtotal += item.totalPrice;
    }
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final isKhata = paymentMethod.toLowerCase() == 'khata_credit';

    if (client != null && tenantId != null) {
      try {
        final invRes = await client.from('invoices').insert({
          'tenant_id': tenantId,
          'shift_id': shiftId,
          'invoice_number': invoiceNumber,
          'member_id': memberId,
          'customer_name': customerName ?? 'Walk-In Customer',
          'subtotal': subtotal,
          'discount_amount': discount,
          'tax_amount': 0.00,
          'total_amount': total,
          'paid_amount': isKhata ? 0.00 : total,
          'due_amount': isKhata ? total : 0.00,
          'status': isKhata ? 'unpaid' : 'paid',
        }).select('id').single();

        final invoiceId = invRes['id'] as String;

        // Insert items
        final itemsData = items.map((i) => {
          'tenant_id': tenantId,
          'invoice_id': invoiceId,
          'item_type': 'product',
          'product_id': i.product.id,
          'description': i.product.name,
          'quantity': i.quantity,
          'unit_price': i.unitPrice,
          'total_price': i.totalPrice,
        }).toList();

        await client.from('invoice_items').insert(itemsData);

        // Record payment
        if (!isKhata) {
          await client.from('payments').insert({
            'tenant_id': tenantId,
            'invoice_id': invoiceId,
            'member_id': memberId,
            'amount': total,
            'payment_method': paymentMethod.toLowerCase(),
            'transaction_reference': 'POS-TXN-${now.millisecondsSinceEpoch}',
          });
        } else if (memberId != null) {
          // Record Khata Debit
          await client.from('member_khata_ledger').insert({
            'tenant_id': tenantId,
            'member_id': memberId,
            'amount': total,
            'is_debit': true,
            'notes': 'Retail Purchase on Credit #$invoiceNumber',
          });
        }

        // Deduct inventory
        for (final item in items) {
          final newStock = (item.product.stockQuantity - item.quantity).clamp(0, 999999);
          await client.from('products').update({'stock_quantity': newStock}).eq('id', item.product.id);
          await client.from('inventory_transactions').insert({
            'tenant_id': tenantId,
            'product_id': item.product.id,
            'change_quantity': -item.quantity,
            'transaction_type': 'pos_sale',
          });
        }
      } catch (e) {
        debugPrint('StaffPosRepository: processPosCheckout error: $e');
      }
    }

    return PosReceipt(
      invoiceNumber: invoiceNumber,
      cashierName: cashierName,
      dateTime: now,
      items: items,
      subtotal: subtotal,
      discount: discount,
      tax: 0.00,
      total: total,
      paymentMethod: paymentMethod.toUpperCase(),
      customerName: customerName,
      isKhata: isKhata,
    );
  }
}
