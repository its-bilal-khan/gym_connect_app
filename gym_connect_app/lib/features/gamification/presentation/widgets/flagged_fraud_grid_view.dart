import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/models.dart';

class FlaggedFraudGridView extends StatelessWidget {
  final List<FlaggedQueueItem> items;
  final String reviewerId;
  final void Function(String queueId) onApprove;
  final void Function(String queueId) onClawback;

  const FlaggedFraudGridView({
    super.key,
    required this.items,
    required this.reviewerId,
    required this.onApprove,
    required this.onClawback,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_rounded, size: 44, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text('QUEUE IS 100% CLEAN', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('No suspicious diet photos or manual step overrides pending review.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final accent = Theme.of(context).colorScheme.primary;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.amber.withValues(alpha: 0.15),
                    child: Icon(item.proofType == 'diet_photo' ? Icons.fastfood_rounded : Icons.directions_walk_rounded, color: Colors.amber, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.memberName ?? 'Gym Member', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('+${item.pointsAwarded} XP Claimed', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: accent)),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.flaggedReason != null)
                Text(item.flaggedReason!, style: GoogleFonts.inter(fontSize: 9, color: Colors.redAccent), maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onApprove(item.id),
                      style: ElevatedButton.styleFrom(backgroundColor: accent.withValues(alpha: 0.15), foregroundColor: accent, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 4)),
                      child: Text('APPROVE', style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onClawback(item.id),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.15), foregroundColor: Colors.redAccent, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 4)),
                      child: Text('CLAWBACK', style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
