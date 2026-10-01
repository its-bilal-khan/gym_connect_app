import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';
import 'package:gym_connect_app/features/workout/presentation/providers/workout_protocol_manager_provider.dart';
import 'package:gym_connect_app/features/workout/presentation/widgets/exercise_video_preview_thumbnail.dart';

/// 1:1 exact replica of Desktop Workout Protocol Studio screen matching user screenshot.
class MiniWorkoutProtocolPreview extends ConsumerWidget {
  final String tenantId;

  const MiniWorkoutProtocolPreview({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final protocolState = ref.watch(workoutProtocolManagerProvider);
    final selectedBodyType = protocolState.selectedBodyType.toUpperCase();
    final isMeso = selectedBodyType.contains('MESO') || selectedBodyType.isEmpty;
    final isEcto = selectedBodyType.contains('ECTO');
    final isEndo = selectedBodyType.contains('ENDO');

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Container(
          width: 1024,
          height: 492,
          color: const Color(0xFF09090B),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141418),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_back_rounded, size: 11, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text('Back', style: GoogleFonts.inter(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'WORKOUT PROTOCOL STUDIO',
                          style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'USING MASTER DEFAULT',
                            style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Desktop POS Routine Studio • Overriding workout split for this gym only',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 7.5, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_done_rounded, size: 9, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text('SAVED TO CLOUD', style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.save_rounded, size: 9, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('Save Gym Protocol', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. Somatotype Protocols Row (3 cards across full width)
              Row(
                children: [
                  Expanded(
                    child: _buildSomatotypeCard(
                      name: 'ECTOMORPH',
                      fullTitle: 'ECTOMORPH Global Master Protocol',
                      desc1: 'Lean Build • High Calorie Hypertrophy Split',
                      desc2: 'Shredded Athletic V-Taper (6-8% Body Fat)',
                      assetImage: 'assets/images/ectomorph.jpg',
                      isActive: isEcto,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSomatotypeCard(
                      name: 'MESOMORPH',
                      fullTitle: 'Mesomorph: Athletic Power & V-Taper',
                      desc1: 'Athletic Build • Heavy Compound & Definition',
                      desc2: 'Dense Muscular Beast (Full Chest & Wide Lats)',
                      assetImage: 'assets/images/mesomorph.jpg',
                      isActive: isMeso,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSomatotypeCard(
                      name: 'ENDOMORPH',
                      fullTitle: 'Endomorph: Metabolic Shred & Furnace',
                      desc1: 'Stocky Build • Metabolic Circuit & High Volume',
                      desc2: 'Solid Powerlifter Physique (Chiseled Mass)',
                      assetImage: 'assets/images/endomorph.jpg',
                      isActive: isEndo,
                      accent: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 3. 7-Day Split Tabs
              Row(
                children: [
                  _buildDaySplitTab('DAY 1', 'Chest & Shoulders', '2 Exercises', isChest: true, isActive: true, accent: accent),
                  const SizedBox(width: 5),
                  _buildDaySplitTab('DAY 2', 'Back & Biceps', '1 Exercise', isActive: false, accent: accent),
                  const SizedBox(width: 5),
                  _buildDaySplitTab('DAY 3', 'Legs', '1 Exercise', isActive: false, accent: accent),
                  const SizedBox(width: 5),
                  _buildDaySplitTab('DAY 4', 'Shoulders & Upper Ba...', '1 Exercise', isActive: false, accent: accent),
                  const SizedBox(width: 5),
                  _buildDaySplitTab('DAY 5', 'Full Body', '2 Exercises', isActive: false, accent: accent),
                  const SizedBox(width: 5),
                  _buildDaySplitTab('DAY 6', 'Arms & Calves', '1 Exercise', isActive: false, accent: accent),
                  const SizedBox(width: 5),
                  _buildDaySplitTab('DAY 7', 'Rest', 'Recovery Protocol', isActive: false, isRest: true, accent: accent),
                ],
              ),
              const SizedBox(height: 8),

              // 4. Day Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Day 1: Heavy Push & Delts',
                          style: GoogleFonts.oswald(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Target Muscles: Chest, Shoulders • 2 Exercises scheduled',
                          style: GoogleFonts.inter(fontSize: 7.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('REST DAY', style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w600, color: Colors.white60)),
                        const SizedBox(width: 4),
                        Container(
                          width: 20,
                          height: 11,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.5), color: Colors.white24),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(width: 9, height: 9, margin: const EdgeInsets.all(1), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.format_list_bulleted_rounded, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Icon(Icons.grid_view_rounded, size: 11, color: const Color(0xFF38BDF8)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 9, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 2),
                              Text(
                                'ADD EXERCISE',
                                style: GoogleFonts.inter(fontSize: 7.2, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 5. Exercise Cards Row: Exactly 2 cards on the left, empty on right!
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Exercise Card #1: Dumbbell Overhead Shoulder Press
                    SizedBox(
                      width: 240,
                      child: _buildExactExerciseCard(
                        number: '#1',
                        title: 'Dumbbell Overhead Shoulder Press',
                        muscle: 'ANTERIOR & LATERAL DELTS',
                        equipment: 'Dumbbells',
                        sets: '4',
                        reps: '6-8',
                        rest: '90s',
                        rpe: 'RPE 8.5',
                        isBench: true,
                        accent: accent,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Exercise Card #2: Full Range Push-Up Form
                    SizedBox(
                      width: 240,
                      child: _buildExactExerciseCard(
                        number: '#2',
                        title: 'Full Range Push-Up Form',
                        muscle: 'CHEST & CORE',
                        equipment: 'Bodyweight',
                        sets: '4',
                        reps: '8-10',
                        rest: '60s',
                        rpe: 'RPE 8.0',
                        isBench: false,
                        accent: accent,
                      ),
                    ),

                    // Empty dark background on the right (matches Image 2 perfectly!)
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        );

        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: 1024,
            height: 492,
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildSomatotypeCard({
    required String name,
    required String fullTitle,
    required String desc1,
    required String desc2,
    required String assetImage,
    required bool isActive,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isActive ? const Color(0xFF2563EB) : Colors.white12,
          width: isActive ? 1.5 : 0.8,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Image.asset(
                assetImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white12,
                  child: const Icon(Icons.fitness_center_rounded, size: 16, color: Colors.white54),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.oswald(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        fullTitle.replaceFirst('$name ', '').replaceFirst(name, ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.oswald(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    if (isActive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                        decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2)),
                        child: Text('ACTIVE', style: GoogleFonts.inter(fontSize: 5, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.check_circle_rounded, size: 9, color: Color(0xFF38BDF8)),
                    ],
                  ],
                ),
                Text(desc1, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 6.5, color: Colors.white70)),
                Text(desc2, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 6.0, color: const Color(0xFFFBBF24))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySplitTab(String code, String name, String count, {bool isChest = false, required bool isActive, bool isRest = false, required Color accent}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E293B) : const Color(0xFF141418),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isActive ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.08),
            width: isActive ? 1.2 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isChest ? '$code: CHEST' : code,
                  style: GoogleFonts.oswald(fontSize: 8, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF38BDF8) : Colors.white),
                ),
                if (isRest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                    child: Text('REST', style: GoogleFonts.inter(fontSize: 5, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ),
              ],
            ),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 6.5, color: Colors.white70)),
            Text(count, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 5.8, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildExactExerciseCard({
    required String number,
    required String title,
    required String muscle,
    required String equipment,
    required String sets,
    required String reps,
    required String rest,
    required String rpe,
    required bool isBench,
    required Color accent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16161B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    number,
                    style: GoogleFonts.jetBrainsMono(fontSize: 7.5, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        '$muscle • $equipment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 6.5, color: const Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.drag_indicator_rounded, size: 9, color: Colors.white38),
                const SizedBox(width: 3),
                const Icon(Icons.delete_outline_rounded, size: 9, color: Colors.redAccent),
              ],
            ),
          ),

          // Exact Realistic Video Preview from Screenshot
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 7),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ExerciseVideoPreviewThumbnail(
                  exercise: Exercise(
                    id: isBench ? '00000000-0000-0000-0000-000000000002' : '00000000-0000-0000-0000-000000000001',
                    name: title,
                    targetMuscle: muscle,
                    equipment: equipment,
                    difficulty: isBench ? 'intermediate' : 'beginner',
                    videoUrl: isBench
                        ? 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4'
                        : 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
                    sideVideoUrl: 'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
                  ),
                  height: 68,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(6),
                  autoPlay: true,
                ),
              ),
            ),
          ),

          // Card Footer: Sets, Reps, Rest, RPE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Sets:', style: GoogleFonts.inter(fontSize: 6.2, color: Colors.white60)),
                    const SizedBox(width: 2),
                    Text(sets, style: GoogleFonts.jetBrainsMono(fontSize: 6.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 5),
                    Text('Reps:', style: GoogleFonts.inter(fontSize: 6.2, color: Colors.white60)),
                    const SizedBox(width: 2),
                    Text(reps, style: GoogleFonts.jetBrainsMono(fontSize: 6.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 5),
                    Text('Rest:', style: GoogleFonts.inter(fontSize: 6.2, color: Colors.white60)),
                    const SizedBox(width: 2),
                    Text(rest, style: GoogleFonts.jetBrainsMono(fontSize: 6.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                Text(rpe, style: GoogleFonts.jetBrainsMono(fontSize: 6.5, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
