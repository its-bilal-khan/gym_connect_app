import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/ai_workout_provider.dart';

class ExerciseSwapSheet extends ConsumerWidget {
  final String dayExerciseId;
  final String currentExerciseName;
  final String targetMuscle;

  const ExerciseSwapSheet({
    super.key,
    required this.dayExerciseId,
    required this.currentExerciseName,
    required this.targetMuscle,
  });

  static Future<void> show(
    BuildContext context, {
    required String dayExerciseId,
    required String currentExerciseName,
    required String targetMuscle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExerciseSwapSheet(
        dayExerciseId: dayExerciseId,
        currentExerciseName: currentExerciseName,
        targetMuscle: targetMuscle,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiWorkoutProvider);
    final candidates = aiState.swapCandidates;
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.70,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1-TAP EXERCISE SWAP', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('Replace "$currentExerciseName" (Target: $targetMuscle)', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('0 PT PENALTY', style: GoogleFonts.oswald(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: candidates.isEmpty
                  ? Center(child: Text('No alternative exercises found for $targetMuscle', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)))
                  : ListView.separated(
                      itemCount: candidates.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final c = candidates[idx];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.fitness_center_rounded, color: accent, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    Text('${c.equipment} • ${c.targetMuscle}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: aiState.isSwapping
                                    ? null
                                    : () async {
                                        HapticFeedback.mediumImpact();
                                        final ok = await ref.read(aiWorkoutProvider.notifier).executeSwap(
                                              dayExerciseId: dayExerciseId,
                                              newExerciseId: c.exerciseId,
                                            );
                                        if (ctx.mounted && ok) {
                                          Navigator.of(ctx).pop();
                                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                            content: Text('Swapped to ${c.name} with 0 penalty!'),
                                            backgroundColor: AppColors.surface,
                                          ));
                                        }
                                      },
                                child: Text('SWAP IN', style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
