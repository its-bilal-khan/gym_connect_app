import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/models/user_profile.dart';
import '../../auth/domain/models/user_role.dart';
import '../../auth/presentation/providers/auth_notifier.dart';
import '../../auth/presentation/providers/auth_state.dart';
import '../../shells/owner/presentation/owner_shell_view.dart';
import '../../shells/staff/presentation/staff_shell_view.dart';
import '../../shells/member/presentation/member_shell_view.dart';
import '../../shells/public/presentation/public_shell_view.dart';
import 'role_navigation_config.dart';
import 'widgets/adaptive_sidebar.dart';
import 'widgets/glass_bottom_nav.dart';
import 'widgets/shell_app_bar.dart';
import '../../../core/theme/app_theme.dart';

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
  void didUpdateWidget(covariant AdaptiveRoleShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeRole != widget.activeRole) {
      setState(() {
        _localRole = widget.activeRole;
        _selectedIndex = 0;
      });
    }
  }

  void _onRoleChanged(UserRole newRole) {
    setState(() {
      _localRole = newRole;
      _selectedIndex = 0;
    });
    ref.read(authNotifierProvider.notifier).switchActiveRole(newRole);
  }

  void _onSignOut() {
    ref.read(authNotifierProvider.notifier).signOut();
  }

  Widget _buildRoleView(UserRole role, UserProfile profile) {
    switch (role) {
      case UserRole.owner:
        return OwnerShellView(profile: profile, selectedIndex: _selectedIndex);
      case UserRole.staff:
        return StaffShellView(profile: profile, selectedIndex: _selectedIndex);
      case UserRole.member:
        return MemberShellView(profile: profile, selectedIndex: _selectedIndex);
      case UserRole.publicUser:
        return PublicShellView(profile: profile, selectedIndex: _selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final effectiveRole = (authState is AuthAuthenticated)
        ? authState.activeRole
        : (_localRole ?? widget.activeRole);
    final effectiveProfile =
        (authState is AuthAuthenticated) ? authState.profile : widget.profile;

    final tabs = RoleNavigationConfig.getTabsForRole(effectiveRole);
    if (_selectedIndex >= tabs.length) {
      _selectedIndex = 0;
    }

    final activeView = _buildRoleView(effectiveRole, effectiveProfile);
    final theme = AppTheme.darkTheme(tenantAccentColor: effectiveProfile.tenantPrimaryColor);

    return Theme(
      data: theme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          if (isDesktop) {
            return Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    AdaptiveSidebar(
                      profile: effectiveProfile,
                      activeRole: effectiveRole,
                      items: tabs,
                      selectedIndex: _selectedIndex,
                      onItemSelected: (i) => setState(() => _selectedIndex = i),
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
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
            ),
          );
        },
      ),
    );
  }
}
