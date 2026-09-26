import 'package:flutter/material.dart';

class TenantModel {
  final String id;
  final String name;
  final String slug;
  final String contactEmail;
  final String contactPhone;
  final String address;
  final String city;
  final String country;
  final String subscriptionStatus;
  final String subscriptionTier;
  final int maxMembers;
  final bool aiTrainerEnabled;
  final bool posEnabled;
  final bool esp32GateEnabled;
  final bool storeEnabled;
  final bool isActive;
  final Color primaryColor;
  final DateTime createdAt;
  final int activeMembersCount;

  const TenantModel({
    required this.id,
    required this.name,
    required this.slug,
    this.contactEmail = '',
    this.contactPhone = '',
    this.address = '',
    this.city = 'Lahore',
    this.country = 'Pakistan',
    this.subscriptionStatus = 'active',
    this.subscriptionTier = 'pro',
    this.maxMembers = 500,
    this.aiTrainerEnabled = true,
    this.posEnabled = true,
    this.esp32GateEnabled = true,
    this.storeEnabled = true,
    this.isActive = true,
    this.primaryColor = const Color(0xFFCCFF00),
    required this.createdAt,
    this.activeMembersCount = 142,
  });

  double get monthlySaaSPKR {
    switch (subscriptionTier.toLowerCase()) {
      case 'enterprise':
        return 75000.0;
      case 'starter':
        return 15000.0;
      case 'pro':
      default:
        return 35000.0;
    }
  }

  Color get statusBadgeColor {
    switch (subscriptionStatus.toLowerCase()) {
      case 'active':
        return const Color(0xFFCCFF00); // Neon Volt
      case 'trial':
        return const Color(0xFF60A5FA); // Blue
      case 'past_due':
        return const Color(0xFFFBBF24); // Amber
      case 'suspended':
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFFA1A1AA);
    }
  }

  String get tierBadgeLabel {
    switch (subscriptionTier.toLowerCase()) {
      case 'enterprise':
        return 'ENTERPRISE VIP';
      case 'starter':
        return 'STARTER TIER';
      case 'pro':
      default:
        return 'PRO PROFESSIONAL';
    }
  }

  TenantModel copyWith({
    String? name,
    String? slug,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? city,
    String? country,
    String? subscriptionStatus,
    String? subscriptionTier,
    int? maxMembers,
    bool? aiTrainerEnabled,
    bool? posEnabled,
    bool? esp32GateEnabled,
    bool? storeEnabled,
    bool? isActive,
    Color? primaryColor,
    int? activeMembersCount,
  }) {
    return TenantModel(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      maxMembers: maxMembers ?? this.maxMembers,
      aiTrainerEnabled: aiTrainerEnabled ?? this.aiTrainerEnabled,
      posEnabled: posEnabled ?? this.posEnabled,
      esp32GateEnabled: esp32GateEnabled ?? this.esp32GateEnabled,
      storeEnabled: storeEnabled ?? this.storeEnabled,
      isActive: isActive ?? this.isActive,
      primaryColor: primaryColor ?? this.primaryColor,
      createdAt: createdAt,
      activeMembersCount: activeMembersCount ?? this.activeMembersCount,
    );
  }

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final branding = json['branding'] as Map<String, dynamic>? ?? {};
    final features = json['features'] as Map<String, dynamic>? ?? {};
    final hexStr = branding['primary_color'] as String? ?? '#CCFF00';
    final parsedColor = _parseHexColor(hexStr);

    return TenantModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Gym',
      slug: json['slug'] as String? ?? 'gym',
      contactEmail: json['contact_email'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? 'Lahore',
      country: json['country'] as String? ?? 'Pakistan',
      subscriptionStatus: json['subscription_status'] as String? ?? 'active',
      subscriptionTier: json['subscription_tier'] as String? ?? 'pro',
      maxMembers: (json['max_members'] as int?) ?? 500,
      aiTrainerEnabled: features['ai_trainer_enabled'] as bool? ?? true,
      posEnabled: features['pos_enabled'] as bool? ?? true,
      esp32GateEnabled: features['esp32_gate_enabled'] as bool? ?? true,
      storeEnabled: features['store_enabled'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      primaryColor: parsedColor,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      activeMembersCount: (json['active_members_count'] as int?) ?? 142,
    );
  }

  Map<String, dynamic> toSupabaseInsert() {
    return {
      'name': name,
      'slug': slug,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'address': address,
      'city': city,
      'country': country,
      'subscription_status': subscriptionStatus,
      'subscription_tier': subscriptionTier,
      'max_members': maxMembers,
      'features': {
        'ai_trainer_enabled': aiTrainerEnabled,
        'pos_enabled': posEnabled,
        'esp32_gate_enabled': esp32GateEnabled,
        'store_enabled': storeEnabled,
      },
      'branding': {
        'primary_color': '#${primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        'surface_color': '#18181B',
        'background_color': '#09090B',
      },
      'is_active': isActive,
    };
  }

  static Color _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFCCFF00);
  }
}
