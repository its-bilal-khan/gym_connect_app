import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../providers/sleep_tracker_provider.dart';
import 'sleep_logging_sheet.dart';

class SleepTrackerCard extends ConsumerWidget {
  final String? tenantId;
  const SleepTrackerCard({super.key, this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final sleepState = ref.watch(sleepTrackerProvider);

    final hasLogged = sleepState.hoursLogged > 0;
    final isSensor = sleepState.isSensorVerified;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLogged ? accent.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (hasLogged ? accent : Colors.purpleAccent).withValues(alpha: 0.15),
            child: Icon(
              Icons.bedtime_rounded,
              color: hasLogged ? accent : Colors.purpleAccent,
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
                        'SLEEP RECOVERY',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.oswald(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildPointsBadge(sleepState.pointsAwarded, accent),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasLogged
                      ? '${sleepState.hoursLogged} hrs logged • ${isSensor ? "Sensor Verified" : "Self-Reported"}'
                      : 'Auto-sync from HealthKit / Health Connect',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => SleepLoggingSheet.show(context, tenantId: tenantId),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                hasLogged ? 'EDIT' : 'SYNC',
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
