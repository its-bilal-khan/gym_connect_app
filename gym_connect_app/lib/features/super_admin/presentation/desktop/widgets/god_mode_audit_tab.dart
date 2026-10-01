import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/domain/models/user_role.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../providers/tenant_providers.dart';
import '../../widgets/super_admin_feature_flags_sheet.dart';
import 'rule9_feature_toggles_banner.dart';

class GodModeAuditTab extends ConsumerWidget {
  const GodModeAuditTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenants = ref.watch(superAdminTenantsNotifierProvider).value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: Color(0xFF00F0FF), size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUPER ADMIN GOD MODE (SECURITY DEFINER)',
                        style: GoogleFonts.oswald(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: const Color(0xFF00F0FF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Full cross-tenant PostgreSQL RLS bypass authority active. You can inspect any gym branch as if you were the physical gym owner.',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Rule9FeatureTogglesBanner(),
          const SizedBox(height: 24),
          Text(
            'QUICK SWITCH / SIMULATE AS GYM OWNER',
            style: GoogleFonts.oswald(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 340,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final t = tenants[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: t.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.apartment_rounded, color: t.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.name,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${t.city} • ${t.subscriptionTier.toUpperCase()}',
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: Colors.amberAccent, size: 18),
                      tooltip: 'Tenant Feature Toggles (Rule 9)',
                      onPressed: () => SuperAdminFeatureFlagsSheet.show(context, tenantId: t.id),
                    ),
                    IconButton(
                      icon: Icon(Icons.login_rounded, color: AppColors.primary, size: 18),
                      tooltip: 'Simulate as ${t.name} Owner',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched context to ${t.name}...'),
                            backgroundColor: AppColors.surface,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        ref.read(authNotifierProvider.notifier).switchActiveRole(UserRole.owner);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'PLATFORM IMMUTABLE AUDIT WATCHDOG',
            style: GoogleFonts.oswald(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildAuditLogEntry(
                  time: 'Just now',
                  gym: 'Titan Fitness Club',
                  action: 'ESP32 Turnstile gate heartbeat OK (12ms ping)',
                  isSuccess: true,
                ),
                const Divider(color: AppColors.border, height: 16),
                _buildAuditLogEntry(
                  time: '14 mins ago',
                  gym: 'Iron Peak Elite Gym',
                  action: 'POS Sale invoice generated: PKR 18,500 (Whey Protein)',
                  isSuccess: true,
                ),
                const Divider(color: AppColors.border, height: 16),
                _buildAuditLogEntry(
                  time: '42 mins ago',
                  gym: 'Rawal Strength & Conditioning',
                  action: 'Trial period initiated by super_admin',
                  isSuccess: true,
                ),
                const Divider(color: AppColors.border, height: 16),
                _buildAuditLogEntry(
                  time: '2 hours ago',
                  gym: 'Metro Flex Gym',
                  action: 'Branch suspended: Overdue subscription balance',
                  isSuccess: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogEntry({
    required String time,
    required String gym,
    required String action,
    required bool isSuccess,
  }) {
    return Row(
      children: [
        Icon(
          isSuccess ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
          size: 16,
          color: isSuccess ? AppColors.primary : AppColors.error,
        ),
        const SizedBox(width: 12),
        Text(
          time,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            gym,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            action,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
