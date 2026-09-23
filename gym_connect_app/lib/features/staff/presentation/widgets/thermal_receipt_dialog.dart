import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/staff_pos_repository.dart';

class ThermalReceiptDialog extends StatelessWidget {
  final PosReceipt receipt;

  const ThermalReceiptDialog({super.key, required this.receipt});

  static Future<void> show(BuildContext context, PosReceipt receipt) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => ThermalReceiptDialog(receipt: receipt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Text('TITAN FITNESS CLUB', style: GoogleFonts.courierPrime(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))),
              Center(child: Text('Sector C, Commercial Phase 5, DHA Lahore', style: GoogleFonts.courierPrime(fontSize: 10, color: Colors.black87))),
              Center(child: Text('NTN: 8941203-7 • Phone: +92 300 1234567', style: GoogleFonts.courierPrime(fontSize: 10, color: Colors.black87))),
              const Divider(color: Colors.black54, thickness: 1, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('INV: ${receipt.invoiceNumber}', overflow: TextOverflow.ellipsis, style: GoogleFonts.courierPrime(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  const SizedBox(width: 8),
                  Text(receipt.paymentMethod, style: GoogleFonts.courierPrime(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
              Text('DATE: ${receipt.dateTime.toIso8601String().split('T').first} ${receipt.dateTime.hour}:${receipt.dateTime.minute.toString().padLeft(2, '0')}', style: GoogleFonts.courierPrime(fontSize: 10, color: Colors.black87)),
              Text('CASHIER: ${receipt.cashierName}', style: GoogleFonts.courierPrime(fontSize: 10, color: Colors.black87)),
              if (receipt.customerName != null)
                Text('CUSTOMER: ${receipt.customerName}', style: GoogleFonts.courierPrime(fontSize: 10, color: Colors.black87)),
              const Divider(color: Colors.black54, thickness: 1, height: 16),
              ...receipt.items.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${i.quantity}x ${i.product.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black)),
                    ),
                    Text('PKR ${i.totalPrice.toInt()}', style: GoogleFonts.courierPrime(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
              )),
              const Divider(color: Colors.black54, thickness: 1, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SUBTOTAL', style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black)),
                  Text('PKR ${receipt.subtotal.toInt()}', style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black)),
                ],
              ),
              if (receipt.discount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DISCOUNT', style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black)),
                    Text('- PKR ${receipt.discount.toInt()}', style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black)),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL AMOUNT', style: GoogleFonts.courierPrime(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                  Text('PKR ${receipt.total.toInt()}', style: GoogleFonts.courierPrime(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
              const Divider(color: Colors.black54, thickness: 1, height: 16),
              Center(child: Text('*** THANK YOU FOR TRAINING ***', style: GoogleFonts.courierPrime(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
              Center(child: Text('Powered by GymConnect POS System', style: GoogleFonts.courierPrime(fontSize: 9, color: Colors.black54))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: Text('PRINT / CLOSE', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
