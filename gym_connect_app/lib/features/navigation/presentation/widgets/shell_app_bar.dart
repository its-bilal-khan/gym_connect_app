import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/widgets/theme_color_switcher_dialog.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../../notifications/presentation/widgets/gym_notifications_sheet.dart';
import '../../../store/presentation/in_gym_store_screen.dart';
import 'role_switcher_sheet.dart';
import 'user_account_hub_sheet.dart';

class ShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final UserProfile profile;
  final UserRole activeRole;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onSignOut;

  const ShellAppBar({
    super.key,
    required this.profile,
    required this.activeRole,
    required this.onRoleChanged,
    required this.onSignOut,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  void _openRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => RoleSwitcherSheet(activeRole: activeRole, onSelectRole: onRoleChanged),
    );
  }

  void _openAccountHub(BuildContext context) {
    UserAccountHubSheet.show(
      context,
      profile: profile,
      activeRole: activeRole,
      onRoleChanged: onRoleChanged,
      onSignOut: onSignOut,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final unread = ref.watch(unreadNotificationsCountProvider);
    final initials = profile.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 4)]),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          profile.tenantName.toUpperCase(),
                          style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${profile.fullName} • Active', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            _buildStoreButton(context, accent),
            const SizedBox(width: 5),
            if (MediaQuery.sizeOf(context).width >= 500) ...[
              _buildThemePaletteButton(context, accent),
              const SizedBox(width: 5),
            ],
            _buildNotificationBell(context, accent, unread),
            const SizedBox(width: 5),
            _buildRoleBadge(context, accent),
            const SizedBox(width: 5),
            _buildProfileAvatarPill(context, accent, initials, unread),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePaletteButton(BuildContext context, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        icon: Icon(Icons.palette_outlined, color: accent, size: 18),
        tooltip: 'Brand Theme Color Palette',
        splashRadius: 18,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        onPressed: () => ThemeColorSwitcherDialog.show(context),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context, Color accent, int unread) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: unread > 0 ? accent.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(
              unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
              color: unread > 0 ? accent : AppColors.textSecondary,
              size: 18,
            ),
            tooltip: 'Notifications & Alerts',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () => GymNotificationsSheet.show(context),
          ),
          if (unread > 0)
            Positioned(
              right: 3,
              top: 3,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 13, minHeight: 13),
                child: Text(
                  '$unread',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreButton(BuildContext context, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        icon: Icon(Icons.shopping_bag_outlined, color: accent, size: 18),
        tooltip: 'Pro Shop & Store',
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
        onPressed: () => InGymStoreScreen.open(context),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, Color accent) {
    return InkWell(
      onTap: () => _openRoleSwitcher(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(activeRole.icon, size: 12, color: accent),
            const SizedBox(width: 4),
            Text(activeRole.badgeLabel, style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.7, color: accent)),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: accent),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatarPill(BuildContext context, Color accent, String initials, int unread) {
    return InkWell(
      onTap: () => _openAccountHub(context),
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.background,
            child: CircleAvatar(
              radius: 15,
              backgroundColor: accent.withValues(alpha: 0.2),
              child: Text(initials.isEmpty ? 'U' : initials, style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: accent)),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}
