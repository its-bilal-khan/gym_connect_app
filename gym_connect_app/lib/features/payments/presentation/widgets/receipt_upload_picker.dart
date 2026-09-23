import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';

class ReceiptUploadPicker extends StatelessWidget {
  final XFile? selectedFile;
  final Uint8List? imageBytes;
  final bool isUploading;
  final ValueChanged<XFile?> onImageSelected;
  final ValueChanged<Uint8List?> onBytesLoaded;

  const ReceiptUploadPicker({
    super.key,
    required this.selectedFile,
    required this.imageBytes,
    required this.isUploading,
    required this.onImageSelected,
    required this.onBytesLoaded,
  });

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      // Crucial: apply imageQuality: 40 and maxWidth: 1080 to minimize storage & speed up upload
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
        maxWidth: 1080,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        onImageSelected(picked);
        onBytesLoaded(bytes);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick screenshot: $e', style: GoogleFonts.inter(fontSize: 12)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedFile != null && imageBytes != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage ? AppColors.primary.withValues(alpha: 0.6) : AppColors.border,
          width: hasImage ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROOF OF PAYMENT',
                style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              if (hasImage)
                Text(
                  '${(imageBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB (Optimized)',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.memory(
                    imageBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.7)),
                      onPressed: isUploading
                          ? null
                          : () {
                              onImageSelected(null);
                              onBytesLoaded(null);
                            },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isUploading ? null : () => _pickImage(context),
              icon: const Icon(Icons.photo_library_outlined, size: 16),
              label: Text('CHANGE SCREENSHOT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: isUploading ? null : () => _pickImage(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      radius: 26,
                      child: Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload Screenshot of Payment',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to open device gallery (Max 1080px, Auto-compressed)',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
