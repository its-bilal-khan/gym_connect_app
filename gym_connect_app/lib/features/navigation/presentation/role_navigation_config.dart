import 'package:flutter/material.dart';
import '../../auth/domain/models/user_role.dart';
import '../domain/nav_destination_item.dart';

abstract final class RoleNavigationConfig {
  static List<NavDestinationItem> getTabsForRole(UserRole role, {bool isDesktop = false}) {
    switch (role) {
      case UserRole.superAdmin:
        if (isDesktop) {
          return const [
            NavDestinationItem(
              id: 'tenants',
              label: 'Gym Tenants',
              icon: Icons.apartment_outlined,
              selectedIcon: Icons.apartment_rounded,
            ),
            NavDestinationItem(
              id: 'onboard',
              label: 'Onboard Gym',
              icon: Icons.add_business_outlined,
              selectedIcon: Icons.add_business_rounded,
            ),
            NavDestinationItem(
              id: 'exercises',
              label: 'Exercise Studio',
              icon: Icons.video_collection_outlined,
              selectedIcon: Icons.video_collection_rounded,
            ),
            NavDestinationItem(
              id: 'analytics',
              label: 'SaaS Tiers & ARR',
              icon: Icons.insights_outlined,
              selectedIcon: Icons.insights_rounded,
            ),
            NavDestinationItem(
              id: 'system',
              label: 'Audit & God Mode',
              icon: Icons.security_outlined,
              selectedIcon: Icons.security_rounded,
            ),
            NavDestinationItem(
              id: 'tools',
              label: 'Fitness Tools',
              icon: Icons.calculate_outlined,
              selectedIcon: Icons.calculate_rounded,
            ),
          ];
        }
        return const [
          NavDestinationItem(
            id: 'tenants',
            label: 'Tenants',
            icon: Icons.apartment_outlined,
            selectedIcon: Icons.apartment_rounded,
          ),
          NavDestinationItem(
            id: 'onboard',
            label: 'Onboard',
            icon: Icons.add_business_outlined,
            selectedIcon: Icons.add_business_rounded,
          ),
          NavDestinationItem(
            id: 'analytics',
            label: 'SaaS',
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights_rounded,
          ),
          NavDestinationItem(
            id: 'system',
            label: 'Audit',
            icon: Icons.security_outlined,
            selectedIcon: Icons.security_rounded,
          ),
          NavDestinationItem(
            id: 'tools',
            label: 'Tools',
            icon: Icons.calculate_outlined,
            selectedIcon: Icons.calculate_rounded,
          ),
        ];

      case UserRole.owner:
        if (isDesktop) {
          return const [
            NavDestinationItem(
              id: 'overview',
              label: 'Executive Overview',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard_rounded,
            ),
            NavDestinationItem(
              id: 'pos_staff',
              label: 'Staff & Audit',
              icon: Icons.shield_outlined,
              selectedIcon: Icons.shield_rounded,
            ),
            NavDestinationItem(
              id: 'live_ops',
              label: 'Operations & IoT',
              icon: Icons.videocam_outlined,
              selectedIcon: Icons.videocam_rounded,
            ),
            NavDestinationItem(
              id: 'tools',
              label: 'Fitness Tools',
              icon: Icons.calculate_outlined,
              selectedIcon: Icons.calculate_rounded,
            ),
            NavDestinationItem(
              id: 'settings',
              label: 'Settings',
              icon: Icons.tune_rounded,
              selectedIcon: Icons.settings_rounded,
            ),
          ];
        }
        return const [
          NavDestinationItem(
            id: 'overview',
            label: 'Overview',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
          ),
          NavDestinationItem(
            id: 'pos_staff',
            label: 'Staff & POS',
            icon: Icons.point_of_sale_outlined,
            selectedIcon: Icons.point_of_sale_rounded,
          ),
          NavDestinationItem(
            id: 'live_ops',
            label: 'Operations',
            icon: Icons.videocam_outlined,
            selectedIcon: Icons.videocam_rounded,
          ),
          NavDestinationItem(
            id: 'tools',
            label: 'Tools',
            icon: Icons.calculate_outlined,
            selectedIcon: Icons.calculate_rounded,
          ),
          NavDestinationItem(
            id: 'settings',
            label: 'Settings',
            icon: Icons.tune_rounded,
            selectedIcon: Icons.settings_rounded,
          ),
        ];

      case UserRole.staff:
        if (isDesktop) {
          return const [
            NavDestinationItem(
              id: 'pos_register',
              label: 'POS Register Desk',
              icon: Icons.point_of_sale_outlined,
              selectedIcon: Icons.point_of_sale_rounded,
            ),
            NavDestinationItem(
              id: 'reception',
              label: 'Gate Check-ins',
              icon: Icons.door_sliding_outlined,
              selectedIcon: Icons.door_sliding_rounded,
            ),
            NavDestinationItem(
              id: 'members',
              label: 'Member Directory',
              icon: Icons.people_outline_rounded,
              selectedIcon: Icons.people_alt_rounded,
            ),
            NavDestinationItem(
              id: 'shift',
              label: 'Shift Tally',
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long_rounded,
            ),
            NavDestinationItem(
              id: 'tools',
              label: 'Fitness Tools',
              icon: Icons.calculate_outlined,
              selectedIcon: Icons.calculate_rounded,
            ),
          ];
        }
        return const [
          NavDestinationItem(
            id: 'reception',
            label: 'Front Desk',
            icon: Icons.qr_code_scanner_rounded,
            selectedIcon: Icons.qr_code_scanner_rounded,
          ),
          NavDestinationItem(
            id: 'members',
            label: 'Members',
            icon: Icons.people_outline_rounded,
            selectedIcon: Icons.people_alt_rounded,
          ),
          NavDestinationItem(
            id: 'pos',
            label: 'POS & Khata',
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
          ),
          NavDestinationItem(
            id: 'shift',
            label: 'Shift Tally',
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet_rounded,
          ),
          NavDestinationItem(
            id: 'tools',
            label: 'Tools',
            icon: Icons.calculate_outlined,
            selectedIcon: Icons.calculate_rounded,
          ),
        ];

      case UserRole.member:
        if (isDesktop) {
          return const [
            NavDestinationItem(
              id: 'desktop_account',
              label: 'Member Account',
              icon: Icons.account_circle_outlined,
              selectedIcon: Icons.account_circle_rounded,
            ),
            NavDestinationItem(
              id: 'tools',
              label: 'Fitness Tools',
              icon: Icons.calculate_outlined,
              selectedIcon: Icons.calculate_rounded,
            ),
          ];
        }
        return const [
          NavDestinationItem(
            id: 'daily_action',
            label: 'Today',
            icon: Icons.bolt_outlined,
            selectedIcon: Icons.bolt_rounded,
          ),
          NavDestinationItem(
            id: 'workout_hub',
            label: 'Workouts',
            icon: Icons.fitness_center_outlined,
            selectedIcon: Icons.fitness_center_rounded,
          ),
          NavDestinationItem(
            id: 'tools',
            label: 'Tools',
            icon: Icons.calculate_outlined,
            selectedIcon: Icons.calculate_rounded,
          ),
          NavDestinationItem(
            id: 'pass',
            label: 'Gate Pass',
            icon: Icons.badge_outlined,
            selectedIcon: Icons.badge_rounded,
          ),
          NavDestinationItem(
            id: 'store_profile',
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];

      case UserRole.publicUser:
        if (isDesktop) {
          return const [
            NavDestinationItem(
              id: 'desktop_guest',
              label: 'Guest Portal',
              icon: Icons.explore_outlined,
              selectedIcon: Icons.explore_rounded,
            ),
            NavDestinationItem(
              id: 'tools',
              label: 'Fitness Tools',
              icon: Icons.calculate_outlined,
              selectedIcon: Icons.calculate_rounded,
            ),
          ];
        }
        return const [
          NavDestinationItem(
            id: 'explore',
            label: 'Discover',
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore_rounded,
          ),
          NavDestinationItem(
            id: 'guest_pass',
            label: 'Pass Claim',
            icon: Icons.confirmation_number_outlined,
            selectedIcon: Icons.confirmation_number_rounded,
          ),
          NavDestinationItem(
            id: 'plans',
            label: 'Memberships',
            icon: Icons.card_membership_outlined,
            selectedIcon: Icons.card_membership_rounded,
          ),
          NavDestinationItem(
            id: 'tools',
            label: 'Tools',
            icon: Icons.calculate_outlined,
            selectedIcon: Icons.calculate_rounded,
          ),
        ];
    }
  }
}
