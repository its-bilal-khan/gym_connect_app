import 'package:flutter/material.dart';

/// The 4 official dark theme primary accent presets defined in GymConnect branding rules.
enum AppThemePreset {
  neonVolt(
    id: 'neon_volt',
    name: 'Neon Volt Green',
    shortName: 'Volt Green',
    hex: '#CCFF00',
    color: Color(0xFFCCFF00),
    description: 'High-voltage athletic energy & peak motivation',
    icon: Icons.bolt_rounded,
  ),
  electricBlue(
    id: 'electric_blue',
    name: 'Electric Blue',
    shortName: 'Electric Blue',
    hex: '#4F7CFF',
    color: Color(0xFF4F7CFF),
    description: 'Clean high-tech precision & modern focus',
    icon: Icons.water_drop_rounded,
  ),
  softYellow(
    id: 'soft_yellow',
    name: 'Soft Premium Yellow',
    shortName: 'Soft Yellow',
    hex: '#F4E87C',
    color: Color(0xFFF4E87C),
    description: 'Warm luxury, gold prestige & executive power',
    icon: Icons.wb_sunny_rounded,
  ),
  lavenderPurple(
    id: 'lavender_purple',
    name: 'Soft Lavender Purple',
    shortName: 'Lavender Purple',
    hex: '#A78BFA',
    color: Color(0xFFA78BFA),
    description: 'Futuristic sleek pastel violet & elegance',
    icon: Icons.auto_awesome_rounded,
  );

  final String id;
  final String name;
  final String shortName;
  final String hex;
  final Color color;
  final String description;
  final IconData icon;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.shortName,
    required this.hex,
    required this.color,
    required this.description,
    required this.icon,
  });

  /// Resolves an [AppThemePreset] from a [Color], defaulting to [neonVolt].
  static AppThemePreset fromColor(Color? color) {
    if (color == null) return AppThemePreset.neonVolt;
    final targetValue = color.toARGB32() & 0x00FFFFFF;
    for (final p in values) {
      if ((p.color.toARGB32() & 0x00FFFFFF) == targetValue) {
        return p;
      }
    }
    return AppThemePreset.neonVolt;
  }

  /// Resolves an [AppThemePreset] from a hex string, defaulting to [neonVolt].
  static AppThemePreset fromHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppThemePreset.neonVolt;
    final clean = hex.replaceAll('#', '').trim().toUpperCase();
    for (final p in values) {
      if (p.hex.replaceAll('#', '').toUpperCase() == clean) {
        return p;
      }
    }
    return AppThemePreset.neonVolt;
  }
}
