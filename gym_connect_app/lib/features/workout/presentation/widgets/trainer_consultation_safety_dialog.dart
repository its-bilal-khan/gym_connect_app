import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';

class TrainerConsultationSafetyDialog extends StatelessWidget {
  final int maxAllowedAiAge;

  const TrainerConsultationSafetyDialog({
    super.key,
    this.maxAllowedAiAge = 55,
  });

  static Future<void> show(BuildContext context, {int maxAllowedAiAge = 55}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => TrainerConsultationSafetyDialog(maxAllowedAiAge: maxAllowedAiAge),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.amber, size: 32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'IN-PERSON TRAINER EVALUATION REQUIRED',
              textAlign: TextAlign.center,
              style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Facility Liability & Cardiovascular Safety Protection',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'For your safety, joint preservation, and facility liability compliance, members aged $maxAllowedAiAge and above require direct in-person evaluation by a physical gym trainer.\n\n'
                'Automated AI workouts are locked for this age category to avoid unmonitored cardiovascular strain or joint overload.\n\n'
                'Please visit our front reception or speak with one of our certified on-floor personal trainers. They will design a medically safe, supervised program tailored for you.',
                style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'I UNDERSTAND & WILL CONSULT TRAINER',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
