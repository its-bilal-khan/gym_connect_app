import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../workout/presentation/widgets/calorie_calculator_sheet.dart';
import '../../../../workout/presentation/widgets/goal_onboarding_dialog.dart';
import '../../../../workout/presentation/widgets/gym_leaderboard_sheet.dart';

class MemberProfileTab extends StatelessWidget {
  const MemberProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('MEMBER PROFILE & SETTINGS', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MEMBERSHIP STATUS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
                  const SizedBox(height: 4),
                  Text('Annual VIP Access', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text('Active through Dec 31, 2026 • Auto-Gate Unlock', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
              leading: const Icon(Icons.accessibility_new_rounded, color: Colors.cyanAccent),
              title: Text('Body Type & AI Training Goal', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text('Tune AI workouts to your genetics', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: () => GoalOnboardingDialog.show(context),
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
              leading: const Icon(Icons.calculate_rounded, color: Colors.deepOrangeAccent),
              title: Text('BMI & Calorie Calculator', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text('Calculate TDEE, BMR, and daily macro targets', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: () => CalorieCalculatorSheet.show(context),
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
              leading: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
              title: Text('Gym Consistency Leaderboard', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text('View rankings, streaks & points', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: () => GymLeaderboardSheet.show(context),
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
