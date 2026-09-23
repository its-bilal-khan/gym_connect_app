import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../membership/data/membership_repository.dart';
import '../../data/payments_repository.dart';
import '../providers/payments_providers.dart';
import '../widgets/manual_checkout_body.dart';
import '../widgets/manual_payment_pending_dialog.dart';

class ManualCheckoutScreen extends ConsumerStatefulWidget {
  final String tenantId;
  final double amount;
  final String? invoiceId;
  final String invoiceNumber;

  const ManualCheckoutScreen({
    super.key,
    required this.tenantId,
    required this.amount,
    this.invoiceId,
    required this.invoiceNumber,
  });

  static Future<void> open(
    BuildContext context, {
    required String tenantId,
    required double amount,
    String? invoiceId,
    required String invoiceNumber,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualCheckoutScreen(
          tenantId: tenantId,
          amount: amount,
          invoiceId: invoiceId,
          invoiceNumber: invoiceNumber,
        ),
      ),
    );
  }

  @override
  ConsumerState<ManualCheckoutScreen> createState() => _ManualCheckoutScreenState();
}

class _ManualCheckoutScreenState extends ConsumerState<ManualCheckoutScreen> {
  XFile? _selectedFile;
  Uint8List? _imageBytes;
  bool _isSubmitting = false;

  Future<void> _submitProof() async {
    if (_imageBytes == null || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a payment screenshot first', style: GoogleFonts.inter(fontSize: 12)),
          backgroundColor: Colors.amber.shade900,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final repo = ref.read(paymentsRepositoryProvider);

    try {
      final receiptUrl = await repo.uploadReceiptImage(
        bytes: _imageBytes!,
        fileName: _selectedFile!.name,
      );

      if (receiptUrl == null) {
        throw Exception('Failed to upload screenshot to storage');
      }

      final success = await repo.submitManualPayment(
        tenantId: widget.tenantId,
        amount: widget.amount,
        receiptImageUrl: receiptUrl,
        invoiceId: widget.invoiceId,
      );

      if (!success) {
        throw Exception('Failed to record pending payment');
      }

      ref.invalidate(pendingInvoiceProvider);
      ref.invalidate(memberSubscriptionProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await ManualPaymentPendingDialog.show(
        context,
        amount: widget.amount,
        onDismissed: () => Navigator.of(context).pop(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting proof: $e', style: GoogleFonts.inter(fontSize: 12)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(tenantPaymentSettingsProvider(widget.tenantId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('MANUAL PROOF CHECKOUT', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => ManualCheckoutBody(
          settings: null,
          amount: widget.amount,
          selectedFile: _selectedFile,
          imageBytes: _imageBytes,
          isSubmitting: _isSubmitting,
          onImageSelected: (file) => setState(() => _selectedFile = file),
          onBytesLoaded: (bytes) => setState(() => _imageBytes = bytes),
          onSubmit: _submitProof,
        ),
        data: (settings) {
          return ManualCheckoutBody(
            settings: settings,
            amount: widget.amount,
            selectedFile: _selectedFile,
            imageBytes: _imageBytes,
            isSubmitting: _isSubmitting,
            onImageSelected: (file) => setState(() => _selectedFile = file),
            onBytesLoaded: (bytes) => setState(() => _imageBytes = bytes),
            onSubmit: _submitProof,
          );
        },
      ),
    );
  }
}
