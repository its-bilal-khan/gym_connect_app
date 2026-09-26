import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/domain/models/user_profile.dart';
import '../../auth/domain/models/user_role.dart';
import '../../auth/presentation/providers/auth_notifier.dart';
import '../../auth/presentation/providers/auth_state.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/presentation/widgets/gym_notifications_sheet.dart';
import '../../shells/owner/presentation/owner_shell_view.dart';
import '../../shells/owner/presentation/desktop/desktop_owner_portal_view.dart';
import '../../shells/staff/presentation/staff_shell_view.dart';
import '../../staff/presentation/desktop/desktop_staff_pos_workstation_view.dart';
import '../../shells/member/presentation/member_shell_view.dart';
import '../../shells/member/presentation/desktop/desktop_member_portal_view.dart';
import '../../shells/public/presentation/public_shell_view.dart';
import '../../store/presentation/screens/order_tracking_screen.dart';
import '../../super_admin/presentation/desktop/desktop_super_admin_workstation_view.dart';
import '../../super_admin/presentation/super_admin_shell_view.dart';
import '../../calculators/presentation/screens/calculators_hub_screen.dart';
import 'role_navigation_config.dart';
import 'widgets/adaptive_sidebar.dart';
import 'widgets/glass_bottom_nav.dart';
import 'widgets/shell_app_bar.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_provider.dart';

class AdaptiveRoleShell extends ConsumerStatefulWidget {
  final UserProfile profile;
  final UserRole activeRole;

  const AdaptiveRoleShell({
    super.key,
    required this.profile,
    required this.activeRole,
  });

  @override
  ConsumerState<AdaptiveRoleShell> createState() => _AdaptiveRoleShellState();
}

class _AdaptiveRoleShellState extends ConsumerState<AdaptiveRoleShell> {
  int _selectedIndex = 0;
  UserRole? _localRole;

  @override
  void initState() {
    super.initState();
    _loadSavedNavIndex();
  }

  Future<void> _loadSavedNavIndex() async {
    final storage = ref.read(secureStorageProvider);
    final saved = await storage.getActiveNavIndex();
    if (saved != null && mounted) {
      final isDesktop = MediaQuery.sizeOf(context).width >= 800;
      final tabs = RoleNavigationConfig.getTabsForRole(
        _localRole ?? widget.activeRole,
        isDesktop: isDesktop,
      );
      if (saved >= 0 && saved < tabs.length) {
        setState(() => _selectedIndex = saved);
      }
    }
  }

  void _onNavItemSelected(int index) {
    setState(() => _selectedIndex = index);
    ref.read(secureStorageProvider).saveActiveNavIndex(index);
  }

