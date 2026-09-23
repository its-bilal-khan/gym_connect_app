import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import 'package:gym_connect_app/features/membership/data/membership_repository.dart';
import '../widgets/payment_success_receipt_dialog.dart';
import 'widgets/gateway_order_header.dart';
import 'widgets/gateway_pin_input.dart';

class EasyPaisaGatewayScreen extends ConsumerStatefulWidget {
  final double amount;
  final String? invoiceId;
  final String invoiceNumber;

  const EasyPaisaGatewayScreen({
    super.key,
    required this.amount,
    required this.invoiceId,
    required this.invoiceNumber,
  });

  static Future<void> open(BuildContext context, {required double amount, String? invoiceId, required String invoiceNumber}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EasyPaisaGatewayScreen(amount: amount, invoiceId: invoiceId, invoiceNumber: invoiceNumber)),
    );
  }

  @override
  ConsumerState<EasyPaisaGatewayScreen> createState() => _EasyPaisaGatewayScreenState();
}

class _EasyPaisaGatewayScreenState extends ConsumerState<EasyPaisaGatewayScreen> {
  final _mobileController = TextEditingController(text: '03451234567');
  final _pinController = TextEditingController(text: '92810');
  bool _isProcessing = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _authorizePayment() async {
    setState(() => _isProcessing = true);
    final txnRef = 'EP-TXN-${10000000 + (DateTime.now().millisecondsSinceEpoch % 89999999)}';
    await ref.read(membershipRepositoryProvider).processInvoicePayment(
      invoiceId: widget.invoiceId,
      amount: widget.amount,
      paymentMethod: 'EasyPaisa',
    );
    ref.invalidate(memberSubscriptionProvider);
    ref.invalidate(pendingInvoiceProvider);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    PaymentSuccessReceiptDialog.show(
      context,
      amount: widget.amount,
      method: 'EasyPaisa Wallet (${_mobileController.text})',
      transactionRef: txnRef,
      onDone: () {
        Navigator.of(context).pop(); // close receipt
        Navigator.of(context).pop(); // close gateway
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF00A859);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF002413),
        title: Text('EASYPAISA SECURE GATEWAY', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GatewayOrderHeader(
              gatewayName: 'EasyPaisa Direct Wallet',
              brandColor: brandColor,
              brandIcon: Icons.phone_android_rounded,
              amount: widget.amount,
              invoiceNumber: widget.invoiceNumber,
            ),
            const SizedBox(height: 18),
            Text('EASYPAISA REGISTERED NUMBER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
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
            GatewayPinInput(length: 5, controller: _pinController, accentColor: brandColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: brandColor.withValues(alpha: 0.3))),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: brandColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Telenor Microfinance Bank approval request active for 2 minutes.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary))),
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
