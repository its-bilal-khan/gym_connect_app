import 'package:flutter/material.dart';

class NavDestinationItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? badgeText;

  const NavDestinationItem({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeText,
  });
}