  @override
  void didUpdateWidget(covariant AdaptiveRoleShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeRole != widget.activeRole) {
      setState(() {
        _localRole = widget.activeRole;
        _selectedIndex = 0;
      });
      ref.read(secureStorageProvider).saveActiveNavIndex(0);
    }
  }

  void _onRoleChanged(UserRole newRole) {
    setState(() {
      _localRole = newRole;
      _selectedIndex = 0;
    });
    ref.read(secureStorageProvider).saveActiveNavIndex(0);
    ref.read(authNotifierProvider.notifier).switchActiveRole(newRole);
    ref.read(gymNotificationsProvider.notifier).loadNotifications();
  }

  void _onSignOut() {
    ref.read(authNotifierProvider.notifier).signOut();
  }

  Widget _buildRoleView(
    UserRole role,
    UserProfile profile, {
    required bool isDesktop,
    required int selectedIndex,
  }) {
    if (isDesktop) {
      final tabs = RoleNavigationConfig.getTabsForRole(role, isDesktop: true);
      final currentTabId = (selectedIndex >= 0 && selectedIndex < tabs.length)
          ? tabs[selectedIndex].id
          : '';

      if (currentTabId == 'tools') {
        return const CalculatorsHubScreen();
      }

      switch (role) {
        case UserRole.superAdmin:
          return DesktopSuperAdminWorkstationView(
            profile: profile,
            initialTabIndex: selectedIndex,
          );
        case UserRole.staff:
          return DesktopStaffPosWorkstationView(initialTabIndex: selectedIndex);
        case UserRole.owner:
          return selectedIndex == 0
              ? DesktopOwnerPortalView(profile: profile)
              : OwnerShellView(profile: profile, selectedIndex: selectedIndex);
        case UserRole.member:
        case UserRole.publicUser:
          return DesktopMemberPortalView(profile: profile);
      }
    }

    switch (role) {
      case UserRole.superAdmin:
        return SuperAdminShellView(profile: profile, selectedIndex: selectedIndex);
      case UserRole.owner:
        return OwnerShellView(profile: profile, selectedIndex: selectedIndex);
      case UserRole.staff:
        return StaffShellView(profile: profile, selectedIndex: selectedIndex);
      case UserRole.member:
        return MemberShellView(profile: profile, selectedIndex: selectedIndex);
      case UserRole.publicUser:
        return PublicShellView(profile: profile, selectedIndex: selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final themeState = ref.watch(appThemeNotifierProvider);

    final effectiveRole = (authState is AuthAuthenticated)
        ? authState.activeRole
        : (_localRole ?? widget.activeRole);
    final effectiveProfile =
        (authState is AuthAuthenticated) ? authState.profile : widget.profile;

    ref.listen<AppAuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        ref.read(appThemeNotifierProvider.notifier).syncWithProfile(next.profile);
      }
    });

    final theme = AppTheme.darkTheme(tenantAccentColor: themeState.currentPreset.color);

    ref.listen<GymNotification?>(liveNotificationToastProvider, (previous, next) {
      if (next != null) {
        final newest = next;
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.hideCurrentSnackBar();
        final isDesktopScreen = MediaQuery.of(context).size.width >= 800;
        messenger?.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            width: isDesktopScreen ? 440 : null,
            margin: isDesktopScreen ? null : const EdgeInsets.fromLTRB(16, 0, 16, 80),
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                Icon(
                  newest.type == NotificationType.storeOrder
                      ? Icons.shopping_bag_rounded
                      : (newest.type == NotificationType.gatePass ? Icons.bolt_rounded : Icons.notifications_active_rounded),
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(newest.title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(newest.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: theme.colorScheme.primary,
              onPressed: () {
                if (newest.type == NotificationType.storeOrder) {
                  OrderTrackingScreen.open(context, initialOrderId: newest.actionPayload);
                } else {
                  GymNotificationsSheet.show(context);
                }
              },
            ),
          ),
        );
      }
    });

    return Theme(
      data: theme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;
          final tabs = RoleNavigationConfig.getTabsForRole(effectiveRole, isDesktop: isDesktop);
          final safeIndex = _selectedIndex >= tabs.length ? 0 : _selectedIndex;
          final activeView = _buildRoleView(
            effectiveRole,
            effectiveProfile,
            isDesktop: isDesktop,
            selectedIndex: safeIndex,
          );

          if (isDesktop) {
            return Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    AdaptiveSidebar(
                      profile: effectiveProfile,
                      activeRole: effectiveRole,
                      items: tabs,
                      selectedIndex: safeIndex,
                      onItemSelected: _onNavItemSelected,
                      onRoleChanged: _onRoleChanged,
                      onSignOut: _onSignOut,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          ShellAppBar(
                            profile: effectiveProfile,
                            activeRole: effectiveRole,
                            onRoleChanged: _onRoleChanged,
                            onSignOut: _onSignOut,
                          ),
                          Expanded(child: activeView),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            extendBody: true,
            appBar: ShellAppBar(
              profile: effectiveProfile,
              activeRole: effectiveRole,
              onRoleChanged: _onRoleChanged,
              onSignOut: _onSignOut,
            ),
            body: SafeArea(bottom: false, child: activeView),
            bottomNavigationBar: GlassBottomNav(
              items: tabs,
              currentIndex: safeIndex,
              onTap: _onNavItemSelected,
            ),
          );
        },
      ),
    );
  }
}
