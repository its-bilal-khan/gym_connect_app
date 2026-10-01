import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/diet_proof_service.dart';
import '../providers/diet_proof_provider.dart';
import 'diet_proof_upload_sheet.dart';

class DietProofCard extends ConsumerWidget {
  final String? tenantId;
  const DietProofCard({super.key, this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final dietState = ref.watch(dietProofProvider);

    final isPhoto = dietState.logType == DietLogType.photoProof;
    final isChecked = dietState.logType == DietLogType.selfCheck;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPhoto ? accent.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (isPhoto ? accent : Colors.orangeAccent).withValues(alpha: 0.15),
            child: Icon(
              Icons.camera_alt_rounded,
              color: isPhoto ? accent : Colors.orangeAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'DIET PHOTO PROOF',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.oswald(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildPointsBadge(dietState.pointsAwarded, accent),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isPhoto
                      ? 'Meal photo submitted • Pending owner review (+15 pts)'
                      : (isChecked
                          ? 'Self-reported tick (+2 pts) • Snap photo for +15'
                          : 'Snap meal photo for +15 points & 15% diet score'),
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => DietProofUploadSheet.show(context, tenantId: tenantId),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                isPhoto ? 'CHANGE' : 'SNAP',
                style: GoogleFonts.oswald(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBadge(int points, Color accent) {
    if (points <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '+$points PTS',
        style: GoogleFonts.oswald(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: accent,
        ),
      ),
    );
  }
}
