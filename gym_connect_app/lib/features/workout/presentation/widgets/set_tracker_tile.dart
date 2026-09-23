import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';

class SetTrackerTile extends StatelessWidget {
  final WorkoutSetRecord record;
  final VoidCallback onToggle;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;

  const SetTrackerTile({
    super.key,
    required this.record,
    required this.onToggle,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: record.isCompleted
            ? accent.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.isCompleted ? accent.withValues(alpha: 0.4) : AppColors.border,
          width: record.isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SET ${record.setNumber}',
                  style: GoogleFonts.oswald(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: record.isCompleted ? accent : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    _buildMetricEditor(
                      label: 'KG',
                      value: record.weightKg.toStringAsFixed(1),
                      onIncrement: () => onWeightChanged(record.weightKg + 2.5),
                      onDecrement: () => onWeightChanged((record.weightKg - 2.5).clamp(0.0, 500.0)),
                    ),
                    const SizedBox(width: 12),
                    _buildMetricEditor(
                      label: 'REPS',
                      value: '${record.actualReps}',
                      onIncrement: () => onRepsChanged(record.actualReps + 1),
                      onDecrement: () => onRepsChanged((record.actualReps - 1).clamp(0, 100)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onToggle();
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: record.isCompleted ? accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: record.isCompleted ? accent : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: record.isCompleted
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 22,
                    color: record.isCompleted ? Colors.black : AppColors.border,
                  ),
                ),
              ),
            ],
          ),
          if (!record.isCompleted && record.weightKg > 0) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onWeightChanged(record.weightKg + 2.5);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, size: 13, color: accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '+2.5 KG AI Overload Suggested (Tap to apply)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricEditor({
    required String label,
    required String value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            Text(value, style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(width: 4),
        Column(
          children: [
            InkWell(
              onTap: onIncrement,
              child: const Icon(Icons.arrow_drop_up_rounded, size: 16, color: AppColors.textSecondary),
            ),
            InkWell(
              onTap: onDecrement,
              child: const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
