import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class PedometerCard extends StatelessWidget {
  final int steps;
  final double distanceKm;
  final int caloriesBurned;
  final bool isLive;
  final bool isWaiting;
  final String? errorMessage;
  final String? badgeText;
  final bool isHealthConnectMissing;
  final VoidCallback? onTap;

  const PedometerCard({
    super.key,
    this.steps = 0,
    this.distanceKm = 0.0,
    this.caloriesBurned = 0,
    this.isLive = false,
    this.isWaiting = false,
    this.errorMessage,
    this.badgeText,
    this.isHealthConnectMissing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showWaiting = (isWaiting || (!isLive && steps == 0) || errorMessage != null) && !isHealthConnectMissing;
    final titleText = steps == 0 ? '0 steps' : '$steps STEPS TODAY';

    final String subtitleText;
    if (isHealthConnectMissing) {
      subtitleText = 'Health Connect required • Tap to install';
    } else if (errorMessage != null && (badgeText == 'OPEN SETTINGS' || badgeText == 'PERMISSION NEEDED')) {
      subtitleText = errorMessage!;
    } else if (showWaiting) {
      subtitleText = 'Waiting for motion...';
    } else {
      subtitleText = '$distanceKm km • $caloriesBurned kcal burned • Live Health Sync';
    }

    final String effectiveBadge;
    final Color badgeColor;
    if (badgeText != null) {
      effectiveBadge = badgeText!;
      badgeColor = isLive ? AppColors.primaryAccent : Colors.orange;
    } else if (isHealthConnectMissing) {
      effectiveBadge = 'INSTALL HEALTH CONNECT';
      badgeColor = Colors.orange;
    } else if (isLive) {
      effectiveBadge = 'HARDWARE LIVE';
      badgeColor = AppColors.primaryAccent;
    } else {
      effectiveBadge = 'WAITING FOR MOTION';
      badgeColor = Colors.orange;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.directions_walk_rounded, color: AppColors.primaryAccent, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          titleText,
                          style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            effectiveBadge,
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
