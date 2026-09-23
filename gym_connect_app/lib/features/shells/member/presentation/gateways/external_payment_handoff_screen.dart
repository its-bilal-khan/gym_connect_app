import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../membership/data/membership_repository.dart';
import '../../data/payment_launch_service.dart';
import '../widgets/payment_success_receipt_dialog.dart';
import 'widgets/gateway_order_header.dart';

class ExternalPaymentHandoffScreen extends ConsumerStatefulWidget {
  final String method;
  final double amount;
  final String? invoiceId;
  final String invoiceNumber;

  const ExternalPaymentHandoffScreen({
    super.key,
    required this.method,
    required this.amount,
    required this.invoiceId,
    required this.invoiceNumber,
  });

  static Future<void> open(BuildContext context, {required String method, required double amount, String? invoiceId, required String invoiceNumber}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExternalPaymentHandoffScreen(method: method, amount: amount, invoiceId: invoiceId, invoiceNumber: invoiceNumber)),
    );
  }

  @override
  ConsumerState<ExternalPaymentHandoffScreen> createState() => _ExternalPaymentHandoffScreenState();
}

class _ExternalPaymentHandoffScreenState extends ConsumerState<ExternalPaymentHandoffScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PaymentLaunchService.launchPaymentMethod(method: widget.method, amount: widget.amount, invoiceNumber: widget.invoiceNumber);
    });
  }

  Color get _brandColor => widget.method.toLowerCase().contains('jazz') ? const Color(0xFFED1C24) : (widget.method.toLowerCase().contains('easy') ? const Color(0xFF00A859) : Colors.blueAccent);

  Future<void> _verifyAndComplete() async {
    setState(() => _isProcessing = true);
    final prefix = widget.method.toLowerCase().contains('jazz') ? 'JC' : (widget.method.toLowerCase().contains('easy') ? 'EP' : 'CARD');
    final txnRef = '$prefix-TXN-${10000000 + (DateTime.now().millisecondsSinceEpoch % 89999999)}';

    await ref.read(membershipRepositoryProvider).processInvoicePayment(
      invoiceId: widget.invoiceId,
      amount: widget.amount,
      paymentMethod: widget.method,
    );
    ref.invalidate(memberSubscriptionProvider);
    ref.invalidate(pendingInvoiceProvider);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    PaymentSuccessReceiptDialog.show(
      context,
      amount: widget.amount,
      method: '${widget.method} App Handoff',
      transactionRef: txnRef,
      onDone: () {
        Navigator.of(context).pop(); // close receipt
        Navigator.of(context).pop(); // close handoff screen
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final methodUpper = widget.method.toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('$methodUpper OFFICIAL GATEWAY', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GatewayOrderHeader(gatewayName: '${widget.method} Official Checkout', brandColor: _brandColor, brandIcon: Icons.open_in_new_rounded, amount: widget.amount, invoiceNumber: widget.invoiceNumber),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandColor.withValues(alpha: 0.3))),
              child: Column(
                children: [
                  Icon(Icons.phone_android_rounded, size: 48, color: _brandColor),
                  const SizedBox(height: 12),
                  Text('LAUNCHING ${widget.method.toUpperCase()} APP...', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Please complete your payment of PKR ${widget.amount.toInt()} inside your official ${widget.method} app or mobile approval screen.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => PaymentLaunchService.launchPaymentMethod(method: widget.method, amount: widget.amount, invoiceNumber: widget.invoiceNumber),
                    icon: const Icon(Icons.launch_rounded, size: 16),
                    label: Text('RE-LAUNCH ${widget.method.toUpperCase()} APP ↗', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(foregroundColor: _brandColor, side: BorderSide(color: _brandColor.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing ? null : _verifyAndComplete,
              style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('I HAVE COMPLETED PAYMENT IN ${widget.method.toUpperCase()}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
