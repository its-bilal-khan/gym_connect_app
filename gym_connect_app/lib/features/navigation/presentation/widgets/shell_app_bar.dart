import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/domain/models/user_role.dart';
import 'role_switcher_sheet.dart';

class ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(68);

  void _openRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => RoleSwitcherSheet(
        activeRole: activeRole,
        onSelectRole: onRoleChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Icon(Icons.fitness_center_rounded, color: accent, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          profile.tenantName.toUpperCase(),
                          style: GoogleFonts.oswald(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${profile.fullName} • Active Session',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _openRoleSwitcher(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(activeRole.icon, size: 14, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      activeRole.badgeLabel,
                      style: GoogleFonts.oswald(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: accent),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              tooltip: 'Sign Out',
              onPressed: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}
