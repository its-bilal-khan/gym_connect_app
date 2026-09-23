import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../membership/data/membership_repository.dart';
import '../../../../workout/presentation/widgets/calorie_calculator_sheet.dart';
import '../../../../workout/presentation/widgets/goal_onboarding_dialog.dart';
import '../../../../workout/presentation/widgets/gym_leaderboard_sheet.dart';
import 'gym_review_dialog.dart';
import '../../../../store/presentation/in_gym_store_screen.dart';
import '../../../../notifications/data/notification_repository.dart';
import '../../../../notifications/presentation/widgets/gym_notifications_sheet.dart';
import 'pay_dues_sheet.dart';

class MemberProfileTab extends ConsumerWidget {
  const MemberProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final subAsync = ref.watch(memberSubscriptionProvider);
    final sub = subAsync.asData?.value;
    final planTitle = sub?.planName ?? 'Annual VIP Access';
    final statusText = sub != null ? 'Active through ${sub.endDate}' : 'Active Membership';

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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MEMBERSHIP STATUS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
                        const SizedBox(height: 4),
                        Text(planTitle, style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text(statusText, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => PayDuesSheet.show(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('RENEW', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final unread = ref.watch(unreadNotificationsCountProvider);
                return ListTile(
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: unread > 0 ? accent.withValues(alpha: 0.6) : AppColors.border)),
                  leading: Icon(Icons.notifications_active_rounded, color: unread > 0 ? accent : Colors.amber),
                  title: Text('Notifications & Alerts Center', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text(unread > 0 ? '$unread unread alerts (dues, deals & updates)' : 'All gym updates & announcements', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  trailing: unread > 0
                      ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)), child: Text('$unread NEW', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)))
                      : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => GymNotificationsSheet.show(context),
                );
              },
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
              leading: const Icon(Icons.payments_rounded, color: Colors.lightGreenAccent),
              title: Text('Pay Dues & Renewals', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text('JazzCash, EasyPaisa, Card & Instant Gate Unlock', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: () => PayDuesSheet.show(context),
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
              leading: const Icon(Icons.storefront_rounded, color: Colors.tealAccent),
              title: Text('In-Gym Supplements & Shakes', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text('Protein shakes, bars & gear with counter pickup code', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: () => InGymStoreScreen.open(context),
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
              leading: const Icon(Icons.rate_review_rounded, color: Colors.purpleAccent),
              title: Text('Rate & Review Your Gym', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text('Verified member rating, equipment and hygiene review', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: () => GymReviewDialog.show(context),
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
