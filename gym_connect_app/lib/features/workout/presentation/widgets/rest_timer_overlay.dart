import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/rest_timer_notifier.dart';

class RestTimerOverlay extends ConsumerWidget {
  const RestTimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);
    if (!timerState.isRunning && !timerState.isFinished) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isZero = timerState.secondsRemaining == 0;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isZero ? AppColors.error.withValues(alpha: 0.3) : accent.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isZero ? AppColors.error : accent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: timerState.progress,
                        strokeWidth: 3.5,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(isZero ? AppColors.error : accent),
                      ),
                      Icon(
                        isZero ? Icons.alarm_on_rounded : Icons.hourglass_bottom_rounded,
                        size: 16,
                        color: isZero ? AppColors.error : accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isZero ? 'REST COMPLETE — NEXT SET!' : 'REST INTERVAL',
                        style: GoogleFonts.oswald(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isZero ? AppColors.error : accent,
                        ),
                      ),
                      Text(
                        '00:${timerState.secondsRemaining.toString().padLeft(2, '0')}',
                        style: GoogleFonts.oswald(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(restTimerProvider.notifier).addSeconds(15),
                  child: Text(
                    '+15S',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  tooltip: 'Skip Rest',
                  onPressed: () => ref.read(restTimerProvider.notifier).cancelTimer(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
