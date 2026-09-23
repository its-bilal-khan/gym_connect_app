import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../../notifications/presentation/widgets/gym_notifications_sheet.dart';
import 'role_switcher_sheet.dart';

class UserAccountHubSheet extends ConsumerWidget {
  final UserProfile profile;
  final UserRole activeRole;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onSignOut;

  const UserAccountHubSheet({
    super.key,
    required this.profile,
    required this.activeRole,
    required this.onRoleChanged,
    required this.onSignOut,
  });

  static Future<void> show(
    BuildContext context, {
    required UserProfile profile,
    required UserRole activeRole,
    required ValueChanged<UserRole> onRoleChanged,
    required VoidCallback onSignOut,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserAccountHubSheet(
        profile: profile,
        activeRole: activeRole,
        onRoleChanged: onRoleChanged,
        onSignOut: onSignOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    final initials = profile.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accent.withValues(alpha: 0.2),
                child: Text(initials.isEmpty ? 'U' : initials, style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName, style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('${profile.email} • ${profile.tenantName}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
            leading: Stack(
              alignment: Alignment.topRight,
              children: [
                const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
                if (unreadCount > 0)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  ),
              ],
            ),
            title: Text('Activity & Notifications', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            subtitle: Text(unreadCount > 0 ? '$unreadCount pending alerts' : 'No unread notifications', style: GoogleFonts.inter(fontSize: 11, color: unreadCount > 0 ? accent : AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            onTap: () {
              Navigator.pop(context);
              GymNotificationsSheet.show(context);
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
            leading: Icon(activeRole.icon, color: accent, size: 24),
            title: Text('Switch Active Role', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            subtitle: Text('Currently active as ${activeRole.badgeLabel}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.swap_horiz_rounded, color: AppColors.textSecondary),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => RoleSwitcherSheet(activeRole: activeRole, onSelectRole: onRoleChanged),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onSignOut();
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            label: Text('SIGN OUT OF SESSION', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
