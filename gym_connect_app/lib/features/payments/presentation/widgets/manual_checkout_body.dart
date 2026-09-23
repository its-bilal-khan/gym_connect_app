import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/tenant_payment_settings.dart';
import 'manual_bank_details_card.dart';
import 'receipt_upload_picker.dart';

class ManualCheckoutBody extends StatelessWidget {
  final TenantPaymentSettings? settings;
  final double amount;
  final XFile? selectedFile;
  final Uint8List? imageBytes;
  final bool isSubmitting;
  final ValueChanged<XFile?> onImageSelected;
  final ValueChanged<Uint8List?> onBytesLoaded;
  final VoidCallback onSubmit;

  const ManualCheckoutBody({
    super.key,
    required this.settings,
    required this.amount,
    required this.selectedFile,
    required this.imageBytes,
    required this.isSubmitting,
    required this.onImageSelected,
    required this.onBytesLoaded,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ManualBankDetailsCard(
            easypaisaNumber: settings?.manualEasypaisaNumber,
            bankDetails: settings?.manualBankDetails,
            amount: amount,
          ),
          const SizedBox(height: 20),
          ReceiptUploadPicker(
            selectedFile: selectedFile,
            imageBytes: imageBytes,
            isUploading: isSubmitting,
            onImageSelected: onImageSelected,
            onBytesLoaded: onBytesLoaded,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text('SUBMIT SCREENSHOT FOR APPROVAL', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
