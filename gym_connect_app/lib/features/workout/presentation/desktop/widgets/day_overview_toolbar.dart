import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/workout_models.dart';

class DayOverviewToolbar extends StatelessWidget {
  final WorkoutRoutineDay day;
  final ValueChanged<bool> onToggleRestDay;
  final VoidCallback onAddExercise;
  final bool isGridView;
  final ValueChanged<bool> onToggleGridView;
  final bool canEdit;

  const DayOverviewToolbar({
    super.key,
    required this.day,
    required this.onToggleRestDay,
    required this.onAddExercise,
    this.isGridView = false,
    required this.onToggleGridView,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day.title,
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.isRestDay
                      ? 'No physical training • Hydration, mobility, and central nervous system recovery'
                      : 'Target Muscles: ${day.muscleGroups.join(', ')} • ${day.exercises.length} Exercises scheduled',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'REST DAY',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: day.isRestDay ? AppColors.warning : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: day.isRestDay,
                activeThumbColor: AppColors.warning,
                onChanged: canEdit ? onToggleRestDay : null,
              ),
              const SizedBox(width: 16),
              if (!day.isRestDay) ...[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toggleIconBtn(
                        icon: Icons.view_list_rounded,
                        active: !isGridView,
                        tooltip: 'List View',
                        onTap: () => onToggleGridView(false),
                      ),
                      const SizedBox(width: 4),
                      _toggleIconBtn(
                        icon: Icons.grid_view_rounded,
                        active: isGridView,
                        tooltip: 'Grid View',
                        onTap: () => onToggleGridView(true),
                      ),
                    ],
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: onAddExercise,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Exercise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleIconBtn({
    required IconData icon,
    required bool active,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? Colors.black : Colors.white60,
          ),
        ),
      ),
    );
  }
}
