import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../notifications/data/notification_repository.dart';
import '../../../../notifications/presentation/widgets/gym_notifications_sheet.dart';
import 'member_profile_header.dart';
import 'member_profile_modules_list.dart';

class MemberProfileTab extends ConsumerWidget {
  const MemberProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Text(
              'MEMBER PROFILE & SETTINGS',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            const MemberProfileHeader(),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, _) {
                final unread = ref.watch(unreadNotificationsCountProvider);
                return ListTile(
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: unread > 0 ? accent.withValues(alpha: 0.6) : AppColors.border,
                    ),
                  ),
                  leading: Icon(
                    Icons.notifications_active_rounded,
                    color: unread > 0 ? accent : Colors.amber,
                  ),
                  title: Text(
                    'Notifications & Alerts Center',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    unread > 0
                        ? '$unread unread alerts (dues, deals & updates)'
                        : 'All gym updates & announcements',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: unread > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unread NEW',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        )
                      : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => GymNotificationsSheet.show(context),
                );
              },
            ),
            const SizedBox(height: 10),
            const MemberProfileModulesList(),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
