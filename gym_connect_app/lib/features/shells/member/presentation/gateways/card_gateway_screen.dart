import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import 'package:gym_connect_app/features/membership/data/membership_repository.dart';
import '../widgets/payment_success_receipt_dialog.dart';
import 'widgets/gateway_order_header.dart';
import 'widgets/gateway_pin_input.dart';

class CardGatewayScreen extends ConsumerStatefulWidget {
  final double amount;
  final String? invoiceId;
  final String invoiceNumber;

  const CardGatewayScreen({
    super.key,
    required this.amount,
    required this.invoiceId,
    required this.invoiceNumber,
  });

  static Future<void> open(BuildContext context, {required double amount, String? invoiceId, required String invoiceNumber}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CardGatewayScreen(amount: amount, invoiceId: invoiceId, invoiceNumber: invoiceNumber)),
    );
  }

  @override
  ConsumerState<CardGatewayScreen> createState() => _CardGatewayScreenState();
}

class _CardGatewayScreenState extends ConsumerState<CardGatewayScreen> {
  final _nameController = TextEditingController(text: 'Ahmad Raza');
  final _cardController = TextEditingController(text: '4242 •••• •••• 4242');
  final _otpController = TextEditingController(text: '849201');
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cardController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _authorizePayment() async {
    setState(() => _isProcessing = true);
    final txnRef = 'CARD-TXN-${10000000 + (DateTime.now().millisecondsSinceEpoch % 89999999)}';
    await ref.read(membershipRepositoryProvider).processInvoicePayment(
      invoiceId: widget.invoiceId,
      amount: widget.amount,
      paymentMethod: 'Debit / Credit Card',
    );
    ref.invalidate(memberSubscriptionProvider);
    ref.invalidate(pendingInvoiceProvider);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    PaymentSuccessReceiptDialog.show(
      context,
      amount: widget.amount,
      method: 'Visa / Mastercard ending in 4242',
      transactionRef: txnRef,
      onDone: () {
        Navigator.of(context).pop(); // close receipt
        Navigator.of(context).pop(); // close gateway
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF1A1F71);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1030),
        title: Text('3D-SECURE CARD GATEWAY', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GatewayOrderHeader(
              gatewayName: 'Visa / Mastercard 3DS',
              brandColor: brandColor,
              brandIcon: Icons.credit_card_rounded,
              amount: widget.amount,
              invoiceNumber: widget.invoiceNumber,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.contactless_rounded, color: Colors.white70, size: 24),
                      Text('VISA', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(_cardController.text, style: GoogleFonts.oswald(fontSize: 18, letterSpacing: 2, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_nameController.text.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70)),
                      Text('EXP: 12/28', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GatewayPinInput(length: 6, controller: _otpController, accentColor: Colors.blueAccent),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3))),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Bank OTP dispatched to +92 300 ******67. Verified by Visa.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing ? null : _authorizePayment,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
