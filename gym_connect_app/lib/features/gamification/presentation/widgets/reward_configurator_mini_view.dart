import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/owner_reward_config_provider.dart';

class RewardConfiguratorMiniView extends ConsumerWidget {
  final double scale;
  const RewardConfiguratorMiniView({super.key, this.scale = 0.85});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerRewardConfigProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final config = state.config;

    final content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'REWARD CONFIGURATOR',
                  style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  'Min ${config.minMonthlyWorkoutsQualification} Workouts',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildRankRow(1, config.rank1Title, Colors.amber),
                const SizedBox(height: 4),
                _buildRankRow(2, config.rank2Title, const Color(0xFFC0C0C0)),
                const SizedBox(height: 4),
                _buildRankRow(3, config.rank3Title, const Color(0xFFCD7F32)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('Ledger: ${state.ledger.length} records', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ),
              Text('Rs. 0 Auto-Fulfill', style: GoogleFonts.inter(fontSize: 10, color: accent)),
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

  Widget _buildRankRow(int rank, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Text('#$rank', style: GoogleFonts.oswald(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
