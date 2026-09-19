import 'package:flutter/material.dart';
import 'user_role.dart';

class UserProfile {
  final String id;
  final String? tenantId;
  final UserRole role;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? deviceId;
  final bool biometricEnabled;
  final bool isActive;
  final String tenantName;
  final Color? tenantPrimaryColor;

  const UserProfile({
    required this.id,
    this.tenantId,
    required this.role,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.deviceId,
    this.biometricEnabled = false,
    this.isActive = true,
    this.tenantName = 'GymConnect Partner Gym',
    this.tenantPrimaryColor,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    Color? parsedColor;
    String gymName = 'GymConnect Partner Gym';

    final tenantData = json['tenants'];
    if (tenantData is Map<String, dynamic>) {
      if (tenantData['name'] != null) {
        gymName = tenantData['name'].toString();
      }
      final branding = tenantData['branding'];
      if (branding is Map<String, dynamic> && branding['primary_color'] != null) {
        parsedColor = _parseHexColor(branding['primary_color'].toString());
      }
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      fullName: json['full_name'] as String? ?? 'Member',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      deviceId: json['device_id'] as String?,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      tenantName: gymName,
      tenantPrimaryColor: parsedColor,
    );
  }

  static Color? _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return null;
  }

  UserProfile copyWith({
    String? id,
    String? tenantId,
    UserRole? role,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? deviceId,
    bool? biometricEnabled,
    bool? isActive,
    String? tenantName,
    Color? tenantPrimaryColor,
  }) {
    return UserProfile(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      deviceId: deviceId ?? this.deviceId,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      isActive: isActive ?? this.isActive,
      tenantName: tenantName ?? this.tenantName,
      tenantPrimaryColor: tenantPrimaryColor ?? this.tenantPrimaryColor,
    );
  }
}
