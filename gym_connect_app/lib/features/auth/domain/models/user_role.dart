import 'package:flutter/material.dart';

enum UserRole {
  owner,
  staff,
  member,
  publicUser;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.member;
    switch (role.toLowerCase().trim()) {
      case 'super_admin':
      case 'gym_owner':
      case 'owner':
        return UserRole.owner;
      case 'staff':
      case 'trainer':
      case 'receptionist':
        return UserRole.staff;
      case 'member':
        return UserRole.member;
      case 'public_user':
      case 'public':
      case 'guest':
        return UserRole.publicUser;
      default:
        return UserRole.member;
    }
  }

  String get dbValue {
    switch (this) {
      case UserRole.owner:
        return 'gym_owner';
      case UserRole.staff:
        return 'staff';
      case UserRole.member:
        return 'member';
      case UserRole.publicUser:
        return 'public_user';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Gym Owner';
      case UserRole.staff:
        return 'Staff & POS';
      case UserRole.member:
        return 'VIP Member';
      case UserRole.publicUser:
        return 'Public Guest';
    }
  }

  String get badgeLabel {
    switch (this) {
      case UserRole.owner:
        return 'OWNER / BOSS';
      case UserRole.staff:
        return 'STAFF DESK';
      case UserRole.member:
        return 'VIP MEMBER';
      case UserRole.publicUser:
        return 'GUEST';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.owner:
        return Icons.admin_panel_settings_rounded;
      case UserRole.staff:
        return Icons.badge_rounded;
      case UserRole.member:
        return Icons.fitness_center_rounded;
      case UserRole.publicUser:
        return Icons.explore_rounded;
    }
  }

  bool get canSwitchRoles => this == UserRole.owner || this == UserRole.staff;
}
