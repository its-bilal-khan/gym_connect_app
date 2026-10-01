import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/moderation_queue_provider.dart';

class FlaggedModerationMiniView extends ConsumerWidget {
  final double scale;
  const FlaggedModerationMiniView({super.key, this.scale = 0.85});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moderationQueueProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final pendingCount = state.items.length;
    final hasItems = pendingCount > 0;

    final content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasItems ? Colors.redAccent.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                hasItems ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                color: hasItems ? Colors.amber : accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'FRAUD MODERATION QUEUE',
                  style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasItems ? Colors.redAccent.withValues(alpha: 0.15) : accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasItems ? '$pendingCount PENDING' : 'CLEAN',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: hasItems ? Colors.redAccent : accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: hasItems
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.amber.withValues(alpha: 0.15),
                        child: Icon(state.items.first.proofType == 'diet_photo' ? Icons.fastfood_rounded : Icons.directions_walk_rounded, color: Colors.amber, size: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.items.first.memberName ?? 'Gym Member', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis),
                            Text('+${state.items.first.pointsAwarded} XP • ${state.items.first.proofType}', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Text('REVIEW', style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold, color: accent)),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: accent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('All diet logs & steps clean', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('Dual-View Audit', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ),
              Text('1-Tap Clawback', style: GoogleFonts.inter(fontSize: 10, color: Colors.redAccent)),
            ],
          ),
        ],
      ),
    );

    if (scale != 1.0) {
      return Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        child: SizedBox(width: 320, child: content),
      );
    }
    return content;
  }
}
