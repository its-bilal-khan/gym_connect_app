import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../providers/composite_compliance_provider.dart';

class CompositeComplianceRingCard extends ConsumerWidget {
  const CompositeComplianceRingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final state = ref.watch(compositeComplianceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.isStreakSaved ? accent.withValues(alpha: 0.6) : AppColors.border,
          width: state.isStreakSaved ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildProgressCircle(state, accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'DAILY 80% COMPLIANCE',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildGateBadge(state.isGateVerified, accent),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _getStatusDescription(state),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 10.5, color: state.isStreakSaved ? accent : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: state.progressFraction,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(3),
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(state.isThresholdMet ? accent : Colors.amber),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildComponentChip('WORKOUT', '${state.workoutPct.toInt()}%', '50%'),
              _buildComponentChip('STEPS', '${state.stepPct.toInt()}%', '25%'),
              _buildComponentChip('DIET', '${state.dietPct.toInt()}%', '15%'),
              _buildComponentChip('SLEEP', '${state.sleepPct.toInt()}%', '10%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(CompositeComplianceState state, Color accent) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: CircularProgressIndicator(
            value: state.progressFraction,
            strokeWidth: 4.5,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(state.isThresholdMet ? accent : Colors.amber),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${state.compositePct.toInt()}%', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('/ 80%', style: GoogleFonts.inter(fontSize: 8, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildGateBadge(bool isVerified, Color accent) {
    final color = isVerified ? accent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVerified ? Icons.check_circle_rounded : Icons.lock_outline_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(isVerified ? 'GATE IN' : 'GATE LOCK', style: GoogleFonts.oswald(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildComponentChip(String label, String value, String weight) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textSecondary)),
        const SizedBox(height: 1),
        Text(value, style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        Text('wt $weight', style: GoogleFonts.inter(fontSize: 7.5, color: AppColors.textSecondary)),
      ],
    );
  }

  String _getStatusDescription(CompositeComplianceState state) {
    if (state.isStreakSaved) return 'Streak saved! 80% goal hit & gate verified.';
    if (state.isThresholdMet) return '80% reached! Scan physical gate to lock streak.';
    final rem = (80.0 - state.compositePct).clamp(0.0, 80.0).toStringAsFixed(0);
    return '$rem% remaining to unlock today\'s streak save.';
  }
}
