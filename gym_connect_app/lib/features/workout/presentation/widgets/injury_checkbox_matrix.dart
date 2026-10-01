import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class InjuryCheckboxMatrix extends StatelessWidget {
  final Set<String> selectedInjuries;
  final ValueChanged<String> onToggle;
  final Color accent;

  static const Map<String, String> injuryOptions = {
    'lower_back': 'Lower Back Pain / Disc Strain',
    'knee_pain': 'Knee Joint / Meniscus Tenderness',
    'shoulder_pain': 'Shoulder Impingement / Rotator Cuff',
    'wrist_pain': 'Wrist Strain / Carpal Sensitivity',
    'neck_pain': 'Cervical / Neck Stiffness',
  };

  const InjuryCheckboxMatrix({
    super.key,
    required this.selectedInjuries,
    required this.onToggle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: injuryOptions.entries.map((entry) {
        final isChecked = selectedInjuries.contains(entry.key);
        return CheckboxListTile(
          value: isChecked,
          activeColor: accent,
          checkColor: Colors.black,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(entry.value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
          onChanged: (_) => onToggle(entry.key),
        );
      }).toList(),
    );
  }
}
