import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../providers/composite_compliance_provider.dart';

class CompositeComplianceMiniView extends ConsumerWidget {
  final double scale;
  const CompositeComplianceMiniView({super.key, this.scale = 0.85});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final state = ref.watch(compositeComplianceProvider);

    return Transform.scale(
      scale: scale,
      alignment: Alignment.topLeft,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: state.isStreakSaved ? accent.withValues(alpha: 0.5) : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    value: state.progressFraction,
                    strokeWidth: 3.5,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.isThresholdMet ? accent : Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COMPLIANCE LIVE',
                        style: GoogleFonts.oswald(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${state.compositePct.toInt()}% of 80% • ${state.isStreakSaved ? "Saved" : "Pending"}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: state.isStreakSaved ? accent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  state.isGateVerified ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                  size: 14,
                  color: state.isGateVerified ? accent : Colors.redAccent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: state.progressFraction,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                state.isThresholdMet ? accent : Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
