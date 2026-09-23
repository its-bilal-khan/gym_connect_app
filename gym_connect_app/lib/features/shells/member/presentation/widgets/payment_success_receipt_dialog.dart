import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class PaymentSuccessReceiptDialog extends StatelessWidget {
  final double amount;
  final String method;
  final String transactionRef;
  final VoidCallback onDone;

  const PaymentSuccessReceiptDialog({
    super.key,
    required this.amount,
    required this.method,
    required this.transactionRef,
    required this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required double amount,
    required String method,
    required String transactionRef,
    required VoidCallback onDone,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentSuccessReceiptDialog(
        amount: amount,
        method: method,
        transactionRef: transactionRef,
        onDone: onDone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.greenAccent)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 54),
            const SizedBox(height: 12),
            Text('PAYMENT CONFIRMED!', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('Your membership is active and gate access unlocked.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  _row('Amount Paid', 'PKR ${amount.toInt()}'),
                  _row('Payment Method', method),
                  _row('Transaction Ref', transactionRef),
                  _row('Status', 'VERIFIED & PAID', isAccent: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: onDone,
              child: Text('DONE', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isAccent ? Colors.greenAccent : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
