import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';
import 'body_type_shape_gallery_dialog.dart';

class BodyTypeCard extends StatelessWidget {
  final BodyTypeInfo? info;
  final String title, subtitle, description, targetPhysique;
  final String? imageAsset, networkImageUrl;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onCustomImageTap;
  final VoidCallback? onImageTap;

  const BodyTypeCard({
    super.key,
    this.info,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.targetPhysique,
    this.imageAsset,
    this.networkImageUrl,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.onCustomImageTap,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? accent : AppColors.border, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: isSelected ? accent.withValues(alpha: 0.2) : Colors.white10, shape: BoxShape.circle),
                  child: Icon(icon, color: isSelected ? accent : AppColors.textSecondary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: isSelected ? accent.withValues(alpha: 0.2) : Colors.white10, borderRadius: BorderRadius.circular(4)),
                            child: Text(subtitle, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? accent : AppColors.textSecondary)),
                          ),
                        ],
                      ),
                      Text(description, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? accent : AppColors.textSecondary.withValues(alpha: 0.4), size: 20),
              ],
            ),
            if (networkImageUrl != null || imageAsset != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  if (onImageTap != null) {
                    onImageTap!();
                  } else if (info != null) {
                    BodyTypeShapeGalleryDialog.show(context, info: info!);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      _buildImage(),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.black.withValues(alpha: 0.25), Colors.black.withValues(alpha: 0.88)],
                            ),
                          ),
                        ),
                      ),
                      // Top badge: Tap to expand & slide target physique photos
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accent.withValues(alpha: 0.6), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_rounded, size: 12, color: accent),
                              const SizedBox(width: 5),
                              Text(
                                (info != null && info!.allImages.length > 1)
                                    ? '${info!.allImages.length} SHAPES • TAP TO SLIDE'
                                    : 'VIEW TARGET SHAPE',
                                style: GoogleFonts.oswald(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8, left: 10, right: 10,
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(targetPhysique, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            if (onCustomImageTap != null)
                              GestureDetector(
                                onTap: onCustomImageTap,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                  child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (networkImageUrl != null && networkImageUrl!.isNotEmpty) {
      return Image.network(
        networkImageUrl!, height: 100, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => imageAsset != null
            ? Image.asset(imageAsset!, height: 100, width: double.infinity, fit: BoxFit.cover)
            : const SizedBox.shrink(),
      );
    }
    return Image.asset(
      imageAsset!, height: 100, width: double.infinity, fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
