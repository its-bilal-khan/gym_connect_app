import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../super_admin/data/system_feature_toggle_repository.dart';
import '../providers/fitness_profile_provider.dart';
import 'rapid_goal_selector.dart';
import 'trainer_consultation_safety_dialog.dart';

class RapidOnboardingSheet extends ConsumerStatefulWidget {
  const RapidOnboardingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const RapidOnboardingSheet(),
    );
  }

  @override
  ConsumerState<RapidOnboardingSheet> createState() => _RapidOnboardingSheetState();
}

class _RapidOnboardingSheetState extends ConsumerState<RapidOnboardingSheet> {
  double _weight = 75.0;
  String _selectedGoal = 'v_shape';
  int _age = 25;
  bool _isSubmitting = false;

  Future<void> _submit(int maxAge) async {
    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);

    await ref.read(fitnessProfileProvider.notifier).saveRapidOnboarding(
          weightKg: _weight,
          goal: _selectedGoal,
          age: _age,
          maxAllowedAiAge: maxAge,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      final trackText = _weight >= 90.0 ? "Track B (Joint-Friendly)" : "Track A (Dynamic)";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Protocol Activated: $trackText!'),
        backgroundColor: AppColors.surface,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final maxAllowedAiAge = ref.watch(maxAllowedAiAgeProvider);
    final isAgeBlocked = _age >= maxAllowedAiAge;
    final isTrackB = _weight >= 90.0;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Text('RAPID 30-SECOND SETUP', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('3 quick questions to silently route your ideal workout track.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            _buildRoutingBadge(isAgeBlocked, isTrackB, maxAllowedAiAge, accent),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  _numberRow('CURRENT WEIGHT', '$_weight KG', () => setState(() => _weight = (_weight - 1).clamp(40, 200)), () => setState(() => _weight = (_weight + 1).clamp(40, 200)), accent),
                  const SizedBox(height: 14),
                  RapidGoalSelector(selectedGoal: _selectedGoal, onSelect: (g) => setState(() => _selectedGoal = g), accent: accent),
                  const SizedBox(height: 14),
                  _numberRow('YOUR AGE', '$_age YRS', () => setState(() => _age = (_age - 1).clamp(14, 90)), () => setState(() => _age = (_age + 1).clamp(14, 90)), accent),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: isAgeBlocked ? 'CONSULT PHYSICAL TRAINER' : (_isSubmitting ? 'CALIBRATING...' : '1-TAP LAUNCH PROTOCOL'),
              icon: isAgeBlocked ? Icons.health_and_safety_rounded : Icons.bolt_rounded,
              onPressed: isAgeBlocked
                  ? () => TrainerConsultationSafetyDialog.show(context, maxAllowedAiAge: maxAllowedAiAge)
                  : (_isSubmitting ? null : () => _submit(maxAllowedAiAge)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutingBadge(bool isAgeBlocked, bool isTrackB, int maxAge, Color accent) {
    final color = isAgeBlocked ? Colors.redAccent : (isTrackB ? Colors.amber : accent);
    final text = isAgeBlocked
        ? '⚠️ SAFETY NOTICE: In-person certified trainer evaluation required for age $maxAge+.'
        : (isTrackB ? 'ROUTING: TRACK B (Low-Impact Beginner Retention)' : 'ROUTING: TRACK A (Dynamic Progressive Overload)');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: color)),
      child: Row(
        children: [
          Icon(isAgeBlocked ? Icons.health_and_safety_rounded : (isTrackB ? Icons.shield_rounded : Icons.flash_on_rounded), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    );
  }

  Widget _numberRow(String label, String value, VoidCallback onDec, VoidCallback onInc, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, size: 22), onPressed: onDec, color: AppColors.textSecondary),
              Text(value, style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
              IconButton(icon: const Icon(Icons.add_circle_outline_rounded, size: 22), onPressed: onInc, color: accent),
            ],
          ),
        ],
      ),
    );
  }
}
