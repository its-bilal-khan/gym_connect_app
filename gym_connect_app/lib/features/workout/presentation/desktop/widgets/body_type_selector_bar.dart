import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/domain/models/user_role.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../domain/models/workout_models.dart';
import '../../providers/body_types_catalog_provider.dart';
import '../../widgets/body_type_shape_gallery_dialog.dart';
import '../../widgets/edit_body_type_dialog.dart';

class BodyTypeSelectorBar extends ConsumerWidget {
  final String selectedBodyType;
  final ValueChanged<String> onSelect;

  const BodyTypeSelectorBar({
    super.key,
    required this.selectedBodyType,
    required this.onSelect,
  });

  static const _defaultIcons = {
    'ectomorph': Icons.accessibility_new_rounded,
    'mesomorph': Icons.fitness_center_rounded,
    'endomorph': Icons.local_fire_department_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(bodyTypesCatalogProvider);
    final authState = ref.watch(authNotifierProvider);
    final canEdit = (authState is AuthAuthenticated) &&
        (authState.activeRole == UserRole.superAdmin || authState.activeRole == UserRole.owner);

    final catalog = catalogAsync.asData?.value ?? const [
      BodyTypeInfo(
        key: 'ectomorph',
        title: 'ECTOMORPH',
        subtitle: 'Lean Build • High Calorie Hypertrophy Split',
        description: 'Fast metabolism & lean build. Requires caloric surplus and hyper-focused compound volume.',
        targetPhysique: 'Outcome: Shredded Athletic V-Taper (6-8% Body Fat)',
        defaultImageAsset: 'assets/images/ectomorph.jpg',
      ),
      BodyTypeInfo(
        key: 'mesomorph',
        title: 'MESOMORPH',
        subtitle: 'Athletic Build • Heavy Compound & Definition',
        description: 'Naturally broad and muscular. Rapid response to progressive overload hypertrophy.',
        targetPhysique: 'Outcome: Dense Muscular Beast (Full Chest & Wide Lats)',
        defaultImageAsset: 'assets/images/mesomorph.jpg',
      ),
      BodyTypeInfo(
        key: 'endomorph',
        title: 'ENDOMORPH',
        subtitle: 'Stocky Build • Metabolic Circuit & High Volume',
        description: 'Thick bone density and raw lifting power. Combined with metabolic conditioning burn.',
        targetPhysique: 'Outcome: Solid Powerlifter Physique (Chiseled Mass)',
        defaultImageAsset: 'assets/images/endomorph.jpg',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 980;
        final imgWidth = isCompact ? 64.0 : 76.0;
        final imgHeight = isCompact ? 52.0 : 60.0;

        return Row(
          children: catalog.map((type) {
            final isSelected = selectedBodyType.toLowerCase() == type.key;
            final icon = _defaultIcons[type.key] ?? Icons.fitness_center_rounded;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: InkWell(
                  onTap: () => onSelect(type.key),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.22),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Professional Physique Image Preview Thumbnail
                        Tooltip(
                          message: 'Tap to view full ${type.title} shape gallery',
                          child: InkWell(
                            onTap: () => BodyTypeShapeGalleryDialog.show(context, info: type),
                            borderRadius: BorderRadius.circular(12),
                            child: _buildPhysiqueImage(
                              type,
                              imgWidth,
                              imgHeight,
                              isSelected,
                              icon,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Middle Info Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      type.title,
                                      style: GoogleFonts.oswald(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: GoogleFonts.oswald(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                type.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 11,
                                    color: isSelected ? AppColors.primary : Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      type.targetPhysique.replaceAll('Outcome: ', ''),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: 0.9)
                                            : AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Right Controls (Edit button & Selection radio)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canEdit)
                              IconButton(
                                icon: Icon(
                                  Icons.edit_note_rounded,
                                  color: isSelected ? AppColors.primary : Colors.white60,
                                  size: 20,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Edit ${type.title} Protocol & Image (Admin/Owner)',
                                onPressed: () => EditBodyTypeDialog.show(context, type),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.white24,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, size: 12, color: Colors.black)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPhysiqueImage(
    BodyTypeInfo type,
    double width,
    double height,
    bool isSelected,
    IconData icon,
  ) {
    final hasRemoteUrl = type.imageUrl != null && type.imageUrl!.trim().isNotEmpty;

    Widget imageContent;
    if (hasRemoteUrl) {
      imageContent = Image.network(
        type.imageUrl!.trim(),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildAssetImage(type, width, height, isSelected, icon),
      );
    } else {
      imageContent = _buildAssetImage(type, width, height, isSelected, icon);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.8),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageContent,
            // Bottom gradient shadow for badge readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom label badge
            Positioned(
              left: 4,
              bottom: 3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 9,
                    color: isSelected ? AppColors.primary : Colors.white70,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    type.key.substring(0, 4).toUpperCase(),
                    style: GoogleFonts.oswald(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isSelected ? AppColors.primary : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // Multi-shape badge if available
            if (type.allImages.length > 1)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 0.8),
                  ),
                  child: Text(
                    '${type.allImages.length} 📸',
                    style: GoogleFonts.inter(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetImage(
    BodyTypeInfo type,
    double width,
    double height,
    bool isSelected,
    IconData icon,
  ) {
    if (type.defaultImageAsset.isNotEmpty) {
      return Image.asset(
        type.defaultImageAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildIconBox(isSelected, icon),
      );
    }
    return _buildIconBox(isSelected, icon);
  }

  Widget _buildIconBox(bool isSelected, IconData icon) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: isSelected ? Colors.black : Colors.white70,
        size: 18,
      ),
    );
  }
}
