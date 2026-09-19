import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../domain/nav_destination_item.dart';
import 'role_switcher_sheet.dart';
import 'sidebar_nav_tile.dart';

class AdaptiveSidebar extends StatelessWidget {
  final UserProfile profile;
  final UserRole activeRole;
  final List<NavDestinationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onSignOut;

  const AdaptiveSidebar({
    super.key,
    required this.profile,
    required this.activeRole,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onRoleChanged,
    required this.onSignOut,
  });

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
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.fitness_center_rounded, color: accent, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GYMCONNECT',
                    style: GoogleFonts.oswald(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () => _openRoleSwitcher(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(activeRole.icon, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activeRole.displayName,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    Icon(Icons.unfold_more_rounded, size: 16, color: accent),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                return SidebarNavTile(
                  item: items[index],
                  isSelected: selectedIndex == index,
                  accentColor: accent,
                  onTap: () => onItemSelected(index),
                );
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                title: Text(
                  'Sign Out',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                onTap: onSignOut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
