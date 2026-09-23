import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import 'package:gym_connect_app/features/membership/data/membership_repository.dart';
import '../widgets/payment_success_receipt_dialog.dart';
import 'widgets/gateway_order_header.dart';
import 'widgets/gateway_pin_input.dart';

class JazzCashGatewayScreen extends ConsumerStatefulWidget {
  final double amount;
  final String? invoiceId;
  final String invoiceNumber;

  const JazzCashGatewayScreen({
    super.key,
    required this.amount,
    required this.invoiceId,
    required this.invoiceNumber,
  });

  static Future<void> open(BuildContext context, {required double amount, String? invoiceId, required String invoiceNumber}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JazzCashGatewayScreen(amount: amount, invoiceId: invoiceId, invoiceNumber: invoiceNumber)),
    );
  }

  @override
  ConsumerState<JazzCashGatewayScreen> createState() => _JazzCashGatewayScreenState();
}

class _JazzCashGatewayScreenState extends ConsumerState<JazzCashGatewayScreen> {
  final _mobileController = TextEditingController(text: '03001234567');
  final _pinController = TextEditingController(text: '7821');
  bool _isProcessing = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _authorizePayment() async {
    setState(() => _isProcessing = true);
    final txnRef = 'JC-TXN-${10000000 + (DateTime.now().millisecondsSinceEpoch % 89999999)}';
    await ref.read(membershipRepositoryProvider).processInvoicePayment(
      invoiceId: widget.invoiceId,
      amount: widget.amount,
      paymentMethod: 'JazzCash',
    );
    ref.invalidate(memberSubscriptionProvider);
    ref.invalidate(pendingInvoiceProvider);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    PaymentSuccessReceiptDialog.show(
      context,
      amount: widget.amount,
      method: 'JazzCash Mobile Account (${_mobileController.text})',
      transactionRef: txnRef,
      onDone: () {
        Navigator.of(context).pop(); // close receipt
        Navigator.of(context).pop(); // close gateway
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFED1C24);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0002),
        title: Text('JAZZCASH SECURE GATEWAY', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GatewayOrderHeader(
              gatewayName: 'JazzCash Direct Debit',
              brandColor: brandColor,
              brandIcon: Icons.account_balance_wallet_rounded,
              amount: widget.amount,
              invoiceNumber: widget.invoiceNumber,
            ),
            const SizedBox(height: 18),
            Text('JAZZCASH ACCOUNT NUMBER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_iphone_rounded, color: brandColor),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 16),
            GatewayPinInput(length: 4, controller: _pinController, accentColor: brandColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('You will receive a USSD push confirmation prompt on your Jazz SIM.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing ? null : _authorizePayment,
              style: ElevatedButton.styleFrom(backgroundColor: brandColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('AUTHORIZE & PAY PKR ${widget.amount.toInt()}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
