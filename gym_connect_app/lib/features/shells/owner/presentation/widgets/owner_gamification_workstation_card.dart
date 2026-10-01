import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/flagged_fraud_moderation_dialog.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/flagged_moderation_mini_view.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/owner_reward_configurator_dialog.dart';
import 'package:gym_connect_app/features/gamification/presentation/widgets/reward_configurator_mini_view.dart';

class OwnerGamificationWorkstationCard extends StatelessWidget {
  final String tenantId;
  final String reviewerId;

  const OwnerGamificationWorkstationCard({
    super.key,
    required this.tenantId,
    required this.reviewerId,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final headerInfo = Row(
                children: [
                  Icon(Icons.military_tech_rounded, color: accent, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GAMIFICATION & REWARDS WORKSTATION',
                          style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Podium prize configuration, automated Rs. 0 fulfillment, and proof-of-effort moderation',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionButtons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => OwnerRewardConfiguratorDialog.show(context, tenantId: tenantId),
                    icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                    label: Text('CONFIG REWARDS', style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => FlaggedFraudModerationDialog.show(context, tenantId: tenantId, reviewerId: reviewerId),
                    icon: const Icon(Icons.verified_user_rounded, size: 16),
                    label: Text('AUDIT QUEUE', style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: AppColors.border)),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: headerInfo),
                    const SizedBox(width: 12),
                    actionButtons,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerInfo,
                  const SizedBox(height: 12),
                  actionButtons,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              if (!isWide) {
                return const Column(
                  children: [
                    RewardConfiguratorMiniView(scale: 1.0),
                    SizedBox(height: 12),
                    FlaggedModerationMiniView(scale: 1.0),
                  ],
                );
              }
              return const Row(
                children: [
                  Expanded(child: RewardConfiguratorMiniView(scale: 1.0)),
                  SizedBox(width: 16),
                  Expanded(child: FlaggedModerationMiniView(scale: 1.0)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
