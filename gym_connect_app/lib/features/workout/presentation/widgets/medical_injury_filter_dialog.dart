import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/fitness_profile_provider.dart';
import 'injury_checkbox_matrix.dart';

class MedicalInjuryFilterDialog extends ConsumerStatefulWidget {
  const MedicalInjuryFilterDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const MedicalInjuryFilterDialog(),
    );
  }

  @override
  ConsumerState<MedicalInjuryFilterDialog> createState() => _MedicalInjuryFilterDialogState();
}

class _MedicalInjuryFilterDialogState extends ConsumerState<MedicalInjuryFilterDialog> {
  double _heightCm = 175.0;
  final Set<String> _selectedInjuries = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(fitnessProfileProvider).asData?.value;
    if (profile?.heightCm != null) _heightCm = profile!.heightCm!;
    if (profile?.medicalInjuries != null) {
      _selectedInjuries.addAll(profile!.medicalInjuries);
    }
  }

  Future<void> _claimAndSave() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    await ref.read(fitnessProfileProvider.notifier).completeProfileQuest(
          heightCm: _heightCm,
          injuries: _selectedInjuries.toList(),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Quest Completed! +50 XP Awarded & Injury Safe Split Active! 🛡️'),
        backgroundColor: AppColors.surface,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('+50 BONUS XP', style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                ),
                const SizedBox(width: 8),
                Text('HEALTH & INJURY SCREENING', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            Text('AI will automatically omit unsafe exercises with zero penalty.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            _heightStepper(accent),
            const SizedBox(height: 14),
            Text('MEDICAL INJURIES (SELECT ALL THAT APPLY)', style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Expanded(
              child: InjuryCheckboxMatrix(
                selectedInjuries: _selectedInjuries,
                onToggle: (key) => setState(() {
                  if (_selectedInjuries.contains(key)) {
                    _selectedInjuries.remove(key);
                  } else {
                    _selectedInjuries.add(key);
                  }
                }),
                accent: accent,
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              text: _isSaving ? 'SAVING PROTOCOL...' : 'SAVE & CLAIM 50 BONUS PTS',
              icon: Icons.shield_rounded,
              onPressed: _isSaving ? null : _claimAndSave,
            ),
          ],
        ),
      ),
    );
  }

  Widget _heightStepper(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('YOUR HEIGHT', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, size: 22), onPressed: () => setState(() => _heightCm = (_heightCm - 1).clamp(120, 230)), color: AppColors.textSecondary),
              Text('${_heightCm.round()} CM', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
              IconButton(icon: const Icon(Icons.add_circle_outline_rounded, size: 22), onPressed: () => setState(() => _heightCm = (_heightCm + 1).clamp(120, 230)), color: accent),
            ],
          ),
        ],
      ),
    );
  }
}
