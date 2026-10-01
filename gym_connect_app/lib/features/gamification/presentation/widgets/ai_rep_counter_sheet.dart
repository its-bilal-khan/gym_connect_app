import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/rep_counter_state_machine.dart';
import '../providers/ai_rep_counter_provider.dart';

class AiRepCounterSheet extends ConsumerWidget {
  final ExerciseMovementType movementType;
  final int targetReps;
  final void Function(int repsCompleted)? onCompleted;

  const AiRepCounterSheet({
    super.key,
    this.movementType = ExerciseMovementType.squat,
    this.targetReps = 12,
    this.onCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    ExerciseMovementType movementType = ExerciseMovementType.squat,
    int targetReps = 12,
    void Function(int repsCompleted)? onCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AiRepCounterSheet(
        movementType: movementType,
        targetReps: targetReps,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiRepCounterProvider);
    final notifier = ref.read(aiRepCounterProvider.notifier);
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.videocam_rounded, color: accent, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VISION AI REP COUNTER', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('Hands-free pose detection & micro-clip recorder', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (state.isRecordingMicroClip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 10),
                        const SizedBox(width: 4),
                        Text('REC ${state.clipRecordedSeconds}s / 8s', style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Simulated / Live Viewport Box
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.accessibility_new_rounded, size: 80, color: accent.withValues(alpha: 0.7)),
                        const SizedBox(height: 12),
                        Text('${state.completedReps} / ${state.targetReps}', style: GoogleFonts.oswald(fontSize: 54, fontWeight: FontWeight.bold, color: accent)),
                        Text('REPS COMPLETED', style: GoogleFonts.oswald(fontSize: 14, letterSpacing: 1.2, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withValues(alpha: 0.5))),
                          child: Text(state.statusText, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: accent)),
                        ),
                        const SizedBox(height: 6),
                        Text('Joint Angle: ${state.currentAngle.toStringAsFixed(1)}°', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: Text(state.movementType.name.toUpperCase(), style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onCompleted?.call(state.completedReps);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('FINISH & SAVE SET', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => notifier.reset(),
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  tooltip: 'Reset Reps',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
