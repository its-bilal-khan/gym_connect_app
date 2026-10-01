import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../providers/diet_proof_provider.dart';

class DietProofUploadSheet extends ConsumerWidget {
  final String? tenantId;
  const DietProofUploadSheet({super.key, this.tenantId});

  static Future<void> show(BuildContext context, {String? tenantId}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DietProofUploadSheet(tenantId: tenantId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final dietState = ref.watch(dietProofProvider);
    final currentTenant = tenantId ?? 'default_tenant';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('UPLOAD MEAL PROOF', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'CAMERA SNAP (+15 PTS)',
            subtitle: 'Take a live photo of your meal plate',
            icon: Icons.camera_alt_rounded,
            color: accent,
            textColor: Colors.black,
            isLoading: dietState.isUploading,
            onTap: () async {
              final ok = await ref.read(dietProofProvider.notifier).snapAndUploadPhoto(tenantId: currentTenant, source: ImageSource.camera);
              if (ok && context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'CHOOSE FROM GALLERY (+15 PTS)',
            subtitle: 'Upload a meal photo from your gallery',
            icon: Icons.photo_library_rounded,
            color: AppColors.background,
            textColor: Colors.white,
            borderColor: AppColors.border,
            isLoading: dietState.isUploading,
            onTap: () async {
              final ok = await ref.read(dietProofProvider.notifier).snapAndUploadPhoto(tenantId: currentTenant, source: ImageSource.gallery);
              if (ok && context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () async {
              await ref.read(dietProofProvider.notifier).logSelfCheck(tenantId: currentTenant);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.textSecondary, size: 16),
            label: Text('No photo? Log simple self-check (+2 PTS)', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 4),
          Text(
            'Anti-Cheat Protection: Meal photos are audited by gym staff. Fraudulent uploads lead to point clawback.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color textColor,
    Color? borderColor,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: borderColor != null ? Border.all(color: borderColor) : null),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: textColor.withValues(alpha: 0.7))),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else
              Icon(Icons.arrow_forward_ios_rounded, color: textColor.withValues(alpha: 0.6), size: 12),
          ],
        ),
      ),
    );
  }
}
