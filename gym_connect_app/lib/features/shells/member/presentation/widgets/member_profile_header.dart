import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../membership/data/membership_repository.dart';
import 'pay_dues_sheet.dart';

class MemberProfileHeader extends ConsumerWidget {
  const MemberProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final subAsync = ref.watch(memberSubscriptionProvider);
    final sub = subAsync.asData?.value;
    final planTitle = sub?.planName ?? 'Annual VIP Access';
    final statusText = sub != null ? 'Active through ${sub.endDate}' : 'Active Membership';

    return Container(
      padding: const EdgeInsets.all(16),
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
              children: [
                Text('MEMBERSHIP STATUS',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
                const SizedBox(height: 4),
                Text(planTitle,
                    style: GoogleFonts.oswald(
                        fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(statusText,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
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
            child: Text('RENEW',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
